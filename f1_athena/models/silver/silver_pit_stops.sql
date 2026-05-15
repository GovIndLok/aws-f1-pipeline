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
            PARTITION BY raceId, driverId, stop
            ORDER BY raceId, driverId, stop
        ) AS rowNum
    FROM {{ ref('bronze_pit_stops') }}
)

SELECT 
    raceId,
    driverId,
    stop,
    lap,
    time,
    milliseconds
FROM source_deduplicate
WHERE rowNum = 1