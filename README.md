# Singapore reddit and weather correlation ELT Pipeline

End to end pipeline that extracts data from reddit (pushshift api) and open-meteo weather api to check for effects of weather on reddit post sentiment via Metabase 
dashboard visualisation.



**Data infrastructure**
![DE Infra](/assets/images/data_proj_flowchart.jpg)


Database migrations can be created as shown below.

```shell
make db-migration # enter a description, e.g. create some schema
# make your changes to the newly created file under ./migrations
make warehouse-migration # to run the new migration on your warehouse
```

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
