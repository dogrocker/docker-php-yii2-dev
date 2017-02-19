#!/bin/bash

set -e

DB_TYPE=${DB_TYPE:-mysql}
DB_HOST=${DB_HOST:-}
DB_PORT=${DB_PORT:-}
DB_NAME=${DB_NAME:-}
DB_USER=${DB_USER:-}
DB_PASS=${DB_PASS:-}
# support for linked mysql image
if [[ -n ${MYSQL_PORT_3306_TCP_ADDR} ]]; then
	DB_TYPE=${DB_TYPE:-mysql}
	DB_HOST=${DB_HOST:-${MYSQL_PORT_3306_TCP_ADDR}}
	DB_PORT=${DB_PORT:-${MYSQL_PORT_3306_TCP_PORT}}
	DB_USER=${DB_USER:-${MYSQL_ENV_MYSQL_USER}}
	DB_PASS=${DB_PASS:-${MYSQL_ENV_MYSQL_PASSWORD}}
	DB_NAME=${DB_NAME:-${MYSQL_ENV_MYSQL_DATABASE}}
fi
DB_DSN="${DB_TYPE}:host=${DB_HOST};port=${DB_PORT};dbname=${DB_NAME}"

FAST_PARAMS=/etc/nginx/conf.d/site-fast_params
PROFILE_PARAMS=/etc/profile.d/web.sh
rm -f ${FAST_PARAMS} ${PROFILE_PARAMS}
touch ${FAST_PARAMS} ${PROFILE_PARAMS}
function add_param() {
	echo "fastcgi_param ${1} \"${2}\";" >> ${FAST_PARAMS}
	echo "export ${1}=\"${2}\"" >> ${PROFILE_PARAMS}
}

for i in `(set -o posix;set)`
do
	variable=$(echo "$i" | cut -d'=' -f1)
	if [[ $variable == DB_* ]]; then
		value=${!variable}
		add_param ${variable} ${value}
		export ${variable}
	elif [[ $variable = ENV_* ]]; then
		value=${!variable}
		name=${variable/ENV_/}
		add_param ${name} ${value}
		eval ${name}=$value
		export ${name}
	fi
done

exec "$@"
