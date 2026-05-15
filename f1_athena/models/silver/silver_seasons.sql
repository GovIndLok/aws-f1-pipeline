{{
  config(
    materialized = 'table',
    tags = ['silver']
    )
}}

SELECT
    year,
    url
FROM {{ ref('bronze_seasons') }}