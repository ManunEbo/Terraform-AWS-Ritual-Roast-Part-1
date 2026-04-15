#!/bin/bash
# This project packages index.py with its dependencies (PyMySQL + Cryptography)
# for an AWS Lambda environment running Python 3.9.

# 1. Start fresh - remove old artifacts
rm -rf my_rotation_dependencies index.zip
sleep 10
mkdir -p my_rotation_dependencies

# 2. Install dependencies
# We target 3.9 to match the Lambda runtime in Terraform.
# We use manylinux2014 to ensure binary compatibility with AWS Lambda's OS.
pip install \
    --platform manylinux2014_x86_64 \
    --target my_rotation_dependencies \
    --implementation cp \
    --python-version 3.9 \
    --only-binary=:all: \
    --upgrade \
    pymysql cryptography

# 3. Copy the Lambda function code into the dependency folder
# This ensures index.py is at the root of the zip file.
cp index.py my_rotation_dependencies/

# 4. Create the deployment package
# We cd into the folder so the zip internal paths start at the root.
cd my_rotation_dependencies
zip -r ../index.zip .
cd ..

echo "Cleanup complete. index.zip is ready for Terraform."

# 5. Optional Cleanup (Commented out as requested)
# To clean up the source code directory after run
# rm -rf my_rotation_dependencies/
# rm -rf pymysql/ PyMySQL-*.dist-info/
# rm -rf cryptography/ cryptography-*.dist-info/
# rm -rf cffi/ cffi-*.dist-info/
# rm -rf .libs_cffi_backend/

# 6. Optional: Remove the temporary directory entirely if you're done
# cd ..
# rm -rf ./my_rotation_dependencies

echo "Cleanup complete. index.zip is ready for Terraform."