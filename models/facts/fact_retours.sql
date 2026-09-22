{{ config(materialized="table") }}

with retours as (
    select * from {{ ref('stg_retours') }}
),

produits as (
    select * from {{ ref('dim_produit') }}
),

clients as (
    select * from {{ ref('dim_client') }}
)

select
    r.retour_id,
    r.commande_id,
    r.produit_id,
    r.client_id,
    to_char(r.date_retour, 'YYYYMMDD')::integer as date_retour_id,
    r.motif,
    r.montant_rembourse
from retours r
left join dim_produit dp    on r.produit_id = dp.produit_id
left join dim_client dci    on r.client_id = dci.client_id