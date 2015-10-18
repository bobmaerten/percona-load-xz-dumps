#!/bin/bash -e

xzcat "/var/local/${MYSQL_ENV_MYSQL_DATABASE}.sql.xz" | pv --progress --size $(xz --list --robot "/var/local/${MYSQL_ENV_MYSQL_DATABASE}.sql.xz" | tail -1 | awk '{print $5}') --name "Importing dump" | mysql -h"$MYSQL_PORT_3306_TCP_ADDR" -P"$MYSQL_PORT_3306_TCP_PORT" -u"$MYSQL_ENV_MYSQL_USER" -p"$MYSQL_ENV_MYSQL_PASSWORD" "$MYSQL_ENV_MYSQL_DATABASE" 2> /dev/null
