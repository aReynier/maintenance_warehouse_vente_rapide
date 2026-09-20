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

## Registre de traitement des données personnelles

- Responsable du traitement: équipe data
- Délégué à la protection des données (DPO): dpo@entreprise.fr

Ce registre est découpé par type de traitement
| ID | Nom du Traitement | Finalité | Données personnelles Concernées | Base Légale | Durée de Conservation | Destinataires / Accès |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TRT-01** | **Ingestion & Staging Data Warehouse** | Centralisation des données opérationnelles brutes pour la préparation des flux analytiques. | Nom, Prénom, Nom complet, Email, Date de naissance, âge, Adresse(ville, code postal, pays), segment, date d'inscription, status actif | **Exécution du contrat** | Durée de la relation contractuelle + 3 ans | `dbt_admin`, Data Engineers (Schémas `raw` & `staging`) |
| **TRT-02** | **Analyse des Ventes & Comportement Client** | Pilotage de la performance commerciale, suivi du CA et segmentation client. | Identifiant client haché, Historique d'achats | **Intérêt légitime** (Art. 6.1.f) | 5 ans (prescription commerciale) | `reporting_user`, Équipe BI & Analysts (Schéma `marts`) |
| **TRT-03** | **Gestion & Analyse des Retours Produits** | Suivi du taux de retour (`raw_retours.csv`), identification des défauts et amélioration de la qualité service. | N° de commande, Motifs de retour, Identifiant client pseudonymisé | **Exécution du contrat** | 3 ans à compter de la clôture de la réclamation | `reporting_user`, Responsables Qualité / SAV (Schéma `marts`) |
| **TRT-04** | **Supervision de l'Infrastructure Data** | Monitoring de la qualité de service (SLA/SLO), suivi des exécutions dbt et disponibilité de la base. | Métriques techniques, journaux de logs, aucune PII métier | **Intérêt légitime** | 1 an (logs système) | `grafana_reader`, Équipe DevOps / Infra |

## Procédure de tri/purge des données personnelles

Conformément au RGPD (Principe de limitation de la conservation), les données à caractère personnel ne doivent pas être conservées sous une forme permettant l'identification des personnes concernées au-delà de la durée nécessaire aux finalités pour lesquelles elles sont traitées.

Cette procédure définit les règles d'identification, d'anonymisation et de purge des comptes clients inactifs au sein du Data Warehouse PostgreSQL.

### Critères d'Inactivité et Règles de Rétention

Un compte client est considéré comme **inactif** s'il remplit les conditions cumulatives suivantes :

- **Statut de l'utilisateur :** `actif = f` (ou absence d'activité/achat enregistrée).
- **Ancienneté / Inactivité :** La date de la dernière activité (ou à défaut la `date_inscription`) est supérieure ou égale à **36 mois (3 ans)**.

#### Modalités de Traitement selon la Couche de Données :

| Couche Data Warehouse   | Type de Traitement                 | Action Effectuée                                                                                                                                       | Fréquence & Mode d'Exécution                                 |
| :---------------------- | :--------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------- | :----------------------------------------------------------- |
| **`raw` / `staging`**   | **Purge / Suppression définitive** | Suppression des lignes clients inactifs (`DELETE`) dans les tables brutes de transit.                                                                  | Mensuelle / Automatisée (Script SQL / Job CRON)              |
| **`marts` (Analytics)** | **Anonymisation Irréversible**     | Hachage permanent de l'email, suppression des données personnelles secondaires (adresse, ville, CP), conservation uniquement des métriques néessaires. | Exécution du pipeline dbt (`dbt run`) après purge du staging |

### Automatisation et Contrôle

Mode d'exécution : Automatisé via une tâche planifiée (Job CRON ou DAG Orchestrateur) exécutée le 1er de chaque mois à 02h00 UTC.

Supervision & Alerting :

- Chaque exécution de la procédure insère une trace dans les logs (date d'exécution, nombre de comptes purges, statut).
- En cas d'échec de la procédure, une alerte est transmise à l'équipe Data Engineer (email ou tableau de bord Grafana, à mettre en place).

Révisions et Audit :

- La présente procédure fait l'objet d'un réexamen annuel par le Data Controller / DPO pour s'assurer de son adéquation avec l'évolution des réglementations.
