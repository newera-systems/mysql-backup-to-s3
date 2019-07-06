#!/bin/bash
# Function definitions used in the entrypoint file.

#
# Environment variable reading function
#
# The function enables reading environment variable from file.
#
# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature
function file_env() {
  local var="$1"
  local fileVar="${var}_FILE"
  local def="${2:-}"
  if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
    echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
    exit 1
  fi
  local val="$def"
  if [ "${!var:-}" ]; then
    val="${!var}"
  elif [ "${!fileVar:-}" ]; then
    val="$(< "${!fileVar}")"
  fi
  export "$var"="$val"
  unset "$fileVar"
}

#
# execute actual backup
#
function do_dump() {
  # what is the name of our source and target?
  now=$(date -u +"%Y%m%d_%H%M%S")

  # do the dump
  workdir=/tmp/backup.$$
  rm -rf $workdir
  mkdir -p $workdir

    if [[ -z "$DB_NAMES" ]]; then
      DB_NAMES=$(mysql -h $DB_SERVER -P $DB_PORT $DBUSER $DBPASS -N -e 'show databases where `Database` not like "information_schema" AND `Database` not like "performance_schema"')
      [ $? -ne 0 ] && return 1
    fi

    for onedb in $DB_NAMES; do

      ONEDB_SQL=${now}_$workdir/${onedb}.sql
      ONEDB_ZIP=${ONEDB_SQL}.tar.gz

      mysqldump -h $DB_SERVER -P $DB_PORT $DBUSER $DBPASS --databases ${onedb} $MYSQLDUMP_OPTS > $ONEDB_SQL
      [ $? -ne 0 ] && return 1

      tar -C $workdir -cvf - $ONEDB_SQL | gzip > $ONEDB_ZIP

      s3cmd ${AWS_ENDPOINT_OPT}  --host=$AWS_ENDPOINT_URL --access_key=${AWS_ACCESS_KEY_ID}   --secret_key=${AWS_SECRET_ACCESS_KEY}  put $ONEDB_ZIP  "${DB_DUMP_TARGET}"
      [ $? -ne 0 ] && return 1

    done


  rm -rf $workdir
  [ $? -ne 0 ] && return 1

  return 0
}



