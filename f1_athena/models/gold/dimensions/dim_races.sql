{{
  config(
    materialized = 'table',
    tags = ['gold', 'dimensions']
    )
}}

SELECT 
    raceId,
    circuitId,
    year,
    round,
    name AS raceName,
    raceDate,
    raceTime
FROM {{ ref('silver_races') }}