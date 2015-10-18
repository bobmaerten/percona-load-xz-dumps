#!/usr/bin/env bash
set -e

IMAGE_NAME='levups/percona'

usage() {
  echo "Usage: $0 <db_name>"
  echo "  Expects a xz compressed SQL dump file in dumps/<db_name>.sql.xz"
  exit 2
}

require_docker() {
  echo "Docker is required, please install first."
  exit 2
}

require_levups_percona() {
  docker images | grep -q $IMAGE_NAME || docker build -t $IMAGE_NAME .
}

check_container() {
  local pattern=$1
  docker ps -a | grep $IMAGE_NAME | awk '{print $NF}' | grep -q $pattern
}

find_or_create_data_container() {
  local name=$1
  check_container mysqldata-$name || docker create --name mysqldata-$name $IMAGE_NAME
}

check_mysql() {
  run_mysql_client $1 '/var/local/check.sh' | sed 's/[^0-9]*//g'
}

wait_for_percona() {
  local name=$1
  local check=$(check_mysql $name)
  echo -n 'Waiting for percona to start.'
  while [ "$check" != "1" ]
  do
    sleep 1
    echo -n '.'
    check=$(check_mysql $name)
  done
  echo ' Started. '
}

run_mysql_server() {
  local name=$1
  check_container mysqlserver-$name || docker run --name mysqlserver-$name --volumes-from mysqldata-$name -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=$name -e MYSQL_USER=user -e MYSQL_PASSWORD=password -d $IMAGE_NAME
  wait_for_percona $name
}

run_mysql_client() {
  local name=$1
  local command=$2
  docker run -it --link mysqlserver-${name}:mysql --rm -v $(pwd)/dumps:/var/local $IMAGE_NAME $command
}

load_mysql_dump() {
  local name=$1
  [ -d "$(pwd)/dumps" ] || { echo "Missing Dump directory." && exit 1 ; }
  [ -f "$(pwd)/dumps/${name}.sql.xz" ] || { echo "Dump file not found." && exit 1 ; }
  [ -x "$(pwd)/dumps/load.sh" ] || { echo "Dump script not found." && exit 1 ; }
  run_mysql_client $name '/var/local/load.sh'
}

[ -x `which docker` ] || require_docker
[ $# -ne 1 ] && usage
require_levups_percona

DB=$1

find_or_create_data_container $DB
run_mysql_server $DB
load_mysql_dump $DB
