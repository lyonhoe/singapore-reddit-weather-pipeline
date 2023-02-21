import json
from datetime import datetime, timedelta, timezone

import nltk
import pandas as pd

nltk.download('vader_lexicon')
import time

import psycopg2.extras as p
import requests
from nltk.sentiment.vader import SentimentIntensityAnalyzer as SIA
from tasks.db_config.warehouse_conn import WarehouseConnection
from tasks.db_config.warehouse_cred import get_warehouse_creds


def getPushshiftData(after, before, sub):
    url = 'https://api.pushshift.io/reddit/search/submission/?after='+str(after)+'&before='+str(before)+'&subreddit='+str(sub)
    r = requests.get(url)
    data = json.loads(r.text)
    return data['data']

def collectSubData(subm):
    subStats = {}
    subStats['title'] = subm['title']
    subStats['created_gmt'] = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(subm['created_utc']))
    subStats['selftext'] = subm['selftext']
    subStats['author'] = subm['author']
    subStats['score'] = subm['score']
    subStats['number_comments'] = subm['num_comments']
    subStats['video_content'] = subm['is_video']
    subStats['subreddit'] = subm['subreddit']
    subStats['submission_url'] = subm['url']
    return subStats

def reddit_into_dataframe():
    # return df of reddit submission relevant info
    after = int((datetime.now(timezone.utc).replace(microsecond=0, second=0, minute=0) - timedelta(hours=1)).timestamp()) #1 hour before
    before = int((datetime.now(timezone.utc).replace(microsecond=0, second=0, minute=0) - timedelta(hours=0)).timestamp())  #current time
    sub = "singapore,asksingapore"
    list_of_subStats = []
    data = getPushshiftData(after, before, sub)
    for i in data:
        list_of_subStats.append(collectSubData(i))
    df = pd.DataFrame.from_dict(list_of_subStats)
    return df

def running_sentiment_analyzer_on_reddit_data():
    sia = SIA()
    list_of_statscores = []
    reddit_df = reddit_into_dataframe()
    for i in reddit_df['title']:
        pol_score = sia.polarity_scores(i)
        list_of_statscores.append(pol_score)
    df2 = pd.DataFrame.from_dict(list_of_statscores)
    df3 = pd.concat([reddit_into_dataframe(),df2],axis =1)
    return df3

def process_reddit_data():
    df3 = running_sentiment_analyzer_on_reddit_data()
    df3['label'] = 0
    df3.loc[df3['compound'] > 0.2, 'label'] = 1
    df3.loc[df3['compound'] < -0.2, 'label'] = -1
    return df3
    

def reddit_data_dict():
    final_reddit_data = process_reddit_data().to_dict('records') 
    return final_reddit_data

def insert_reddit_data():
    return '''
    INSERT INTO reddit_submission (
        title,
        created_gmt,
        selftext,
        author,
        score,
        number_comments,
        video_content,
        subreddit,
        submission_url,
        neg,
        neu,
        pos,
        compound,
        label
    )
    VALUES (
        %(title)s,
        %(created_gmt)s,
        %(selftext)s,
        %(author)s,
        %(score)s,
        %(number_comments)s,
        %(video_content)s,
        %(subreddit)s,
        %(submission_url)s,
        %(neg)s,
        %(neu)s,
        %(pos)s,
        %(compound)s,
        %(label)s
    );
    '''


def run_reddit():
    with WarehouseConnection(get_warehouse_creds()).managed_cursor() as curr:
        p.execute_batch(curr, insert_reddit_data(), reddit_data_dict())

if __name__ == '__main__':
    run_reddit()