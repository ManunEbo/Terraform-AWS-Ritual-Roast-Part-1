from flask import Flask, jsonify, request, send_from_directory
import mysql.connector
import os
import sys
from flask_cors import CORS
import boto3
import json
import time

app = Flask(
    __name__,
    static_folder="ritual_roast/build/static",
    template_folder="ritual_roast/build"
)
CORS(app, resources={r"/*": {"origins": "*"}})

# Global variables for DB
connection = None
cursor = None

def get_mysql_database_secrets():
    try:
        session = boto3.Session()
        client = session.client(service_name="secretsmanager", region_name="eu-west-2")
        # Ensure this SecretId matches your actual Secret Name in AWS
        get_secret_value_response = client.get_secret_value(SecretId="rr-db-secret-14")
        secret_string = json.loads(get_secret_value_response["SecretString"])
        return secret_string
    except Exception as e:
        print(f"Error fetching secrets: {e}")
        return None

def connect_to_db():
    global connection, cursor
    secrets = get_mysql_database_secrets()
    if not secrets:
        return False
    
    try:
        connection = mysql.connector.connect(
            host=secrets["host"],
            user=secrets["username"],
            password=secrets["password"],
            database=secrets["dbname"],
            port=secrets["port"],

            # Ensuring that the traffic is encrypted using ssl
            ssl_ca='/home/ec2-user/global-bundle.pem', # <--- This is where the magic happens
            ssl_verify_cert=True                       # <--- This forces the verification
        )
        cursor = connection.cursor()
        
        # Create table if not exists
        query = """
        CREATE TABLE IF NOT EXISTS recipes (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(255) NOT NULL,
            email VARCHAR(255) NOT NULL,
            recipe_name VARCHAR(255) NOT NULL,
            description TEXT,
            ingredients TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );
        """
        cursor.execute(query)
        connection.commit()
        return True
    except Exception as e:
        print(f"Database connection failed: {e}")
        return False

def check_and_reconnect():
    global connection, cursor
    if connection is None:
        connect_to_db()
    else:
        try:
            connection.ping(reconnect=True, attempts=3, delay=2)
        except Exception:
            connect_to_db()

# Routes
@app.route('/get_recipe', methods=['GET'])
def get_recipes():
    check_and_reconnect()
    if not cursor:
        return jsonify({"error": "Database unavailable"}), 503
    
    query = "SELECT * FROM recipes ORDER BY id DESC;"
    cursor.execute(query)
    rows = cursor.fetchall()
    recipes = []
    for row in rows:
        recipes.append({
            'id': row[0], 'name': row[1], 'email': row[2],
            'recipe_name': row[3], 'description': row[4],
            'ingredients': row[5], 'created_at': str(row[6])
        })
    return jsonify(recipes)

@app.route('/add_recipe', methods=['POST'])
def add_recipe():
    check_and_reconnect()
    if not cursor:
        return jsonify({"error": "Database unavailable"}), 503
    
    data = request.get_json()
    query = """
        INSERT INTO recipes (name, email, recipe_name, description, ingredients)
        VALUES (%s, %s, %s, %s, %s);
    """
    cursor.execute(query, (data.get('name'), data.get('email'), data.get('recipe_name'), data.get('description'), data.get('ingredients')))
    connection.commit()
    return jsonify({'message': 'Recipe added successfully'}), 201

# Health Check Endpoint (Explicitly for ALB)
@app.route('/health')
def health_check():
    return "OK", 200

@app.route("/", defaults={"path": ""})
@app.route("/<path:path>")
def serve(path):
    static_file_path = os.path.join(app.static_folder, path)
    template_file_path = os.path.join(app.template_folder, path)

    if path and os.path.exists(static_file_path):
        return send_from_directory(app.static_folder, path)
    if path and os.path.exists(template_file_path):
        return send_from_directory(app.template_folder, path)

    index_file = os.path.join(app.template_folder, "index.html")
    if os.path.exists(index_file):
        return send_from_directory(app.template_folder, "index.html")
    return "index.html not found", 404

# if __name__ == '__main__':
#     # Start the app immediately so the ALB can see it
#     app.run(host='0.0.0.0', port=5000, debug=False)


if __name__ == '__main__':
    print("🚀 Initializing Database Connection...")
    
    # Try to connect. If it fails, EXIT the script.
    if connect_to_db():
        print("✅ Database initialized and table verified.")
        # Only start the web server if the DB is actually ready
        app.run(host='0.0.0.0', port=5000, debug=False)
    else:
        print("❌ CRITICAL: Initial database connection failed.")
        print("Exiting to allow Systemd to restart the service...")
        sys.exit(1) # This exit code 1 is what tells Systemd to RESTART


    