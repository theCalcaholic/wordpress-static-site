#!/usr/bin/bash

set -ex

read -r -p "Enter the intended domain for your static site: " DOMAIN
read -r -p "Enter your admin (wordpress) domain (keep empty for default 'admin.${DOMAIN}'): " ADMIN_DOMAIN
ADMIN_DOMAIN="${ADMIN_DOMAIN:-"admin.${DOMAIN}"}"
read -r -p "Enter your matomo domain (keep empty for default 'matomo.${DOMAIN}'): " MATOMO_DOMAIN
MATOMO_DOMAIN="${MATOMO_DOMAIN:-"matomo.${DOMAIN}"}"
read -r -p "Enter your comentario domain (keep empty for default 'comentario.${DOMAIN}'): " COMMENTS_DOMAIN
COMMENTS_DOMAIN="${COMMENTS_DOMAIN:-"comments.${DOMAIN}"}"

CADDYFILE="Caddyfile"
ADMIN_EMAIL=""
while true
do
  read -r -N 1 -p "Do you want to use self signed certificates (e.g. for local testing or with dummy domains)? (y/N) " local_setup
  echo ''
  local_setup="${local_setup,,}"
  if [[ "${local_setup}" == y ]]
  then
    CADDYFILE="Caddyfile-local"
    break
  elif [[ "${local_setup}" == n ]]
  then
    read -r -p "Enter an email address to be used for letsencrypt certificates: " ADMIN_EMAIL
    break
  fi
  echo "Invalid choice! Please enter y (yes) or n (no)."
done

read -r -p "Enter a username for basic authentication: " BASIC_AUTH_USER
read -r -p "Enter a password for basic authentication: " BASIC_AUTH_PW

CONTAINER_CLI=""
if docker version > /dev/null 2>&1
then
  CONTAINER_CLI="docker"
elif podman version > /dev/null 2>&1
then
  CONTAINER_CLI="podman"
fi

if [[ -z "$CONTAINER_CLI" ]]
then
  echo "No container runtime found! Please install docker or podman and make sure their command line interface is in the PATH."
  exit 1
fi

BASIC_AUTH_PW_HASH="$("${CONTAINER_CLI}" run --rm docker.io/library/caddy:2 caddy hash-password --plaintext "${BASIC_AUTH_PW}")"

POSTGRES_PASSWORD="$(base64 < /dev/urandom | head -c 32)"
MATOMO_DB_PASSWORD="$(base64 < /dev/urandom | head -c 32)"

cat <<EOF > .env
DOMAIN="${DOMAIN?}"
ADMIN_DOMAIN="${ADMIN_DOMAIN?}"
MATOMO_DOMAIN="${MATOMO_DOMAIN?}"
COMMENTS_DOMAIN="${COMMENTS_DOMAIN?}"
ADMIN_EMAIL="${ADMIN_EMAIL}"

DB_ROOT_PASSWORD="$(base64 < /dev/urandom | head -c 32)"
WORDPRESS_DB_PASSWORD="$(base64 < /dev/urandom | head -c 32)"
MATOMO_DB_PASSWORD="${MATOMO_DB_PASSWORD}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD?}"

BASIC_AUTH_USER="${BASIC_AUTH_USER?}"
BASIC_AUTH_PW_HASH="${BASIC_AUTH_PW_HASH?}"

CADDYFILE="${CADDYFILE}"
EOF

mkdir -p ./comentario
cat <<EOF > ./comentario/secrets.yaml
postgres:
  host:     comments-db
  port:     5432
  database: comentario
  username: postgres
  password: "${POSTGRES_PASSWORD?}"
EOF

mkdir -p wordpress-db/init.d
cat <<EOF > wordpress-db/init.d/matomo.sql
CREATE DATABASE matomo;
CREATE USER 'matomo' IDENTIFIED BY '${MATOMO_DB_PASSWORD}';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, INDEX, DROP, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES ON matomo.* TO 'matomo';
GRANT FILE ON *.* TO 'matomo';
EOF

if [[ "$local_setup" == "y" ]]
then
  while true
  do
    read -r -N 1 -p "Do you want to add the domains to /etc/hosts for local testing (requires root permissions)? (y/N) " choice
    echo ''
    local_setup="${local_setup,,}"
    if [[ "${choice}" == y ]]
    then
      for domain in "$DOMAIN" "$ADMIN_DOMAIN" "$COMMENTS_DOMAIN" "$MATOMO_DOMAIN"
      do
        grep "$domain" /etc/hosts > /dev/null || echo "127.0.0.1 $domain" | sudo tee -a /etc/hosts
      done
      break
    elif [[ "$choice" == n ]]
    then
      break
    fi

  done
  echo "Invalid choice! Please enter y (yes) or n (no)."
fi

