{{
  config(
    materialized = 'table',
    tags = ['silver']
    )
}}

WITH source_cleaned AS (
    SELECT 
        constructorId,
        lower(COALESCE(NULLIF(TRIM(constructorRef), ''), 'unknown'))  AS constructorRef,
        COALESCE(NULLIF(TRIM(name), ''), 'unknown')  AS constructorName,
        COALESCE(NULLIF(TRIM(nationality), ''), 'unknown')  AS nationality,
        NULLIF(TRIM(url), '')  AS wikipediaUrl
    FROM {{ ref('bronze_constructors') }}
    WHERE constructorId IS NOT NULL 
),

with_lineage AS (
    SELECT
        c.constructorId,
        c.constructorRef,
        c.constructorName,
        c.nationality,
        c.wikipediaUrl,

        -- Lineage enrichment from seed_constructor_lineage
        -- Falls back to a generated value for constructors not in the seed
        COALESCE(lin.team_lineage_id,    c.constructorRef || '_lineage')       AS team_lineage_id,
        COALESCE(lin.root_team_name,     c.constructorName)                    AS root_team_name,
        COALESCE(lin.lineage_sequence,   1)                                     AS lineage_sequence,
        lin.rebrand_year_start,
        lin.rebrand_year_end,
        lin.predecessor_lineage_id,
        lin.succession_type,
        lin.rebrand_notes,

        -- Computed lineage flags
        CASE WHEN lin.constructor_ref IS NOT NULL    THEN TRUE ELSE FALSE END   AS is_part_of_lineage,
        CASE WHEN lin.lineage_sequence > 1           THEN TRUE ELSE FALSE END   AS is_rebrand,
        CASE WHEN lin.predecessor_lineage_id IS NOT NULL THEN TRUE ELSE FALSE END AS is_successor_team,
        CASE WHEN lin.rebrand_year_end IS NULL       THEN TRUE ELSE FALSE END   AS is_current_name

        FROM source_cleaned c 
        LEFT JOIN {{ ref('seed_constructor_lineage') }} lin
            ON c.constructorRef = lin.constructor_ref
)

SELECT * FROM with_lineage