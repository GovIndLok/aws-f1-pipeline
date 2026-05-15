{{
  config(
    materialized = 'table',
    tags = ['silver']
    )
}}

WITH source_deduplicate AS (
    SELECT *,
    ROW_NUMBER() OVER (
        PARTITION BY circuitId
        ORDER BY circuitId
    ) AS rowNum 
    FROM {{ ref('bronze_circuits') }}
),

casted_circuits AS (
    SELECT 
        circuitId,
        circuitRef,
        name,
        location,
        country,
        CAST(lat as DECIMAL(10, 7)) AS lat,
        CAST(lng as DECIMAL(10, 7)) AS lng,
        alt,
        url
    FROM source_deduplicate
    WHERE rowNum = 1
)

SELECT * FROM casted_circuits