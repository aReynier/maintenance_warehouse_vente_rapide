# Indicateurs de Service (SLA/SLO) et Tableau de Bord de Supervision

Ce document définit les objectifs de niveau de service (SLO) appliqués à l'entrepôt de données ainsi que la structure du tableau de bord de maintenance pour en assurer la supervision.

## 1. Engagement et Indicateurs de Niveau de Service (SLA / SLO)

Dans le cadre d'une architecture analytique (Data Warehouse), les exigences de disponibilité sont adaptées aux usages décisionnels (différents des systèmes transactionnels temps réel).

### Synthèse des objectifs (SLO)

| Indicateur                                   | Définition                                                 | Objectif (SLO)                     | Mesure & Fréquence                     |
| :------------------------------------------- | :--------------------------------------------------------- | :--------------------------------- | :------------------------------------- |
| **Disponibilité de la base de données(SLA)** | Accessibilité de PostgreSQL pour les requêtes analytiques. | **98 %** _(heures ouvrées)_        | Uptime du service `postgresql.service` |
| **Succès des pipelines (SLA)**               | Taux d'exécutions dbt sans erreur sur un mois.             | **95 %**                           | Rapport d'exécution `run_results.json` |
| **Fraîcheur des données**                    | Écart maximal toléré pour la mise à jour des modèles.      | **1 fois par 24h** _(avant 05h30)_ | Timestamp de génération dans dbt       |
| **Temps d'exécution**                        | Durée totale de la séquence (`seed` + `run` + `test`).     | **< 15 minutes**                   | Durée totale reportée par dbt          |
| **Qualité des données**                      | Ratio de tests de validation dbt réussis.                  | **100 %** _(tests critiques)_      | Execution de `dbt test`                |

**Note de scalabilité :** Le temps d'éxécution de 15 minutes est adapté au volume initial. En cas de montée en charge (volumétrie ou ajout de nouveaux marts), ce seuil pourra être réévalué ou optimisé

### Indicateurs de Résilience et Gestion des Incidents (PRA)

| Indicateur                                            | Définition                                                          | Cible          | Application                                                 |
| :---------------------------------------------------- | :------------------------------------------------------------------ | :------------- | :---------------------------------------------------------- |
| **RPO (PDMA - Perte de Données Maximale Admissible)** | Perte maximale de données tolérée en cas de sinistre majeur.        | **24 heures**  | Garantis par la sauvegarde quotidienne PostgreSQL de 06h00. |
| **RTO (durée maximale d’indisponibilité tolérée)**    | Temps maximum avant la prise en charge d'un ticket/alerte critique. | **6 heures**   | Traitement dans la journée ouvrée par l'équipe Data.        |
| **MTTR (Mean Time To Recovery)**                      | Temps moyen de résolution/réparation du pipeline en panne.          | **< 2 heures** | Correction du code/donnée + réexécution ciblée dbt.         |

_Pour consulter le détail de la stratégie de restauration et des rétentions, se référer à la [Politique de Sauvegarde et Restauration Postgres](./politique_sauvegarde.md)._

---
