{{
  config(
    materialized = 'table',
    tags = ['gold','facts']
    )
}}

SELECT
    lt.raceId,
    lt.driverId,
    ra.circuitId,
    res.constructorId,
    lt.lap,
    lt.position,
    lt.timeDisplay AS lapTime,
    lt.milliseconds AS lapMS
FROM {{ ref('silver_lap_times') }} lt 
LEFT JOIN {{ ref('silver_races') }} ra 
    ON lt.raceId = ra.raceId
LEFT JOIN {{ ref('silver_results') }} res
    ON lt.raceId = res.raceId
    AND lt.driverId = res.driverId