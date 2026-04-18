{{
  config(
    materialized = 'table',
    tags = ['bronze']
    )
}}

SELECT *
FROM {{ source('source', 'lap_times') }}