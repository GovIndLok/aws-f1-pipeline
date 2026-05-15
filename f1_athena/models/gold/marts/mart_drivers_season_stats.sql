{{
  config(
    materialized = 'table',
    tags = ['gold', 'marts']
    )
}}

WITH race_stats AS (
    SELECT
        result.driverId,
        rec.year,
        COUNT(result.raceId) AS totalRaces,
        SUM(result.points) AS totalPoints,
        AVG(result.startPosition) AS avgStartPosition,
        AVG(result.finishOrder) AS avgFinishOrder,
        AVG(result.points) AS avgPoints,
        SUM(CASE WHEN result.finishOrder = 1 THEN 1 ELSE 0 END) AS totalWins,
        SUM(CASE WHEN result.finishOrder <= 3 THEN 1 ELSE 0 END) AS totalPodium,
        SUM(CASE WHEN result.points > 0 THEN 1 ELSE 0 END) AS totalPointsFinish,
        SUM(CASE WHEN result.startPosition = 1 THEN 1 ELSE 0 END) AS totalP1Starts,
        SUM(CASE WHEN result.finishStatus = 'Finished' THEN 1 ELSE 0 END)*1.0 / COUNT(*) AS finishRate
    FROM {{ ref('fct_results') }} result
    LEFT JOIN {{ ref('dim_races') }} rec
        ON result.raceId = rec.raceId
    GROUP BY result.driverId, rec.year
),

qualifying_stats AS (
    SELECT
        qual.driverId,
        rac.year,
        AVG(qual.qualifyingPosition) AS avgQualifyingPosition,
        SUM(CASE WHEN qual.q3Sec IS NOT NULL THEN 1 ELSE 0 END) AS totalQ3Apperance
    FROM {{ ref('fct_qualifyings') }} qual
    LEFT JOIN {{ ref('dim_races') }} rac
        ON qual.raceId = rac.raceId
    GROUP BY qual.driverId, rac.year
)

SELECT
    d.driverId,
    d.driverRef,
    d.forename,
    d.surname,
    d.nationality,
    d.currentNumber,
    rs.year,
    rs.totalRaces,
    rs.totalPoints,
    rs.avgStartPosition,
    rs.avgFinishOrder,
    rs.avgPoints,
    rs.totalPodium,
    rs.totalP1Starts,
    rs.finishRate,
    qs.avgQualifyingPosition,
    qs.totalQ3Apperance
FROM {{ ref('dim_drivers') }} d 
LEFT JOIN race_stats rs 
    ON d.driverId = rs.driverId
LEFT JOIN qualifying_stats qs
    ON d.driverId = qs.driverId AND rs.year = qs.year