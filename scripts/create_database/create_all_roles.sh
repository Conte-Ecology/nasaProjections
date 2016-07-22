#!/bin/bash
# Creates all roles with database-level permissions
# usage: ./create_all_roles.sh <dbname>

DB=$1

psql -d $DB -f create-nasa_admin.sql
psql -d $DB -f create-nasa_read.sql
psql -d $DB -f create-nasa_write.sql

psql -d $DB -c "GRANT TEMPORARY, CONNECT ON DATABASE $DB TO nasa_read";
psql -d $DB -c "GRANT CREATE ON DATABASE $DB TO nasa_write";
psql -d $DB -c "GRANT CREATE, TEMPORARY, CONNECT ON DATABASE $DB TO nasa_admin";