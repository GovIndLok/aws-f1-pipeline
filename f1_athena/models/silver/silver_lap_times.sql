{{
  config(
    materialized = 'table',
    tags = ['silver']
    )
}}

WITH source_cast AS (
    SELECT 
        raceId,
        driverId,
        lap,
        position,
        CASE WHEN regexp_like(time, '^[0-9]') THEN time ELSE NULL END AS timeDisplay,
        TRY_CAST(milliseconds AS INT) AS milliseconds
    FROM {{ ref('bronze_lap_times') }}
),

deduplicate AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY raceId, driverId, lap 
            ORDER BY raceId
        ) AS rowNum
    FROM source_cast
)

SELECT 
    raceId,
    driverId,
    lap,
    position,
    timeDisplay,
    milliseconds
FROM deduplicate
WHERE rowNum = 1