#! /bin/bash
# This project does not use Lambda layers
# Below index.py with its mysql dependencies are packaged (in a .zip file)
# because AWS Lambda is a "bare-bones" execution environment.
# Unlike an EC2 instance, which has a persistent hard drive
# to run pip install at boot,
# a Lambda function is a temporary container that exists only for a few seconds.

# Change directory into the desired directory
cd my_rotation_dependencies/

# Install the dependency in place
pip install pymysql --target .

# Zipping the function and the dependencies
zip -r ../index.zip .

# To clean up the source code directory after run
# rm -rf pymysql/ PyMySQL-*.dist-info/

# To remove the directory the brute force way
# rm -rf ./my_rotation_dependencies
