COPY (
       select   temperature,
                windspeed,
                winddirection,
                time_gmt
       from singapore_weather
       where time_gmt 
       = '{{dag_run.get_task_instance('is_api_available_weather').start_date.astimezone(dag.timezone).replace(microsecond=0, second=0, minute=0)}}'
) TO '{{ params.extract_weather_data }}' WITH (FORMAT CSV, HEADER);