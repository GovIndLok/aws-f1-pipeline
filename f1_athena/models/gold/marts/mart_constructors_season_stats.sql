{{
  config(
    materialized = 'table',
    tags = ['gold', 'marts']
    )
}}

WITH race_results AS (
    SELECT
        result.constructorId,
        result.raceId,
        rac.year,
        COUNT(DISTINCT result.raceId) AS totalRaces,
        SUM(result.points) AS totalPoints,
        SUM(CASE WHEN result.finishOrder = 1 THEN 1 ELSE 0 END) AS totalWins,
        SUM(CASE WHEN result.finishOrder <= 3 THEN 1 ELSE 0 END) AS totalPodiums,
        SUM(CASE WHEN result.finishStatus = 'Finished' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS finishRate,
        MIN(result.finishOrder) AS bestFinish
    FROM {{ ref('fct_results') }} result
    LEFT JOIN {{ ref('dim_races') }} rac
        ON result.raceId = rac.raceId
    GROUP BY result.constructorId, result.raceId, rac.year
)

SELECT
    const.constructorId,
    const.constructorName,
    const.teamLineageId,
    const.constructorNationality,
    stat.year,
    stat.totalRaces,
    stat.totalPoints,
    stat.totalWins,
    stat.totalPodiums,
    stat.finishRate,
    stat.bestFinish
FROM {{ ref('dim_constructors') }} const
LEFT JOIN race_results stat
    ON const.constructorId = stat.constructorId