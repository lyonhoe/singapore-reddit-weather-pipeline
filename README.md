## Singapore reddit and weather correlation ETL pipeline

End to end pipeline that extracts data from reddit (pushshift api) and open-meteo weather api to check for effects of weather on reddit post sentiment via Metabase 
dashboard visualisation.



# Data infrastructure
![DE Infra](/assets/images/data_proj_flowchart.jpg)

AWS cloud infrastructure is provisioned through Terraform, orchestrated through Airflow, containerised through Docker and output is visualised through Metabase.

# Dashboard
![DE Infra](/assets/images/reddit_weather_dashboard.png)

# Pipeline Flow

1. Data is extracted from both Reddit and Open-Meteo API
2. Reddit post title is analyzed using a Sentiment Analyzer and sentiment statistics is added to raw data
3. Both reddit and weather data are loaded into a Postgres OLTP database
4. Selected data are pulled from Postgres and loaded into s3 bucket
5. Data is combined and transformed via Redshift spectrum
6. Final data visualised through Metabase

# Instructions to setup

1. make tf-init # if you added new providers
2. make infra-up # set up infra on AWS cloud. Wait for about 5 minutes before proceeding
3. make spectrum-migration # setup tables on Redshift and Redshift Spectrum
4. make cloud-airflow # forward Airflow port from EC2 to local machine to display on browser
5. make cloud-metabase # forward Metabase port from EC2 to local machine to display on browser