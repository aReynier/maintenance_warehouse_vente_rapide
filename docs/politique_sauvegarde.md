# Politique de sauvegarde de la base de données Postgres

## Objectifs de continuité (RPO/RTO)

**RPO (PDMA - Perte de Données Maximale Admissible) : 24 heures**

- Garanti par la sauvegarde quotidienne nocturne. Les données sources étant conservées dans les systèmes amont, la perte maximale équivaut aux traitements de la journée.

**RTO (durée maximale d’indisponibilité tolérée) : 6 heures**

- Temps alloué pour restaurer la base, vérifier l'intégrité et remettre le data warehouse à disposition des analystes tout en ayant un impact résuit dur leur travail.

## Back up complet

Le backup complet sert à sauvegarder et restaurer l'intégralité des données et de la structure du Data Warehouse.

### Lancement périodique

Pour paramétrer la tâche cron pour le backup complet, éditer la table cron:

```bash
crontab -e
```

Ajouter la tâche cron suivante tout en bas en adaptant son chemin:

```bash
0 6 * * * votre-chemin-absolu/scripts/backup_full.sh >> /var/log/backup_postgres.log 2>&1
```

_Astuce:_ pour connaitre votre chemin vous pouvez taper la commande suivante:

```bash
pwd
```

Pour vérifier que cette tâche cron est bien présente, si vous êtes sous lnux vous pouvez lancer la commande suivante:

```bash
crontab -l
```

### Lancement manuel

Pour des tests, si besoin de lancement manuel du backup complet, lancer le script backup_full.sh

```
./scripts/backup_full.sh
```

### Règles du backup complet

- Déclenchement : Tous les jours à 06h00 du matin (après la fin des flux d'ingestion et des transformations dbt nocturnes et avant l'arrivée de l'équipe analytique).

- Temps de rétention : 14 jours (purge automatique par le script).

- Format : Le pg_dump enregistre ce backup au format Custom (-Fc) car il est plus optimisé qu'un SQL classique, compressé nativement et permet une restauration parallélisée avec pg_restore.

### Protocole de restauration d'urgence

En cas d'incident majeur ou de corruption de données, suivre cette procédure pour restaurer un backup :

1. Localiser le fichier de sauvegarde le plus récent dans /var/backups/postgres/.

2. Créer une base de données temporaire de test :

```Bash
createdb -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_SUPERUSER warehouse_test_restore
```

3. Exécuter la restauration avec pg_restore avec le bon nom de ficheir de sauvegarde:

```Bash
pg_restore -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_SUPERUSER -d warehouse_test_restore /var/backups/postgres/warehouse_YYYYMMDD_HHMMSS.dump
```

4. Effectuer un contrôle rapide des tables et du nombre de lignes pour valider l'intégrité des données.

5. Une fois la validation effectuée, basculer la connexion des utilisateurs vers la nouvelle base et supprimer l'ancienne base défectueuse.

6. En cas de test, consigner ci-dessous les protocoles de test effectués:

| date du test | fichier de backup utilisé             | protocole réussi | taille | durée  |
| ------------ | ------------------------------------- | ---------------- | ------ | ------ |
| 09/09/2026   | datawarehouse_e6_20260909_141250.dump | ✅               | 33k    | <1min. |

### Guide de résolution d'erreurs

Le script est prévu pour s'arrêter au moindre fail et des logs sont prévus pour les différents cas:
| phrase | correctif possible |
|- |- |
|"File .env not found" | Charger le fichier .env ou le déplacer à la racine du projet à partir du modèle .env.example. |
|"pg_dump exited with error" | Corriger les paramètres de connexion (POSTGRES_HOST, POSTGRES_ADMIN, POSTGRES_SUPERUSER) dans le .env. |
|"Backup file is empty or missing" | Vérifier que le dossier /var/backups/postgres a bien été créé, dispose des bons droits (chmod 700) et que le disque n'est pas saturé. |
|"pg_restore integrity check failed" | Vérifier que la commande pg_dump a bien abouti et que le fichier se trouve bien dans le dossier attendu sous le nom attendu. |
|chmod: changing permissions of '/var/backups/postgres': Operation not permitted|sudo chown -R $USER:$USER /var/backups/postgres|

---

## Back up partiel

Le backup partiel est une opération manuelle à la demande. Il permet de sauvegarder précisemment un schéma ou une table spécifique.

### Lancement manuel

Pour tester, ou au besoin de lancement manuel du backup complet, lancer le script backup_partial.sh

```
./scripts/backup_partial.sh paramètre1 paramètre2
```

Ce script prend deux paramètres:

- paramètre1 -> -t | -n | table | schema
- paramètre2 -> nom-objet

Ce script sert à extraire des données de la base pour les enregistrer dans un fichier sur le disque.

### Procédure de restauration partielle / ciblée

Pour restaurer uniquement le schéma ou la table sauvegardée (avec écrasement/remplacement de l'existant) :

```Bash
pg_restore -h $POSTGRES_HOST -p $POSTGRES_PORT -U${POSTGRES_ADMIN:-postgres} \
           --clean --if-exists \
           -d $POSTGRES_DB \
           /var/backups/postgres/datawarehouse_e6_schema_gold_YYYYMMDD_HHMMSS.dump
```

### Guide de résolution d'erreurs

Tout comme pour le backup complet,le script de backup partiel est prévu pour s'arrêter au moindre fail et des logs sont prévus pour les différents cas:
| phrase | correctif possible |
|- |- |
|"File .env not found" | Charger le fichier .env ou le déplacer à la racine du projet à partir du modèle .env.example. |
|"pg_dump exited with error" | Corriger les paramètres de connexion (POSTGRES_HOST, POSTGRES_ADMIN, POSTGRES_SUPERUSER) dans le .env. |
|"Backup file is empty or missing" | Vérifier que le dossier /var/backups/postgres a bien été créé, dispose des bons droits (chmod 700) et que le disque n'est pas saturé. |
|"pg_restore integrity check failed" | Vérifier que la commande pg_dump a bien abouti et que le fichier se trouve bien dans le dossier attendu sous le nom attendu. |
|chmod: changing permissions of '/var/backups/postgres': Operation not permitted|sudo chown -R $USER:$USER /var/backups/postgres|
|Usage: ./... <schema|-n|table|-t> <nom_du_composant> | Rajouter les paramètres requis|
|Type invalide... | Choisir un nom de type valabe, c'est à dire -t ou -n ou table ou schema |
