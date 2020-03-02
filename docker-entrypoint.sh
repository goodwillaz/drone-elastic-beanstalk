#!/bin/ash

if [ "$1" == "/bin/sh" ]; then
  exec "$@"
fi

set -e

export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-$PLUGIN_REGION}
export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-$PLUGIN_ACCESS_KEY}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-$PLUGIN_SECRET_KEY}

set --

# Do this after the secret stuff above so we don't leak secrets
if [ "${PLUGIN_DEBUG}" == "true" ]; then
  set -x
  set -- --debug
fi

if [ -n "$PLUGIN_ENVIRONMENT" ]; then
  set -- "$PLUGIN_ENVIRONMENT" "$@"
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

if [ "${PLUGIN_QUIET}" == "true" ]; then
  set -- "$@" --quiet
fi

if [ -n "$PLUGIN_NO_HANG" ]; then
  set -- "$@" --nohang
fi

set -- "$@" "--timeout" "${PLUGIN_TIMEOUT:-55}"

if [ -n "$PLUGIN_SOURCE" ]; then
  set -- "$@" "--source" "codecommit/$PLUGIN_SOURCE"
fi

eb deploy --process "$@"
