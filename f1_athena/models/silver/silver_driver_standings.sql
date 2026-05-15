{{
  config(
    materialized = 'table',
    tags = ['silver']
    )
}}

WITH source_deduplicate As (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY driverStandingsId
            ORDER BY driverStandingsId
        ) AS rowNum 
    FROM {{ ref('bronze_driver_standings') }}
),

casted AS (
    SELECT
    driverStandingsId,
    raceId,
    driverId,
    CAST(points AS DECIMAL(4,1)) AS points,
    position,
    wins
    FROM source_deduplicate
    WHERE rowNum = 1
)

SELECT * FROM casted