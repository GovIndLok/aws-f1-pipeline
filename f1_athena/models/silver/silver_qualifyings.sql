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
    FROM {{ ref('bronze_qualifyings') }}
),

casted AS (
    SELECT 
        qualifyId,
        raceId,
        driverId,
        constructorId,
        position,
        -- q1/q2/q3 stored as 'm:ss.mmm' — convert to total seconds as INT
        CASE 
            WHEN regexp_like(q1, '^[0-9]')
            THEN (TRY_CAST(SPLIT(q1, ':')[1] AS DOUBLE) * 60) + TRY_CAST(SPLIT(q1, ':')[2] AS DOUBLE)
            ELSE NULL
        END AS q1_sec,
        CASE 
            WHEN regexp_like(q2, '^[0-9]')
            THEN (TRY_CAST(SPLIT(q2, ':')[1] AS DOUBLE) * 60) + TRY_CAST(SPLIT(q2, ':')[2] AS DOUBLE)
            ELSE NULL
        END AS q2_sec,
        CASE 
            WHEN regexp_like(q3, '^[0-9]')
            THEN (TRY_CAST(SPLIT(q3, ':')[1] AS DOUBLE) * 60) + TRY_CAST(SPLIT(q3, ':')[2] AS DOUBLE)
            ELSE NULL
        END AS q3_sec
    FROM source_deduplicate
    WHERE rowNum = 1
)

SELECT * FROM casted