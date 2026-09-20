# Conformité RGPD

## Stratégie de gestion des accès

### Principes directeurs

La gestion des accès au Data Warehouse repose sur deux principes essentiels du RGPD:

- Principe du Moindre Privilège : Chaque utilisateur ou composant système ne dispose que des droits strictement nécessaires à l'accomplissement de ses missions.

- Confidentialité et Sécurité par Défaut : Les données à caractère personnel brutes sont isolées à la source et inaccessibles aux couches d'analyse métier.

| Rôle / Utilisateur        | Portée des Droits        | Périmètre / Schémas                                        | Usage & Justification                                                                                                                               |
| ------------------------- | ------------------------ | ---------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------ |
| postgres Superutilisateur | Global (Système)         | Réservé opérations d'urgence et paramétrages globaux SGBD. |
| dbt_admin                 | Lecture / Écriture / DDL | raw, staging, marts                                        | Dédié Data Engineers et pipelines dbt pour construction et administration de l'entrepôt.                                                            |
| reporting_user            | Lecture seule (SELECT)   | marts / analytics uniquement                               | Dédié aux équipes BI et Data Analysts pour la consommation des dashboards et analyses ad-hoc.                                                       | Accès aux tables raw interdit. |
| grafana_reader            | Lecture seule restreinte | Tables système & dbt_run_results                           | Utilisé par Grafana via le réseau interne Docker (172.17.0.1) pour le suivi des métriques d'exploitation (SLA/SLO). Aucun accès aux données métier. |

### Protection des flux des données en transit

- **Stockage & Reseau :** L'entrepôt est hébergé en environnement souverain/local sans transfert de PII hors de l'Union Européenne.
- **Chiffrement :** Les connexions à la base de données privilégient les flux sécurisés (TLS/SSL).
- **Isolation par Schéma :** Le schéma `raw` (contenant les identifiants en clair) est strictement inaccessible au rôle `reporting_user` que ce soit en modification ou consultation.

### Protection des données personnelles

Dans le respect du RGPD, les équipes de reporting et d'analyse n'ont aucun accès aux données personnelles en clair.

    Isolation des données brutes : Le schéma raw (contenant les identifiants en clair) est strictement inaccessible au rôle reporting_user.

    Anonymisation / Pseudonymisation : Les transformations dbt appliquent un masquage ou un hachage des PII avant d'exposer les données nettoyées dans la couche de restitution (marts).

### Auditabilité et Traçabilité

Afin de garantir la traçabilité des traitements et de répondre aux exigences de contrôle (ex: audit CNIL ou gestion des incidents de sécurité), l'ensemble des connexions et des requêtes exécutées sur PostgreSQL est consigné dans les logs du SGBD. Ces données de journalisation permettent de vérifier régulièrement la conformité des accès et de corriger d'éventuelles déviances.

Les demandes de droit d'accès, modificationn d'opposition ou de suppression transmises au DPO sont traitées au niveau des systèmes sources avant répercussion dans la couche `raw` et ré-exécution des pipelines dbt.
