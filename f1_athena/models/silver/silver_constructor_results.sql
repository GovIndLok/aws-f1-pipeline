{{
  config(
    materialized = 'table',
    tags = ['silver']
    )
}}

WITH source_deduplicate AS (
    SELECT *,
    ROW_NUMBER() OVER (
        PARTITION BY constructorResultsId
        ORDER BY constructorResultsId
    ) AS rowNum 
    FROM {{ ref('bronze_constructor_results') }}
),

clean_casted AS (
    SELECT 
        constructorResultsId,
        raceId,
        constructorId,
        CAST(points AS DOUBLE) AS points,
        SUBSTR(CAST(TRY_CAST(NULLIF(status, '\N') AS INT) AS VARCHAR), 1, 3) AS status
    FROM source_deduplicate
    WHERE rowNum = 1
)

SELECT * FROM clean_casted