#!/bin/bash

echo 'Running query ./redshift_setup/create_tables.sql'
export PGCLIENTENCODING=UTF-8
psql -f ./redshift_setup/create_tables.sql postgres://$(terraform -chdir=./terraform output -raw redshift_user):$(terraform -chdir=./terraform output -raw redshift_password)@$(terraform -chdir=./terraform output -raw redshift_dns_name):5439/dev