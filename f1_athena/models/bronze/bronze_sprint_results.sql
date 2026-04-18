{{
  config(
    materialized = 'table',
    tags = ['bronze']
    )
}}

SELECT *
FROM {{ source('source', 'sprint_results') }}