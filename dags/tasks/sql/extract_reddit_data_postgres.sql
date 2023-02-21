SET LOCAL timezone = 'Singapore';

COPY ( 
       select   title,
                created_gmt,
                author,
                video_content,
                subreddit,
                submission_url,
                label
       from reddit_submission
       where created_gmt 
       >= '{{dag_run.get_task_instance('is_api_available_reddit').start_date.astimezone(dag.timezone).replace(microsecond=0, second=0, minute=0) - macros.timedelta(hours=1) }}'
       and created_gmt < '{{dag_run.get_task_instance('is_api_available_reddit').start_date.astimezone(dag.timezone).replace(microsecond=0, second=0, minute=0) }}'
       order by created_gmt desc
) TO '{{ params.extract_reddit_data }}' WITH (FORMAT CSV, HEADER, DELIMITER '~');