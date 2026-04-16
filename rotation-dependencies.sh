#!/bin/bash
# Package index.py with PyMySQL + Cryptography for AWS Lambda (Python 3.9)

# 1. Clean up old builds and create fresh directory
rm -rf my_rotation_dependencies
rm -f index.zip
mkdir my_rotation_dependencies

# 2. Install dependencies
# Using --platform manylinux2014_x86_64 ensures the 'cryptography' C-extensions 
# are compatible with the AWS Lambda Linux environment.
pip install \
    --platform manylinux2014_x86_64 \
    --target my_rotation_dependencies \
    --implementation cp \
    --python-version 3.9 \
    --only-binary=:all: \
    pymysql cryptography

# 3. Copy the Lambda function code into the directory
cp index.py my_rotation_dependencies/

# 4. Create the deployment package
cd my_rotation_dependencies
zip -r ../index.zip .
cd ..

echo "Build complete. index.zip is ready for Terraform."

# 5. Optional Cleanup (Commented out)
# rm -rf my_rotation_dependencies/