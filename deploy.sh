# Login to AWS
saml2aws login

# Login to docker
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin 733046350245.dkr.ecr.eu-west-1.amazonaws.com

# Push docker images
docker compose build
docker compose push

# Create a new deployment. NB: likely will require installing lightsailctl
# https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-install-software
aws lightsail create-container-service-deployment --service-name mcm-dev --containers "{
    \"mcm-app\": {
      \"image\": \"733046350245.dkr.ecr.eu-west-1.amazonaws.com/mcm-app:latest\",
      \"command\": [],
      \"environment\": {},
      \"ports\": {\"5000\": \"HTTP\"}
    },
    \"mcm-web\": {
      \"image\": \"733046350245.dkr.ecr.eu-west-1.amazonaws.com/mcm-web:latest\",
      \"command\": [],
      \"environment\": {},
      \"ports\": {\"80\": \"HTTP\"}
    }
}" --public-endpoint "{
  \"containerName\": \"mcm-web\",
  \"containerPort\": 80,
  \"healthCheck\": {
    \"healthyThreshold\": 2,
    \"unhealthyThreshold\": 2,
    \"timeoutSeconds\": 2,
    \"intervalSeconds\": 5,
    \"path\": \"/\",
    \"successCodes\": \"200-499\"
  }
}"
