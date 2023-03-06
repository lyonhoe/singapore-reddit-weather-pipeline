CREATE EXTERNAL TABLE spectrum.reddit_data_staging (
   Title VARCHAR(max),
   Created_gmt TIMESTAMP,
   Author VARCHAR(100),
   Video_content VARCHAR(100),
   Subreddit VARCHAR(100),
   Submission_url VARCHAR(1000),
   Label INT
) PARTITIONED BY (insert_datetime TIMESTAMP) ROW FORMAT DELIMITED FIELDS TERMINATED BY '~' STORED AS textfile LOCATION 's3://singapore-weather-reddit/stage/reddit_data/' TABLE PROPERTIES ('skip.header.line.count' = '1');

CREATE EXTERNAL TABLE spectrum.weather_data_staging (
   Temperature DECIMAL(4, 2),
   Windspeed DECIMAL(4, 2),
   Winddirection DECIMAL(5, 2),
   TimeGmt TIMESTAMP
) PARTITIONED BY (insert_datetime TIMESTAMP) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' STORED AS textfile LOCATION 's3://singapore-weather-reddit/stage/weather_data/' TABLE PROPERTIES ('skip.header.line.count' = '1');

CREATE TABLE IF NOT EXISTS public.reddit_weather_correlation (
   positive_count INTEGER,
   negative_count INTEGER,
   neutral_count INTEGER,
   temperature DECIMAL(4, 2),
   windspeed DECIMAL(4, 2),
   date_time TIMESTAMP
);