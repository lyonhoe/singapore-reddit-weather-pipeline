# Singapore reddit and weather correlation ELT pipeline

End to end pipeline that extracts data from reddit (pushshift api) and open-meteo weather api to check for effects of weather on reddit post sentiment via Metabase 
dashboard visualisation.



# Data infrastructure
![DE Infra](/assets/images/data_proj_flowchart.jpg)

AWS cloud infrastructure is provisioned through Terraform, orchestrated through Airflow, containerised through Docker and output is visualised through Metabase.















For the [continuous delivery](https://github.com/josephmachado/data_engineering_project_template/blob/main/.github/workflows/cd.yml) to work, set up the infrastructure with terraform, & defined the following repository secrets. You can set up the repository secrets by going to `Settings > Secrets > Actions > New repository secret`.

1. **`SERVER_SSH_KEY`**: We can get this by running `terraform -chdir=./terraform output -raw private_key` in the project directory and paste the entire content in a new Action secret called SERVER_SSH_KEY.
2. **`REMOTE_HOST`**: Get this by running `terraform -chdir=./terraform output -raw ec2_public_dns` in the project directory.
3. **`REMOTE_USER`**: The value for this is **ubuntu**.

### Tear down infra

After you are done, make sure to destroy your cloud infrastructure.

```shell
make down # Stop docker containers on your computer
make infra-down # type in yes after verifying the changes TF will make
```
