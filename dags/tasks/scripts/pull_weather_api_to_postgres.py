import logging
import sys

import pandas as pd
import psycopg2.extras as p
import requests
from tasks.db_config.warehouse_conn import WarehouseConnection
from tasks.db_config.warehouse_cred import get_warehouse_creds


def get_weather_data():
    url = "https://api.open-meteo.com/v1/forecast?latitude=1.29&longitude=103.85&current_weather=true&timezone=Asia%2FSingapore"
    try:
        r = requests.get(url)
    except requests.ConnectionError as ce:
        logging.error(f"There was an error with the request, {ce}")
        sys.exit(1)
    return r.json().get('current_weather', [])

def weather_data_dataframe():
    df4 =pd.DataFrame.from_dict(get_weather_data(),orient='index').transpose()
    df4.rename(columns={"time": "time_gmt"}, inplace=True)
    df4['time_gmt'] = df4['time_gmt'].str.replace('T',' ')
    return df4

def weather_data_dict():
    df5 = weather_data_dataframe()
    final_weather = df5.to_dict('records') 
    return final_weather

def _get_exchange_insert_query():
    return '''
    INSERT INTO singapore_weather (
        temperature,
        windspeed,
        winddirection,
        weathercode,
        time_gmt
    )
    VALUES (
        %(temperature)s,
        %(windspeed)s,
        %(winddirection)s,
        %(weathercode)s,
        %(time_gmt)s
    );
    '''

def run_weather():
    with WarehouseConnection(get_warehouse_creds()).managed_cursor() as curr:
        p.execute_batch(curr, _get_exchange_insert_query(), weather_data_dict())