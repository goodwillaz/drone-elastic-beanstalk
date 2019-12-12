#!/bin/ash

if [ "$1" == "/bin/sh" ]; then
  exec "$@"
fi

set -e

export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-$PLUGIN_REGION}
export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-$PLUGIN_ACCESS_KEY}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-$PLUGIN_SECRET_KEY}

DEPLOY_OPTS=""

if [ -n "$PLUGIN_ENVIRONMENT" ]; then
  DEPLOY_OPTS="$DEPLOY_OPTS $PLUGIN_ENVIRONMENT"
fi

# Do this after the secret stuff above so we don't leak secrets
if [ "${PLUGIN_DEBUG}" == "true" ]; then
  set -x
  DEPLOY_OPTS="$DEPLOY_OPTS --debug"
fi

# Default label
LABEL=${DRONE_TAG:-$DRONE_COMMIT}
if [ -n "$PLUGIN_LABEL" ]; then
  LABEL=${PLUGIN_LABEL}
fi
DEPLOY_OPTS="$DEPLOY_OPTS --label $LABEL"

if [ -n "$DRONE_COMMIT_MESSAGE" ]; then
  DEPLOY_OPTS="$DEPLOY_OPTS --message ${DRONE_COMMIT_MESSAGE:0:200}"
fi

if [ -n "$PLUGIN_STAGED" ]; then
  touch .ebignore
  DEPLOY_OPTS="$DEPLOY_OPTS --staged" # Probably not needed due to .ebignore
fi

if [ "${PLUGIN_QUIET}" == "true" ]; then
  DEPLOY_OPTS="$DEPLOY_OPTS --quiet"
fi

if [ -n "$PLUGIN_NO_HANG" ]; then
  DEPLOY_OPTS="$DEPLOY_OPTS --nohang"
fi

DEPLOY_OPTS="$DEPLOY_OPTS --timeout ${PLUGIN_TIMEOUT:-55}"

if [ -n "$PLUGIN_SOURCE" ]; then
  DEPLOY_OPTS="$DEPLOY_OPTS --source codecommit/$PLUGIN_SOURCE"
fi

eb deploy $DEPLOY_OPTS
