{{
  config(
    materialized = 'table',
    tags = ['gold', 'facts']
    )
}}

SELECT
    ps.raceId,
    ps.driverId,
    
    ra.circuitId, 
    res.constructorId,

    ps.stop,
    ps.lap,
    ps.time AS pitStopTime,
    ps.milliseconds AS pitStopMS
FROM {{ ref('silver_pit_stops') }} ps 
LEFT JOIN {{ ref('silver_races') }} ra
    ON ps.raceId = ra.raceId
LEFT JOIN {{ ref('silver_results') }} res
    ON ps.raceId = res.raceId
    AND ps.driverId = res.driverId