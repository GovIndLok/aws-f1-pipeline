{{
  config(
    materialized = 'table',
    tags = ['gold', 'dimensions']
    )
}}

SELECT
    circuitId,
    circuitRef,
    name AS circuitName,
    location AS circuitLocation,
    country,
    lat AS latitude,
    lng AS longitude,
    alt AS altitude
FROM {{ ref('silver_circuits') }}
