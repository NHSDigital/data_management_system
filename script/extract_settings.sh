#!/bin/bash

# ===========================================================
# DESCRIPTION:
#   This script extracts application settings from a live
#   server, for environment variables.
# ===========================================================


if [ -z "$CURRENT" ]; then
  CURRENT=$HOME/mbis_front/current
fi

if [ ! -e "$CURRENT" ]; then
  echo Please configure CURRENT in this script!
  exit 1
fi

CONFIG="$CURRENT/config"

# =================================================================================================
# Config files
#
# Can be supplied as Base64 encoded strings via ENV vars and will be written to file.
#

# Writes the contents of an environment variable to STDOUT, to make it easy to
# copy and paste into a secret store
# Usage emit_environment_variable VARIABLE_NAME CONTENTS
function emit_environment_variable {
    echo "$1: (`echo "$2" | tr -d "\n" | wc -c | tr -d ' '` bytes)"
    echo "$2"
    echo
}

# Helper function to encode a file as a Base64 string, suitable for adding to
# environment variables for server startup.
# Usage: encode64 VARIABLE_NAME FILENAME
function encode64 {
  if [ -n "$1" ]; then
      if [ -e "$2" ]; then
      emit_environment_variable "$1" "`base64 "$2" | tr -d "\n"`"
    else
      echo "Cannot set $1: file $2 not found" >&2
    fi  
  fi
}

encode64 "ADMIN_USERS_BASE64" "$CONFIG/admin_users.yml"
encode64 "DATABASE_BASE64" "$CONFIG/database.yml"
encode64 "CREDENTIALS_BASE64" "$CONFIG/credentials.yml.enc"
encode64 "EXCLUDED_MBISIDS_BASE64" "$CONFIG/excluded_mbisids.yml.enc"
encode64 "ODR_USERS_BASE64" "$CONFIG/odr_users.yml"
encode64 "SMTP_SETTINGS_BASE64" "$CONFIG/smtp_settings.yml"
encode64 "SPECIAL_USERS_BASE64" "$CONFIG/special_users.production.yml"
encode64 "USER_YUBIKEYS_BASE64" "$CONFIG/user_yubikeys.yml"

if [ -e "$CONFIG/master.key" ]; then
  emit_environment_variable "SECRET_KEY_BASE" "`cat "$CONFIG/master.key"`"
fi

# Not needed for webapps, only for god services:
# encode64 "$REGULAR_EXTRACTS_BASE64" "$CONFIG/regular_extracts.csv"

encode64 PUBLIC_KEY_BASE64 "$CONFIG/keys/mbis_project_data_passwords_20180323_public.pem"

# Not needed on AWS
# encode64 $CERTIFICATES_ENCRYPTION_BASE64 "$CONFIG/certificates/saml/encryption.phe.adfs.pem"
# encode64 $CERTIFICATES_SIGNING_BASE64 "$CONFIG/certificates/saml/signing.phe.adfs.pem"
# =================================================================================================
