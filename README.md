# Entrepôt de données — VenteRapide

## Contexte

Entrepôt de données e-commerce fourni dans le cadre de l'épreuve **E6**
de la certification RNCP 37638 Data Engineer.

La société fictive **VenteRapide** exploite une boutique en ligne généraliste.
Cet entrepôt centralise les données de commandes, produits, clients, visites et retours.

## Stack technique

| Composant       | Technologie                |
| --------------- | -------------------------- |
| Base de données | PostgreSQL 16              |
| Transformation  | dbt 1.11                   |
| Modélisation    | Schéma en étoile (Kimball) |
| Environnement   | Linux / WSL2               |

## Prérequis

- PostgreSQL installé et démarré
  `psql --version`
  `pg_isready`
- dbt installé : `pip install dbt-postgres`

## Installation

### 1. Récupérer le projet

cloner le dépôt

```bash
git clone https://github.com/aReynier/maintenance_warehouse_vente_rapide.git
```

Créer le fichier d'environnement à partir du modèle et configurer vos identifiants locaux :

```bash
cp .env.example .env
```

### 2. Créer la base de données PostgreSQL

Charger les variables du .env

```bash
export $(cat .env | grep -v '^#' | xargs)
```

Créer la base, l'utilisateur et appliquer les privilèges :

```bash
sudo -u postgres psql -c "CREATE DATABASE ${POSTGRES_DB};"
sudo -u postgres psql -c "CREATE USER ${POSTGRES_ADMIN} WITH PASSWORD '${POSTGRES_PASSWORD}';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} TO ${POSTGRES_ADMIN};"
sudo -u postgres psql -d ${POSTGRES_DB} -c "GRANT ALL ON SCHEMA public TO ${POSTGRES_ADMIN};"
sudo -u postgres psql -d ${POSTGRES_DB} -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${POSTGRES_ADMIN};"
```

Possibilité de lancer Postgres avec l'admin de la façon suivante:

```bash
psql -h ${POSTGRES_HOST} -p ${POSTGRES_PORT} -U ${POSTGRES_ADMIN} -d ${POSTGRES_DB}
```

### 3. Configurer le profil dbt

Éditez le fichier `~/.dbt/profiles.yml` et ajoutez :

```yaml
datawarehouse_e6:
  target: dev
  outputs:
    dev:
      type: postgres
      host: localhost
      port: ${POSTGRES_PORT}
      user: ${POSTGRES_ADMIN}
      password: ${POSTGRES_PASSWORD}
      dbname: ${POSTGRES_DB}
      schema: public
      threads: 4
```

### 4. Vérifier la connexion

```bash
dbt debug
```

### 5. Lancer l'entrepôt

```bash
dbt seed        # charge les 5 tables brutes
dbt run         # construit les 12 modèles
dbt snapshot    # initialise le SCD type 2
dbt test        # lance les 66 tests
```

## Structure du projet

seeds/  
raw_clients.csv  
raw_produits.csv  
raw_commandes.csv  
raw_lignes_commande.csv  
raw_visites.csv  
models/
staging/ ← nettoyage et typage des données brutes  
dimensions/ ← dim_client, dim_produit, dim_date, dim_canal, dim_statut_commande  
facts/ ← fact_commandes, fact_visites  
snapshots/  
scd_client.sql ← SCD type 2 sur dim_client (ville, code_postal, segment)

## Utilisateurs PostgreSQL

| Utilisateur | Droits                   | Usage                |
| ----------- | ------------------------ | -------------------- |
| postgres    | Superadmin système       | Urgence uniquement   |
| dbt_admin   | admin + Lecture/écriture | Admin + Pipeline dbt |

## Documentation interactive

```bash
dbt docs generate
dbt docs serve --port 8080
```

Ouvrez ensuite http://localhost:8080 pour accéder au lineage graph (icône en bas à droite sur l'interface web dbt).

## Restauration depuis un backup

```bash
pg_restore -d datawarehouse_e6 fichier.dump
```
