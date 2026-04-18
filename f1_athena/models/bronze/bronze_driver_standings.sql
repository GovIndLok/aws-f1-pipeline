{{
  config(
    materialized = 'table',
    tags = ['bronze']
    )
}}

SELECT *
FROM {{ source('source', 'driver_standings') }}