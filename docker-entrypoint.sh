#!/bin/ash

if [ "$1" == "/bin/sh" ]; then
  exec "$@"
fi

set -e

export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-$PLUGIN_REGION}
export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-$PLUGIN_ACCESS_KEY}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-$PLUGIN_SECRET_KEY}

if [ "${PLUGIN_DEBUG}" == "true" ]; then
  set -x
fi

create() {
  # If we don't have a .elasticbeanstalk folder, we can't create an environment, so bail
  if ! [ -d .elasticbeanstalk ]; then
    return
  fi

  # If the environment already exists, just leave
  if eb list | grep -q "$PLUGIN_ENVIRONMENT"; then
    return
  fi

  set -- "$PLUGIN_ENVIRONMENT" --timeout "${PLUGIN_TIMEOUT:-55}"

  if [ "${PLUGIN_QUIET}" == "true" ]; then
    set -- "$@" --quiet
  fi

  if [ -n "$PLUGIN_NO_HANG" ]; then
    set -- "$@" --nohang
  fi

  if [ "${PLUGIN_DEBUG}" == "true" ]; then
    set -- "$@" --verbose
  fi

  if [ -n "$PLUGIN_SINGLE_INSTANCE" ]; then
    set -- "$@" --single
  fi

  if [ -n "$PLUGIN_INSTANCE_TYPE" ]; then
    set -- "$@" --elb-type "$PLUGIN_INSTANCE_TYPE"
  fi

  if [ -n "$PLUGIN_LOAD_BALANCER" ]; then
    set -- "$@" --ls "$PLUGIN_LOAD_BALANCER"
  fi

  ENV_VARS=""
  while IFS='=' read -r -d '' n v; do
      if ! [ "$n" = "${n#EB_ENV_}" ]; then
          ENV_VARS=${ENV_VARS},${n#EB_ENV_}=${v}
      fi
  done < <(env -0)
  if [ -n "$ENV_VARS" ]; then
    set -- "$@" --envvars "${ENV_VARS#,}"
  fi

  if [ -n "$PLUGIN_EC2_ROLE" ]; then
    create_ec2_role
    set -- "$@" --instance_profile "$PLUGIN_EC2_ROLE"
  fi

  if [ -n "$PLUGIN_SERVICE_ROLE" ]; then
    create_service_role
    set -- "$@" --service-role "$PLUGIN_SERVICE_ROLE"
  fi

  exec eb create "$@"
}

deploy() {
  set -- "$PLUGIN_ENVIRONMENT" --timeout "${PLUGIN_TIMEOUT:-55}"

  if [ "${PLUGIN_QUIET}" == "true" ]; then
    set -- "$@" --quiet
  fi

  if [ -n "$PLUGIN_NO_HANG" ]; then
    set -- "$@" --nohang
  fi

  if [ "${PLUGIN_DEBUG}" == "true" ]; then
    set -- "$@" --verbose
  fi

  # Default label
  DRONE_COMMIT=${DRONE_COMMIT:0:12}
  LABEL=${DRONE_TAG:-$DRONE_COMMIT}
  if [ -n "$PLUGIN_LABEL" ]; then
    LABEL=${PLUGIN_LABEL}
  fi
  set -- "$@" --label "$LABEL"

  if [ -n "$DRONE_COMMIT_MESSAGE" ]; then
    set -- "$@" "--message" "${DRONE_COMMIT_MESSAGE:0:200}"
  fi

  if [ -n "$PLUGIN_STAGED" ]; then
    touch .ebignore
    set -- "$@" --staged # Probably not needed due to .ebignore
  fi

  if [ -n "$PLUGIN_PROCESS" ]; then
    set -- "$@" --process
  fi

  if [ -n "$PLUGIN_MODULES" ]; then
    set -- "$@" --modules "$PLUGIN_MODULES"
  fi

  if [ -n "$PLUGIN_SOURCE" ]; then
    set -- "$@" --source "codecommit/$PLUGIN_SOURCE"
  fi

  exec eb deploy "$@"
}

create_ec2_role() {
  if ! aws iam get-role --role-name "$PLUGIN_EC2_ROLE"; then
    aws iam create-role --role-name "$PLUGIN_EC2_ROLE" --assume-role-policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ec2.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"
    aws iam attach-role-policy --role-name "$PLUGIN_EC2_ROLE" --policy-arn "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
    aws iam attach-role-policy --role-name "$PLUGIN_EC2_ROLE" --policy-arn "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
    aws iam attach-role-policy --role-name "$PLUGIN_EC2_ROLE" --policy-arn "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
    aws iam create-instance-profile --instance-profile-name "$PLUGIN_EC2_ROLE"
    aws iam add-role-to-instance-profile --instance-profile-name "$PLUGIN_EC2_ROLE" --role-name "$PLUGIN_EC2_ROLE"
  fi
}

create_service_role() {
  if ! aws iam get-role --role-name "$PLUGIN_SERVICE_ROLE"; then
    aws iam create-role --role-name "$PLUGIN_SERVICE_ROLE" --assume-role-policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"elasticbeanstalk.amazonaws.com\"},\"Action\":\"sts:AssumeRole\",\"Condition\":{\"StringEquals\":{\"sts:ExternalId\":\"elasticbeanstalk\"}}}]}"
    aws iam attach-role-policy --role-name "$PLUGIN_SERVICE_ROLE" --policy-arn "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
    aws iam attach-role-policy --role-name "$PLUGIN_SERVICE_ROLE" --policy-arn "arn:aws:iam::aws:policy/AmazonElastiCacheReadOnlyAccess"
    aws iam attach-role-policy --role-name "$PLUGIN_SERVICE_ROLE" --policy-arn "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkService"
  fi
}

# If not sourced, run it!
if ! [ "sh" == "${0##*/}" ]; then
  # Create the environment if it doesn't exist
  create

  # Deploy code (only if we didn't have to create the environment)!
  deploy
fi
