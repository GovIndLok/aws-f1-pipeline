{{
  config(
    materialized = 'table',
    tags = ['silver']
    )
}}

WITH base_table AS (
    SELECT
        res.driverId,
        res.number AS driverNumber,
        rac.date AS raceDate,
        rac.year AS raceYear,
        rac.round AS raceRound
    FROM {{ ref('bronze_results') }} res
    JOIN {{ ref('bronze_races') }} rac
    ON res.raceId = rac.raceId
    WHERE res.number IS NOT NULL
),

change_detect AS (
    SELECT
        *,
        LAG(driverNumber) OVER (
            PARTITION BY driverId
            ORDER BY raceDate
        ) AS prevNumber
    FROM base_table
),

stint_group AS (
    SELECT
        *,
        SUM(
            CASE
                WHEN prevNumber IS NULL THEN 0
                WHEN driverNumber = prevNumber THEN 0
                ELSE 1
            END
        ) OVER (
            PARTITION BY driverId
            ORDER BY raceDate
        ) AS stintId
    FROM change_detect
),

bounds AS (
    SELECT
        driverId,
        driverNumber,
        stintId,
        raceDate,
        raceYear,
        raceRound,
        ROW_NUMBER() OVER (
            PARTITION BY driverId, stintId
            ORDER BY raceYear, raceRound ASC
        ) AS RacNum_first,
        ROW_NUMBER() OVER (
            PARTITION BY driverId, stintId
            ORDER BY raceYear DESC, raceRound DESC
        ) AS RacNum_last
    FROM stint_group
)

SELECT 
    driverId,
    driverNumber,
    MIN(raceDate) AS startDate,
    MAX(raceDate) AS endDate,
    MIN(raceYear) AS startYear,
    MIN(CASE WHEN RacNum_first = 1 THEN raceRound END) AS startRound,
    MAX(raceYear) AS endYear,
    MAX(CASE WHEN RacNum_last = 1 THEN raceRound END) AS endRound,
    COUNT(*) AS raceCount
FROM bounds
GROUP BY driverId, driverNumber, stintId
ORDER BY driverId, startDate