####################################################################################################################
# Setup containers to run Airflow

docker-spin-up:
	docker compose --env-file env up airflow-init && docker compose --env-file env up --build -d

perms:
	sudo mkdir -p logs plugins temp dags tests && sudo chmod -R u=rwx,g=rwx,o=rwx logs plugins temp dags tests

up: perms docker-spin-up

down:
	docker compose down

sh:
	docker exec -ti webserver bash

####################################################################################################################
# Set up cloud infrastructure

tf-init:
	terraform -chdir=./terraform init

infra-up:
	terraform -chdir=./terraform apply

infra-down:
	terraform -chdir=./terraform destroy

infra-config:
	terraform -chdir=./terraform output

####################################################################################################################
# Create tables in Redshift and Redshift spectrum

spectrum-migration:
	./aws_migration.sh

####################################################################################################################
# Port forwarding to local machine

cloud-metabase:
	terraform -chdir=./terraform output -raw private_key > private_key.pem && chmod 600 private_key.pem && ssh -o "IdentitiesOnly yes" -i private_key.pem ubuntu@$$(terraform -chdir=./terraform output -raw ec2_public_dns) -N -f -L 3001:$$(terraform -chdir=./terraform output -raw ec2_public_dns):3000 && start http://localhost:3001 && rm private_key.pem

cloud-airflow:
	terraform -chdir=./terraform output -raw private_key > private_key.pem && chmod 600 private_key.pem && ssh -o "IdentitiesOnly yes" -i private_key.pem ubuntu@$$(terraform -chdir=./terraform output -raw ec2_public_dns) -N -f -L 8081:$$(terraform -chdir=./terraform output -raw ec2_public_dns):8080 && start http://localhost:8081 && rm private_key.pem

####################################################################################################################
# Helpers

ssh-ec2:
	terraform -chdir=./terraform output -raw private_key > private_key.pem && chmod 600 private_key.pem && ssh -o StrictHostKeyChecking=no -o IdentitiesOnly=yes -i private_key.pem ubuntu@$$(terraform -chdir=./terraform output -raw ec2_public_dns) && rm private_key.pem
