{{
  config(
    materialized = 'table',
    tags = ['gold', 'facts']
    )
}}

SELECT 
    q.qualifyId,
    q.raceId,
    q.driverId,

    res.constructorId,
    ra.circuitId,

    q.position AS qualifyingPosition,
    q.q1_sec AS q1Sec,
    q.q2_sec AS q2Sec,
    q.q3_sec AS q3Sec 
FROM {{ ref('silver_qualifyings') }} q 
LEFT JOIN {{ ref('silver_races') }} ra 
    ON q.raceId = ra.raceId
LEFT JOIN {{ ref('silver_results') }} res
    ON q.raceId = res.raceId
    AND  q.driverId = res.driverId