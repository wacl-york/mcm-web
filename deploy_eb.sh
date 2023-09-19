# Login
saml2aws login

# TODO why do we have to have 2 parameter files?
# Update this function to use param2.json
find_param() {
  local keyName="$1"
  cat param.json | jq -r --arg keyName $keyName \
    '.[] | select(.ParameterKey == $keyName) | .ParameterValue'
}

VERSION=$(find_param Version)
BUCKET_NAME=$(find_param S3Bucket)
KEY_NAME="$(find_param S3Key)_${VERSION}.zip"

# TODO ideally create Bucket in a separate CF and use output from that stack here, currently being manually created
#
# upload git archive to S3
# Once have progressed out of the initial development stage (i.e. when will be archiving comitted changes), can use git archive
#git archive --format zip HEAD | aws s3 cp - s3://${BUCKET_NAME}/${KEY_NAME}
zip -r - . -q -x ./.bundle/\* ./vendor/\* ./.git/\* | aws s3 cp - s3://${BUCKET_NAME}/${KEY_NAME}

TEMPLATE_OUT=cf.json
AWS_STACK_NAME=mcm-eb-dev
CAPABILITIES="--capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM"
aws cloudformation package --template-file eb_cloudformation.json --s3-bucket "$BUCKET_NAME" --output-template-file "$TEMPLATE_OUT"
PARAMETER_FILE=param2.json
PARAMETER_OVERRIDES="--parameter-overrides $(jq -r 'to_entries[] | "\(.key)=\"\(.value)\""' $PARAMETER_FILE | tr '\r\n' ' ')"

array=(aws cloudformation deploy --stack-name "$AWS_STACK_NAME" --template-file "$TEMPLATE_OUT" "$CAPABILITIES" "$PARAMETER_OVERRIDES" --force-upload --s3-bucket "$BUCKET_NAME" --no-fail-on-empty-changeset)
eval $(echo ${array[@]})

aws elasticbeanstalk create-application-version --application-name MCM --version-label $VERSION --description "v.$VERSION release" --source-bundle S3Bucket=$BUCKET_NAME,S3Key=$KEY_NAME
# TODO how to get this environment ID from CF output?
aws elasticbeanstalk update-environment --application-name MCM --version-label $VERSION --environment-id e-9xdvetkaa2 
