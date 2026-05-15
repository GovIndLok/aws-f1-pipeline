{{
  config(
    materialized = 'table',
    tags = ['gold', 'dimensions']
    )
}}

SELECT 
    constructorId,
    constructorRef,
    constructorName,
    nationality AS constructorNationality,
    wikipediaUrl AS constructorUrl,
    root_team_name AS rootTeamName,
    team_lineage_id AS teamLineageId,
    is_rebrand AS rebrand,
    is_successor_team AS successorTeam,
    is_current_name AS currentName 
FROM {{ ref('silver_constructors') }}