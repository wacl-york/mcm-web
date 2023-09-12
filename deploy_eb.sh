# Login
saml2aws login

find_param() {
  local keyName="$1"
  cat param.json | jq -r --arg keyName $keyName \
    '.[] | select(.ParameterKey == $keyName) | .ParameterValue'
}

BUCKET_NAME=$(find_param S3Bucket)
KEY_NAME=$(find_param S3Key)

# TODO ideally create Bucket in a separate CF and use output from that stack here, currently being manually created

# upload git archive to S3
# TODO remove vendor from archive?
#git archive --format zip HEAD | aws s3 cp - s3://${BUCKET_NAME}/${KEY_NAME}
zip -r - . -q -x ./.bundle/\* ./vendor/\* ./.git/\* | aws s3 cp - s3://${BUCKET_NAME}/${KEY_NAME}

TEMPLATE_OUT=cf.json
AWS_STACK_NAME=mcm-eb-dev
CAPABILITIES="--capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM"
aws cloudformation package --template-file eb_cloudformation.json --s3-bucket "$BUCKET_NAME" --output-template-file "$TEMPLATE_OUT"
PARAMETER_FILE=param2.json
PARAMETER_OVERRIDES="--parameter-overrides $(jq -r 'to_entries[] | "\(.key)=\"\(.value)\""' $PARAMETER_FILE | tr '\r\n' ' ')"

# Original create stack code, have to manually delete to update stack so moved to copying the cfn-deploy-action code
#aws cloudformation create-stack \
#   --stack-name mcm-eb-dev \
#   --template-body file://eb_cloudformation.json \
#   --region eu-west-1 \
#   --parameters file://param.json \
#   --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM

#aws cloudformation deploy --stack-name $AWS_STACK_NAME --template-file $TEMPLATE_OUT $PARAMETER_OVERRIDES $CAPABILITIES $ROLE_ARN $FORCE_UPLOAD $TAGS $DEPLOY_BUCKET --no-fail-on-empty-changeset
array=(aws cloudformation deploy --stack-name "$AWS_STACK_NAME" --template-file "$TEMPLATE_OUT" "$CAPABILITIES" "$PARAMETER_OVERRIDES" --force-upload --s3-bucket "$BUCKET_NAME" --no-fail-on-empty-changeset)
eval $(echo ${array[@]})
