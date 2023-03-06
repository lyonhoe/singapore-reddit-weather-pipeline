from datetime import datetime, timedelta

import pendulum
from tasks.aws.postgres_to_s3 import _local_to_s3
from tasks.aws.redshift_con import run_redshift_external_query
from tasks.scripts.pull_reddit_api_to_postgres import run_reddit
from tasks.scripts.pull_weather_api_to_postgres import run_weather

from airflow import DAG
from airflow.models import Variable
from airflow.operators.python import PythonOperator
from airflow.providers.http.sensors.http import HttpSensor
from airflow.providers.postgres.operators.postgres import PostgresOperator

local_tz = pendulum.timezone("Asia/Singapore")

# Config
BUCKET_NAME = Variable.get("BUCKET")

default_args = {
            "owner": "Airflow",
            "retries": 2,
            "retry_delay": timedelta(minutes=1),
            "start_date" : datetime(2023, 2, 21, tzinfo=local_tz)
        }

dag = DAG(
    "reddit_weather_singapore",
    default_args=default_args,
    schedule_interval= '@hourly',
    max_active_runs=1,
    catchup=False
)


is_api_available_reddit = HttpSensor(
        dag = dag,
        task_id='is_api_available_reddit',
        method='GET',
        http_conn_id='is_api_available_reddit',
        endpoint= 'reddit/search/submission/?after=1675123200&before=1675126800&subreddit=singapore,asksingapore',
        response_check= lambda response: "data" in response.text,
        poke_interval = 5
)


create_table_reddit = PostgresOperator(
        dag = dag,
        task_id = 'create_table_reddit',
        postgres_conn_id='postgres',
        sql=''' 
            CREATE TABLE IF NOT EXISTS reddit_submission(
                title text,
                created_gmt timestamptz,
                selftext text,
                author text,
                score int,
                number_comments int,
                video_content text,
                subreddit text,
                submission_url text,
                neg float,
                neu float,
                pos float,
                compound float,
                label int
            );
        '''
    )


load_reddit_data = PythonOperator(
        dag = dag,
        task_id = 'store_reddit_data_postgres',
        python_callable= run_reddit

    )

extract_reddit_data_from_postgres = PostgresOperator(
    dag=dag,
    task_id="extract_reddit_data_from_postgres",
    sql="./tasks/sql/extract_reddit_data_postgres.sql",
    postgres_conn_id="postgres",
    params={
        "extract_reddit_data": "/temp/extract_reddit_data.csv"
    }
)

reddit_data_to_stage_data_lake = PythonOperator(
    dag=dag,
    task_id="reddit_to_stage_data_lake",
    python_callable= _local_to_s3,
    op_kwargs={
        "file_name": "/opt/airflow/temp/extract_reddit_data.csv",
        "key": "stage/reddit_data/{{ dag_run.logical_date.astimezone(dag.timezone).replace(microsecond=0, second=0, minute=0) }}/extract_reddit_data.csv",
        "bucket_name": BUCKET_NAME,
        "remove_local": "True",
    }
)

reddit_data_stage_data_lake_to_stage_tbl = PythonOperator(
    dag=dag,
    task_id="reddit_data_stage_data_lake_to_stage_tbl",
    python_callable= run_redshift_external_query,
    op_kwargs={
        "qry": "alter table spectrum.reddit_data_staging add if not exists partition(insert_datetime='{{ dag_run.get_task_instance('is_api_available_reddit').start_date.astimezone(dag.timezone).replace(microsecond=0, second=0, minute=0) }}') \
            location 's3://"
        + BUCKET_NAME
        + "/stage/reddit_data/{{ dag_run.get_task_instance('is_api_available_reddit').start_date.astimezone(dag.timezone).replace(microsecond=0, second=0, minute=0) }}'",
    },
)


is_api_available_weather = HttpSensor(
        dag = dag,
        task_id='is_api_available_weather',
        method='GET',
        http_conn_id='is_api_available_weather',
        endpoint= 'v1/forecast?latitude=1.29&longitude=103.85&current_weather=true&timezone=Asia%2FSingapore',
        response_check= lambda response: "current_weather" in response.text,
        poke_interval = 5
)

create_table_weather = PostgresOperator(
        dag = dag,
        task_id = 'create_table_weather',
        postgres_conn_id='postgres',
        sql='''
            CREATE TABLE IF NOT EXISTS singapore_weather(
                temperature float,
                windspeed float,
                winddirection float,
                weathercode int,
                time_gmt timestamp
            );
        '''
    )

load_weather_data_postgres = PythonOperator(
    dag=dag,
    task_id="store_weather_data_postgres",
    python_callable= run_weather
)

extract_weather_data_from_postgres = PostgresOperator(
    dag=dag,
    task_id="extract_weather_data_from_postgres",
    sql="./tasks/sql/extract_weather_data_postgres.sql",
    postgres_conn_id="postgres",
    params={
        "extract_weather_data": "/temp/extract_weather_data.csv"
    }
)

weather_data_to_stage_data_lake = PythonOperator(
    dag=dag,
    task_id="weather_to_stage_data_lake",
    python_callable= _local_to_s3,
    op_kwargs={
        "file_name": "/opt/airflow/temp/extract_weather_data.csv",
        "key": "stage/singapore_weather/{{ dag_run.get_task_instance('is_api_available_weather').start_date.astimezone(dag.timezone).replace(microsecond=0, second=0, minute=0) }}/extract_reddit_data.csv",
        "bucket_name": BUCKET_NAME,
        "remove_local": "True",
    }
)

weather_data_stage_data_lake_to_stage_tbl = PythonOperator(
    dag=dag,
    task_id="weather_data_stage_data_lake_to_stage_tbl",
    python_callable= run_redshift_external_query,
    op_kwargs={
        "qry": "alter table spectrum.weather_data_staging add if not exists partition(insert_datetime='{{ dag_run.get_task_instance('is_api_available_weather').start_date.astimezone(dag.timezone).replace(microsecond=0, second=0, minute=0) }}') \
            location 's3://"
        + BUCKET_NAME
        + "/stage/singapore_weather/{{ dag_run.get_task_instance('is_api_available_weather').start_date.astimezone(dag.timezone).replace(microsecond=0, second=0, minute=0) }}'",
    },
)

generate_weather_reddit_correlation_data = PostgresOperator(
    dag=dag,
    task_id="generate_weather_reddit_correlation_data",
    sql="./tasks/sql/generate_correlation_data.sql",
    postgres_conn_id="redshift",
)

is_api_available_weather >> create_table_weather >> load_weather_data_postgres >> extract_weather_data_from_postgres >> weather_data_to_stage_data_lake >> weather_data_stage_data_lake_to_stage_tbl
is_api_available_reddit >> create_table_reddit >> load_reddit_data >> extract_reddit_data_from_postgres >> reddit_data_to_stage_data_lake >> reddit_data_stage_data_lake_to_stage_tbl

[weather_data_stage_data_lake_to_stage_tbl,reddit_data_stage_data_lake_to_stage_tbl] >> generate_weather_reddit_correlation_data