import boto3
import json
import logging
import random
import string
import pymysql # Requires packaging this dependency in your zip file

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def generate_random_password(length=16):
    characters = string.ascii_letters + string.digits + "!@#$%^&*"
    return ''.join(random.choices(characters, k=length))

def lambda_handler(event, context):
    arn = event['SecretId']
    token = event['ClientRequestToken']
    step = event['Step']

    # The SecretId is passed dynamically. No need to hardcode it.
    client = boto3.client('secretsmanager')

    # Ensure the rotation is enabled and valid
    metadata = client.describe_secret(SecretId=arn)
    if not metadata['RotationEnabled']:
        logger.error(f"Secret {arn} is not enabled for rotation")
        raise ValueError(f"Secret {arn} is not enabled for rotation")

    # Route to the correct step based on the Secrets Manager event
    if step == "createSecret":
        create_secret(client, arn, token)
    elif step == "setSecret":
        set_secret(client, arn, token)
    elif step == "testSecret":
        test_secret(client, arn, token)
    elif step == "finishSecret":
        finish_secret(client, arn, token)
    else:
        raise ValueError(f"Invalid step parameter: {step}")

def create_secret(client, arn, token):
    # Fetch current secret to get the "hidden" username, dbname, host, etc.
    current_dict = get_secret_dict(client, arn, "AWSCURRENT")
    
    # Generate a new password
    current_dict['password'] = generate_random_password()
    
    try:
        # Save the new password to Secrets Manager under the "AWSPENDING" stage
        client.put_secret_value(
            SecretId=arn,
            ClientRequestToken=token,
            SecretString=json.dumps(current_dict),
            VersionStages=['AWSPENDING']
        )
    except client.exceptions.ResourceExistsException:
        pass # If the pending secret already exists, we just move on

def set_secret(client, arn, token):
    current_dict = get_secret_dict(client, arn, "AWSCURRENT")
    pending_dict = get_secret_dict(client, arn, "AWSPENDING", token)

    # Extract your hidden variables directly from the secret JSON
    host = current_dict['host']
    db_name = current_dict['dbname']
    username = current_dict['username']
    
    new_password = pending_dict['password']

    # Connect to the MySQL database to execute the password change
    try:
        conn = pymysql.connect(
            host=host,
            user=username,
            password=current_dict['password'], # Log in with old password
            database=db_name,
            connect_timeout=5
        )
        with conn.cursor() as cursor:
            # Execute SQL to change the password inside the database engine
            cursor.execute(f"ALTER USER '{username}'@'%' IDENTIFIED BY '{new_password}';")
        conn.commit()
        conn.close()
    except Exception as e:
        logger.error(f"Failed to update database password: {e}")
        raise

def test_secret(client, arn, token):
    # Retrieve the pending secret and attempt a test connection to the database
    pending_dict = get_secret_dict(client, arn, "AWSPENDING", token)
    
    try:
        conn = pymysql.connect(
            host=pending_dict['host'],
            user=pending_dict['username'],
            password=pending_dict['password'],
            database=pending_dict['dbname'],
            connect_timeout=5
        )
        conn.close()
    except Exception as e:
        logger.error(f"Failed to connect with new password: {e}")
        raise

def finish_secret(client, arn, token):
    # Finalize the rotation by moving the AWSCURRENT label to the new secret version
    metadata = client.describe_secret(SecretId=arn)
    current_version = None
    for version in metadata["VersionIdsToStages"]:
        if "AWSCURRENT" in metadata["VersionIdsToStages"][version]:
            if version == token:
                return # The correct version is already marked as current
            current_version = version
            break

    client.update_secret_version_stage(
        SecretId=arn,
        VersionStage="AWSCURRENT",
        MoveToVersionId=token,
        RemoveFromVersionId=current_version
    )

def get_secret_dict(client, arn, stage, token=None):
    # Helper function to fetch and parse the JSON secret
    if token:
        response = client.get_secret_value(SecretId=arn, VersionId=token, VersionStage=stage)
    else:
        response = client.get_secret_value(SecretId=arn, VersionStage=stage)
    return json.loads(response['SecretString'])