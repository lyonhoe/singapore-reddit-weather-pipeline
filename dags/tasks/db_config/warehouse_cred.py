import os

from tasks.db_config.warehouse_conn import DBConnection


def get_warehouse_creds() -> DBConnection:
    return DBConnection(
        user=os.getenv('WAREHOUSE_USER', 'airflow'),
        password=os.getenv('WAREHOUSE_PASSWORD', 'airflow'),
        db=os.getenv('WAREHOUSE_DB', 'airflow'),
        host= os.getenv('WAREHOUSE_HOST', 'postgres'),
        port=int(os.getenv('WAREHOUSE_PORT', 5432)),
    )