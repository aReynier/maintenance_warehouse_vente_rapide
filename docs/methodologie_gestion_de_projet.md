# Méthodologie de Gestion de Projet & Exploitation (Build & Run)

Ce document formalise le cadre méthodologique retenu pour le développement (Build) du Data Warehouse de **VenteRapide** ainsi que pour son exploitation continue (Run & Maintenance). Il s'appuie sur une démarche hybride articulée autour du **Ticketing**, d'**ITIL** et de **Kanban**.

---

## 1. Principes de Ticketing

Afin de garantir une traçabilité totale et un suivi rigoureux de la charge de travail, toute action (développement, correction, tâche d'infrastructure ou rédaction de documentation) fait obligatoirement l'objet d'un ticket.

### Structure standard d'un ticket

Chaque ticket créé dans le système de gestion de tâches doit respecter la structure suivante :

- **Titre :** Normalisé sous la forme `Phrase décrivant l'action en commençant par un verbe à l'infinitif` (ex: `Créer le modèle stg_retours`).
- **Description :** Contexte métier/technique et objectif de la tâche.
- **Critères d'acceptation :** Liste à puces (_checklist_) définissant les conditions strictes de validation.
- **Estimation :** Évaluée en points de complexité selon la suite de Fibonacci (`1`, `2`, `3`, `5`, `8`).
- **Priorité :** Niveau d'urgence défini de `P0` à `P2`.
- **Assignation :** Développeur ou membre de l'équipe responsable de l'exécution.
- **Label :** Catégorisation parmi les 5 labels du projet (`Gestion de projet`, `Documentation`, `DBT`, `infra-db`, `RGPD`).

### Échelle de Priorisation

- **P0 (Bloquant / MVP) :** Incidents majeurs en production, ruptures de pipeline dbt ou fonctionnalités clés les plus urgentes.
- **P1 (Important) :** Nouveaux Data Marts, évolutions de schémas (SCD), optimisations de performances et documentation technique d'architecture.
- **P2 (Amélioration / Secondaire) :** Tâches d'ergonomie, automatisation secondaire, procédures d'exploitation d'urgence et nettoyages cosmétiques.

---

## 2. Framework ITIL (Gestion des Services & Maintenance)

L'exploitation du Data Warehouse s'inspire des bonnes pratiques ITIL pour structurer le support, assurer la continuité de service et gérer les évolutions post-mise en production.

---

## 3. Démarche Kanban & Cycle de Vie des Tâches

Le suivi visuel du travail s'effectue sur un tableau **Kanban unique**, assurant la transition continue entre les livrables initiaux du projet (Build) et les demandes d'exploitation (Run). Ce Kanban a été créé sous la forme d'un **Github Project** pour tirer profit de focntionnalités github telles que la création d'issues et de branches directement à partir des tickets.

### Structure des colonnes du Kanban

0. **Backlog (To Do) :** Réservoir centralisant l'ensemble des tickets P0, P1 et P2 identifiés.
1. **Prêt :** Tâches prêtes à l'emploi.
2. **In Progress :** Tâches en cours de réalisation (limitation stricte du Work In Progress / WIP à 3 tickets max par personne).
3. **Review / Test :** Étape de contrôle qualité (exécution des tests `dbt test`, validation des critères d'acceptation, relecture du code, 5 tickets au maximum).
4. **Done :** Tâches validées, documentées et fusionnées sur la branche principale.

### Modèle de Labels Officiels

Pour catégoriser efficacement la charge de travail, les tickets utilisent exclusivement les 5 labels suivants :

- `DBT` : Modèles de transformation (staging, marts, seeds, snapshots SCD, tests).
- `infra-db` : Base de données PostgreSQL, rôles/droits SQL, stockage, logs techniques.
- `Documentation` : Documentation MLD/MPD, lineage graph, procédures d'exploitation.
- `RGPD` : Registre des traitements, anonymisation PII, scripts de purge.
- `Gestion de projet` : Méthodologie, suivi Kanban, priorisation et cadrage.
