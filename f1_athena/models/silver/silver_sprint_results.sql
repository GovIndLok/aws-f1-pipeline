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
            PARTITION BY raceId, driverId
            ORDER BY raceId, driverId
        ) AS rowNum 
    FROM {{ ref('bronze_sprint_results') }}
),

casted AS (
    SELECT
        resultId,
        raceId,
        driverId,
        number,
        grid,
        TRY_CAST(position AS INT) finishPosition,
        NULLIF(positionText, '\N') AS resultCode,
        PositionOrder AS finishOrder,
        TRY_CAST(points AS DOUBLE) AS points,
        laps,
        CASE 
            WHEN regexp_like(time, '^[+]?[0-9]')
            THEN time 
            ELSE NULL 
        END AS timeDisplay,
        TRY_CAST(milliseconds AS INT) AS timeMilliseconds,
        TRY_CAST(fastestLap AS INT) AS fastestLap,
        NULLIF(fastestLapTime, '\N') AS fastestLapTimeDisplay,

        --- Convert fastestLapTime to milliseconds
        CASE 
            WHEN fastestLapTime LIKE '%:%' THEN 
            (
                --- min to milli seconds
                TRY_CAST(SPLIT_PART(fastestLapTime, ':', 1) AS DOUBLE) * 60 * 1000
            ) +
            (
                --- seconds.milliseconds to milliseconds
                TRY_CAST(SPLIT_PART(fastestLapTime, ':', 2) AS DOUBLE) * 1000
            )
            ELSE NULL 
        END AS fastestLapTimeMilliseconds,

        statusId
    FROM source_deduplicate
    WHERE rowNum = 1
)

SELECT * FROM casted