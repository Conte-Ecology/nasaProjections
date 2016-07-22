#!/bin/bash
# Drops all roles with database-level permissions
# usage: ./drop_all_roles.sh <dbname>

DB=$1

psql -d $DB -f drop-nasa_admin.sql
psql -d $DB -f drop-nasa_read.sql
psql -d $DB -f drop-nasa_write.sql
psql -d $DB -f drop-nasa_data.sql