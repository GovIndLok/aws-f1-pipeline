{{
  config(
    materialized = 'table',
    tags = ['bronze']
    )
}}

SELECT *
FROM {{ source('source', 'pit_stops') }}