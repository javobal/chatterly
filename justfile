
# Retrieve an authentication token and authenticate your Docker client to your registry
auth-docker:
    aws ecr get-login-password --region us-east-1 --profile javobal \
    | docker login --username AWS --password-stdin 655757912437.dkr.ecr.us-east-1.amazonaws.com

