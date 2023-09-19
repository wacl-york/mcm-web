# Login
saml2aws login

STACK_NAME=mcm-eb-dev
EB_APP_NAME=MCM
TEMPLATE_OUT=cf.json
PARAMETER_FILE=param.json

find_param() {
  local keyName="$1"
  cat ${PARAMETER_FILE} | jq -r ".${keyName}"
}

get_default_vpc() {
    aws ec2 describe-vpcs --filters Name=tag:AWS_Solutions,Values=LandingZoneStackSet --output=json | jq -r ".Vpcs[].VpcId"
}

get_default_subnets() {
  local vpc_id="$1"
  local sub1=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=${vpc_id} Name=tag:Name,Values='Public subnet 1' | jq -r ".Subnets[].SubnetId")
  local sub2=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=${vpc_id} Name=tag:Name,Values='Public subnet 2' | jq -r ".Subnets[].SubnetId")
  echo "${sub1},${sub2}"
}

get_eb_environment_name() {
  local cf_name="$1"
  aws cloudformation describe-stack-resources --stack-name ${STACK_NAME} | jq -r ".[][] | select(.LogicalResourceId==\"${cf_name}\") | .PhysicalResourceId"
}

VERSION=$(find_param Version)
BUCKET_NAME=$(find_param S3Bucket)
KEY_NAME="$(find_param S3Key)_${VERSION}.zip"
VPC_ID=$(get_default_vpc)
SUBNETS=$(get_default_subnets ${VPC_ID})
EB_ENV_PROD=$(get_eb_environment_name 'MCMEnvironment')
CAPABILITIES="--capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM"
PARAMETER_OVERRIDES="--parameter-overrides VpcId=${VPC_ID} Subnets=${SUBNETS} S3Bucket=${BUCKET_NAME}"

# TODO ideally create Bucket in a separate CF and use output from that stack here, currently being manually created

# ------------ Step 1: Update the infrastructure if needed
aws cloudformation package --template-file eb_cloudformation.json --s3-bucket "$BUCKET_NAME" --output-template-file "$TEMPLATE_OUT"
array=(aws cloudformation deploy --stack-name "$STACK_NAME" --template-file "$TEMPLATE_OUT" "$CAPABILITIES" "$PARAMETER_OVERRIDES" --force-upload --s3-bucket "$BUCKET_NAME" --no-fail-on-empty-changeset)
eval $(echo ${array[@]})

# ------------ Step 2: Upload the new version of the app
# TODO Once have progressed out of the initial development stage (i.e. when will be archiving comitted changes), can use git archive
#git archive --format zip HEAD | aws s3 cp - s3://${BUCKET_NAME}/${KEY_NAME}
# Can then use commit hash as the version number
zip -r - . -q -x ./.bundle/\* ./vendor/\* ./.git/\* | aws s3 cp - s3://${BUCKET_NAME}/${KEY_NAME}

# ------------ Step 3: Create a new application version in EBS corresponding to this source code bundle
aws elasticbeanstalk create-application-version --application-name $EB_APP_NAME --version-label $VERSION --description "v.$VERSION release" --source-bundle S3Bucket=$BUCKET_NAME,S3Key=$KEY_NAME

# ------------ Step 4: Update the environment to use this new version
aws elasticbeanstalk update-environment --application-name $EB_APP_NAME --version-label $VERSION --environment-name $EB_ENV_PROD
