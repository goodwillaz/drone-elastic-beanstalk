#!/bin/bash

if [ "$1" == "/bin/bash" ]; then
  exec "$@"
fi

set -e

export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-$PLUGIN_REGION}
export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-$PLUGIN_ACCESS_KEY}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-$PLUGIN_SECRET_KEY}

if [ "${PLUGIN_DEBUG}" == "true" ]; then
  set -x
fi

if [ -z "$PLUGIN_APPLICATION" ]; then
  echo "The application setting is required"
  exit 1;
fi

deploy() {
  # Default label
  DRONE_COMMIT=${DRONE_COMMIT:0:12}
  VERSION_LABEL=${DRONE_TAG:-$DRONE_COMMIT}
  export VERSION_LABEL=${PLUGIN_LABEL:-$VERSION_LABEL}

  # Check if the version exists
  VERSION_CHECK=$(aws elasticbeanstalk describe-application-versions --application-name "$PLUGIN_APPLICATION" --version-labels "$VERSION_LABEL" --query 'ApplicationVersions[0].VersionLabel' --output text)
  if [ "$VERSION_CHECK" = "$VERSION_LABEL" ]; then
    echo "Version already exists, not recreating..."
  else
    # Create a zip file - if ebignore present or if staged, create a stash and archive that: https://stackoverflow.com/a/12010656
    if [ -f .ebignore ]; then
      mv .ebignore .gitignore
      PLUGIN_STAGED=true
    fi

    if [ -n "$PLUGIN_STAGED" ]; then
      git rm --cached -r . 2>&1 > /dev/null
      git add . 2>&1 > /dev/null
      GIT_COMMITTER_NAME='Drone' GIT_COMMITTER_EMAIL='drone@git.hub' git commit --all --allow-empty-message -m "" --author "Drone <drone@git.hub>" 2>&1 > /dev/null
    fi

    # Create an archive of our project
    git archive --format=zip -o /tmp/${VERSION_LABEL}.zip HEAD

    # Get the S3 bucket to use for app versions
    export S3_BUCKET=$(aws elasticbeanstalk create-storage-location --output text)

    # Upload the version to S3
    export S3_KEY="${PLUGIN_APPLICATION}/${VERSION_LABEL}.zip"
    echo "Uploading version ${VERSION_LABEL} to ${S3_KEY}..."
    aws s3 mv /tmp/${VERSION_LABEL}.zip s3://${S3_BUCKET}/${S3_KEY} 2>&1 > /dev/null

    if [ -z "$DRONE_COMMIT_MESSAGE" ]; then
      DRONE_COMMIT_MESSAGE="${VERSION_LABEL}"
    fi
    DRONE_COMMIT_MESSAGE="${DRONE_COMMIT_MESSAGE:0:200}"

    # Create the version in the application (and the application if it doesn't exist)
    echo "Creating application version..."
    aws elasticbeanstalk create-application-version \
      --application-name "$PLUGIN_APPLICATION" \
      --version-label "$VERSION_LABEL" \
      --description "$DRONE_COMMIT_MESSAGE" \
      --source-bundle S3Bucket="$S3_BUCKET",S3Key="$S3_KEY" \
      2>&1 > /dev/null
  fi

  if [ -f package-lock.json ]; then
    echo "Installing dependencies from package-lock.json..."
    npm ci
  elif [ -f package.json ]; then
    echo "Installing dependencies from package.json..."
    npm install
  fi

  if [ -z "$PLUGIN_DEPLOY_CMD" ]; then
    PLUGIN_DEPLOY_CMD="cdk deploy --all --require-approval never --progress events"
  fi

  exec $PLUGIN_DEPLOY_CMD
}

# If not sourced, run it!
if ! [ "sh" == "${0##*/}" ]; then
  deploy
fi
