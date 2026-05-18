import sys
import os
import io
from datetime import datetime

import boto3
import fastf1
import pandas as pd
from awsglue.utils import getResolvedOptions


def get_job_parameters():
    return getResolvedOptions(sys.argv, [
        'JOB_NAME',
        'TempDir',
        'S3_BUCKET',
        'S3_PREFIX',
        'SEASON',
        'ROUND'
    ])


def setup_fastf1_cache():
    cache_dir = "/tmp/fastf1_cache"

    os.makedirs(cache_dir, exist_ok=True)

    fastf1.Cache.enable_cache(cache_dir)

    print(f"FastF1 cache enabled: {cache_dir}")


def fetch_race_session(season, round_number):

    print(f"Fetching season={season}, round={round_number}")

    session = fastf1.get_session(
        season,
        round_number,
        'R'
    )

    session.load(
        laps=True,
        telemetry=False,
        weather=False,
        messages=False
    )

    return {
        "races": session.results,
        "laps": session.laps
    }


def normalize_dataframe(df):

    if df is None:
        return None

    if not isinstance(df, pd.DataFrame):
        print(f"Unsupported type: {type(df)}")
        return None

    if df.empty:
        print("Empty dataframe")
        return None

    df = df.copy()

    # normalize columns safely
    df.columns = [
        str(col).strip().lower().replace(" ", "_")
        for col in df.columns
    ]

    return df


def filter_columns(df, dataset_type):

    column_mapping = {
        'races': [
            'driver',
            'drivernumber',
            'position',
            'ClassifiedPosition',
            'points',
            'status',
            'lapcount',
            'time',
            'gridposition'
        ],
        'laps': [
            'driver',
            'drivernumber',
            'lapnumber',
            'laptime',
            'sector1time',
            'sector2time',
            'sector3time',
            'ispersonalbest'
        ]
    }

    allowed = column_mapping.get(dataset_type)

    if not allowed:
        return df

    existing = [c for c in allowed if c in df.columns]

    return df[existing]


def add_metadata(df, season, round_number):

    df['_loaded_at'] = datetime.utcnow().isoformat()

    df['season'] = season

    df['race_round'] = round_number

    df['source_system'] = 'fastf1'

    return df


def write_to_s3(df, bucket, prefix, dataset_type, season, round_number):

    s3_key = (
        f"{prefix}"
        f"{dataset_type}/"
        f"{season}/"
        f"{round_number}/"
        f"{dataset_type}.csv"
    )

    csv_buffer = io.StringIO()

    df.to_csv(csv_buffer, index=False)

    boto3.client('s3').put_object(
        Bucket=bucket,
        Key=s3_key,
        Body=csv_buffer.getvalue(),
        ContentType='text/csv'
    )

    print(f"Wrote {dataset_type}")
    print(f"Rows: {len(df)}")
    print(f"S3: s3://{bucket}/{s3_key}")


def main():

    args = get_job_parameters()

    season = int(args['SEASON'])
    round_number = int(args['ROUND'])

    setup_fastf1_cache()

    datasets = fetch_race_session(
        season,
        round_number
    )

    for dataset_type, raw_df in datasets.items():

        print(f"\nDataset: {dataset_type}")
        print(f"Type: {type(raw_df)}")

        df = normalize_dataframe(raw_df)

        if df is None:
            print(f"Skipping {dataset_type}")
            continue

        df = filter_columns(df, dataset_type)

        df = add_metadata(
            df,
            season,
            round_number
        )

        print(f"Columns: {list(df.columns)}")
        print(f"Rows: {len(df)}")

        write_to_s3(
            df,
            args['S3_BUCKET'],
            args['S3_PREFIX'],
            dataset_type,
            season,
            round_number
        )

    print("\nPipeline completed successfully")


if __name__ == "__main__":
    main()