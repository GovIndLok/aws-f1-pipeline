{{
  config(
    materialized = 'table',
    tags = ['gold', 'facts']
    )
}}

SELECT
    r.resultId,
    r.raceId,
    r.driverId,
    r.constructorId,

    ra.circuitId,

    r.grid AS startPosition,
    r.finishPosition,
    r.resultCode AS finishTextCode,
    r.finshOrder AS finishOrder,
    r.points,
    r.laps AS lapCompleted,
    r.timeMilliseconds / 1000.0 AS CompletionTimeSec,
    r.fastestLap ,
    r.fastestLapRank,
    r.fastestLapTimeMilliseconds / 1000.0 AS fastestLapTimeSec,
    r.fastestLapSpeed,
    st.statusId AS finishStatusId,
    st.status AS finishStatus
FROM {{ ref('silver_results') }} r 
LEFT JOIN {{ ref('silver_races') }} ra
    ON r.raceId = ra.raceId
LEFT JOIN {{ ref('status') }} st
    ON r.statusId = st.statusId