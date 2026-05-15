{{
  config(
    materialized = 'table',
    tags = ['silver']
    )
}}

WITH source_deduplicate AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY driverId
            ORDER BY driverId
        ) AS rowNum
    FROM {{ ref('bronze_drivers') }}
),

casted AS (
    SELECT
        driverId,
        driverRef,
        TRY_CAST(NULLIF(number, '\N') AS INT) AS driverNumber,
        SUBSTR(CAST(NULLIF(code, '\N') AS VARCHAR), 1, 3) AS driverCode,
        forename,
        surname,
        CAST(dob AS DATE) AS dob,
        nationality,
        url
    FROM  source_deduplicate
    WHERE rowNum = 1
)

SELECT * FROM casted