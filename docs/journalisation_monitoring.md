# Politique de Journalisation et Monitoring (PostgreSQL & dbt)

Ce document décrit la stratégie de journalisation des événements, de détection des anomalies de performance et d'audit de sécurité pour l'entrepôt de données.

---

## 1. Journalisation PostgreSQL

La configuration des logs PostgreSQL est gérée de manière déclarative via le script SQL `scripts/setup_postgres_logging.sql` à l'aide de commandes `ALTER SYSTEM SET`.

### Emplacement des fichiers de logs

Les fichiers sont stockés dans le répertoire `log/` du dossier de données PostgreSQL (exemple: `/var/lib/postgresql/16/main`). Chaque fichier est nommé avec un horodatage unique sous la forme `postgresql-YYYY-MM-DD_HHMMSS.log`.

---

### Référentiel des paramètres configurés

| Paramètre                                    | Valeur configurée                  | Rôle et justification technique                                                                                                                                      |
| :------------------------------------------- | :--------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`logging_collector`**                      | `'on'`                             | **Activation du logger.** Active le processus d'arrière-plan qui redirige les erreurs vers les fichiers de logs système.                                             |
| **`log_directory`**                          | `'log'`                            | **Répertoire cible.** Définit le dossier où sont écrits les fichiers de journaux.                                                                                    |
| **`log_filename`**                           | `'postgresql-%Y-%m-%d_%H%M%S.log'` | **Modèle de nommage.** Garantit qu'un nouveau fichier horodaté est créé à chaque rotation.                                                                           |
| **`log_line_prefix`**                        | `'... (tx:%x)'`                    | **Enrichissement du préfixe.** Format : `Horodatage [PID] utilisateur@base/application (tx:ID_transaction)`. Indispensable pour l'audit et la corrélation d'erreurs. |
| **`log_statement`**                          | `'ddl'`                            | **Traçabilité DDL.** Enregistre toutes les modifications de structure (`CREATE`, `ALTER`, `DROP`). Permet de suivre l'évolution des tables générées par `dbt`.       |
| **`log_min_duration_statement`**             | `'250'` (ms)                       | **Détection des requêtes lentes.** Toute instruction dont l'exécution dépasse 250 ms est enregistrée avec son temps exact pour optimisation des index.               |
| **`log_min_messages`**                       | `'warning'`                        | **Filtrage de la sévérité.** Évite la saturation du disque en n'enregistrant que les événements de niveau `WARNING`, `ERROR`, `FATAL` et `PANIC`.                    |
| **`log_min_error_statement`**                | `'error'`                          | **Capture du SQL en erreur.** Enregistre la requête SQL qui a échoué.                                                                                                |
| **`log_lock_waits`**                         | `'on'`                             | **Détection des blocages.** Enregistre une alerte si une requête attend un verrou pendant plus d'une seconde.                                                        |
| **`log_temp_files`**                         | `'0'`                              | **Observabilité mémoire.** Enregistre la création de fichiers temporaires sur disque lorsqu'une requête dépasse le `work_mem` alloué.                                |
| **`log_connections` / `log_disconnections`** | `'on'`                             | **Audit d'accès & RGPD.** Consigne chaque ouverture et fermeture de session utilisateur pour la traçabilité des accès.                                               |
| **`log_rotation_age` / `log_rotation_size`** | `'1d'` / `'10MB'`                  | **Gestion de l'espace disque.** Force la création d'un nouveau fichier toutes les 24 heures ou dès que la taille atteint 10 Mo.                                      |

---

## Procédure d'application et de rechargement

Exécuter le script de configuration :

```bash
psql -U ${POSTGRES_SUPERUSER} -d ${POSTGRES_DB} -f scripts/setup_postgres_logging.sql
```

Redémarrer postgres:

```bash
sudo systemctl restart postgresql
```

Pour tester si les logs correspondent bien à l'attendu:

```bash
psql -h ${POSTGRES_HOST} -p ${POSTGRES_PORT} -U ${POSTGRES_SUPERUSER} -d ${POSTGRES_DB} -c "
SELECT name, setting, unit, context
FROM pg_settings
WHERE name IN (
    'logging_collector',
    'log_directory',
    'log_filename',
    'log_min_duration_statement',
    'log_statement',
    'log_temp_files',
    'log_lock_waits'
);"
```

## 2. Journalisation dbt

dbt assure la traçabilité et l'observabilité des logs.

### Configuration globale des logs

La politique de journalisation dbt est fixée au niveau de la racine du projet via la section `flags` du fichier `dbt_project.yml`:

- **log_format: default** : Format texte basique
- **log_level: info** : Sévérité minimale capturée dès le niveau info

### Fichiers de logs et artefacts

Chaque exécution dbt génère deux fichiers :

- `logs/dbt.log` : Fichier journal textuel retraçant l'ensemble des commandes exécutées, l'horodatage au millième de seconde, le PID de session, les requêtes SQL compilées soumises à PostgreSQL, ainsi que les traces d'erreurs complètes (stack traces) en cas d'échec.
- `target/run_results.json` : Artefact structuré (JSON) généré automatiquement à la fin de chaque commande (dbt run, dbt test, dbt build). Il contient l'état d'exécution de chaque modèle (success, error, skipped), le temps de traitement exact en secondes ainsi que le nombre de lignes modifiées.

### Recommandations pour les développeurs et l'exploitation

Bien que le projet définisse un comportement par défaut, il est recommandé d'adapter l'exécution selon le contexte d'utilisation :

- En cas d'erreur complexe, élever temporairement le niveau de log à debug pour capturer l'intégralité du contexte :

```bash
dbt --log-level debug run --select nom_du_modele
```

- Dans le cadre d'une utilisation future en CI/CD, forcer la sortie JSON structurée :

```bash
dbt --log-format json run
```

Astuces

- Inspection rapide des 20 dernières lignes erreurs dans le journal dbt

```bash
grep -i "error" logs/dbt.log | tail -n 20
```

**Note**: dans un cas futur de mise en production, prévoir l'arrêt immédiat de la pipeline à la moindre erreur
