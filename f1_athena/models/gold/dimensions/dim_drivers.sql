    {{
    config(
        materialized = 'table',
        tags = ['gold', 'dimensions']
        )
    }}

    WITH latest_num AS (
        SELECT
            driverId,
            driverNumber AS currentNumber,
            endYear AS lastRaceSeason
        FROM (
            SELECT
                driverId,
                driverNumber,
                endYear,
                endRound,
                ROW_NUMBER() OVER (
                    PARTITION BY driverId
                    ORDER BY endYear DESC, endRound DESC
                ) AS rn 
            FROM {{ ref('silver_driver_num') }}
        ) ranked
        WHERE rn = 1
    ),

    max_season AS (
        SELECT 
            MAX(year) AS currentSeason
        FROM {{ ref('bronze_races') }}
    )

    SELECT 
        d.driverId,
        d.driverRef,
        d.forename,
        d.surname,
        d.forename || ' ' || d.surname AS fullName,
        d.nationality,
        d.dob,

        lin.currentNumber,
        lin.lastRaceSeason,

        CASE 
            WHEN lin.lastRaceSeason = (SELECT currentSeason FROM max_season)
            THEN TRUE
            ELSE FALSE
        END AS Active   
    FROM {{ ref('silver_drivers') }} d 
    JOIN latest_num lin 
        ON d.driverId = lin.driverId