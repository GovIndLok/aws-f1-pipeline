{{
  config(
    materialized = 'table',
    tags = ['silver']
    )
}}

WITH source_deduplicate AS (
    SELECT *,
    ROW_NUMBER() OVER (
        PARTITION BY constructorStandingsId
        ORDER BY constructorStandingsId
    ) AS rowNum 
    FROM {{ ref('bronze_constructor_standings') }}
),

casted AS (
    SELECT 
        constructorStandingsId,
        raceId,
        constructorId,
        CAST(points AS DECIMAL(5,1)) AS points,
        position,
        wins
    FROM source_deduplicate
    WHERE rowNum = 1
)

SELECT * FROM casted