INSERT INTO public.reddit_weather_correlation (
    positive_count,
    negative_count,
    neutral_count,
    temperature,
    windspeed,
    date_time
)
SELECT 
count(case when red.label = 1 then red.label end) as positive_count,
count(case when red.label = -1 then red.label end) as negative_count,
count(case when red.label = 0 then red.label end) as neutral_count,
wea.temperature as temperature,
wea.windspeed as windspeed,
wea.timegmt as date_time
from spectrum.reddit_data_staging red
left join spectrum.weather_data_staging wea
on date_trunc('hour',red.created_gmt) = date_trunc('hour',wea.timegmt)
where red.insert_datetime = '{{ dag_run.get_task_instance('is_api_available_weather').start_date.astimezone(dag.timezone).replace(microsecond=0, second=0, minute=0)  }}'
and wea.insert_datetime = '{{ dag_run.get_task_instance('is_api_available_weather').start_date.astimezone(dag.timezone).replace(microsecond=0, second=0, minute=0) - macros.timedelta(hours=1)  }}'
group by wea.timegmt,wea.windspeed,wea.temperature;