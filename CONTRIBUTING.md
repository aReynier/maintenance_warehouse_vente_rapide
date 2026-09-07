# Guide de Contribution (Git Workflow)

Ce document décrit les conventions techniques à respecter pour contribuer au code du Data Warehouse de VenteRapide.

## 1. Conventions de Commits (Conventional Commits)

Les messages de commit doivent être rédigés en français et respecter la structure suivante :
`<type>(<périmètre>(opt)): <description courte>`

- **Types autorisés :**
  - `feat` : Nouvelle fonctionnalité ou modèle dbt (ex: `feat(dbt): ajouter le modèle fact_retours`)
  - `fix` : Correction d'un bug ou d'une requête SQL (ex: `fix(infra): corriger les droits du rôle reporting`)
  - `docs` : Ajout ou mise à jour de documentation (ex: `docs(dbt): mettre a jour le schema.yml`)
  - `chore` : Tâches de maintenance ou configuration (ex: `chore(ci): configurer GitHub Actions`)
  - `refactor` : Modification du code sans changement de fonctionnalité

## 2. Nommage des Branches

Toute modification doit faire l'objet d'une branche dédiée créée depuis `main` et devra être une branche crée à partir d'un ticket issu du projet github. Conserver le chiffre et réduire le titre de façon à garder un nom de branche explicite tout en veillant à ce qu'elle ne soit pas trop longue:

- exemple : `46-ajouter-guide-contribution-git`

## 3. Règles de Pull Request (PR)

- Un push direct de la fonctionnalité à la `main` est strictement interdit.
- Une fonctionnalité se merge à la `dev`
- La dev se merge à la `main`
- En dehors de la dev, seul les branches issus de tickets de type hotfix sont tolérés
