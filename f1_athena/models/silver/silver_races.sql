{{
  config(
    materialized = 'table',
    tags = ['silver']
    )
}}

WITH source_deduplicate AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY raceId
            ORDER BY raceId
        ) AS rowNum
    FROM {{ ref('bronze_races') }}
),

cleaned AS (
    SELECT 
        raceId,
        year,
        round,
        circuitId,
        name,
        date AS raceDate,
        time AS raceTime,
        TRY (
            DATE_PARSE(
                CASE 
                    WHEN regexp_like(CAST(date AS VARCHAR), '^[0-9]') AND regexp_like(CAST(time AS VARCHAR), '^[0-9]')
                    THEN CAST(date AS VARCHAR) || ' ' || time
                    ELSE NULL
                END,
                '%Y-%m-%d %H:%i:%s'
            )
        ) AS race_timestamp,
        url 
    FROM source_deduplicate
    WHERE rowNum = 1
)

SELECT * FROM cleaned