#!/usr/bin/env bash


# Strict mode: quitte immédiatement en cas de fail
set -euo pipefail


# Vérification des arguments reçus
OBJECT_TYPE="${1:-}"
OBJECT_NAME="${2:-}"

if [[ -z "$OBJECT_TYPE" || -z "$OBJECT_NAME" ]]; then
    echo "Usage: $0 <schema|-n|table|-t> <nom_du_composant>"
    echo "Exemples :"
    echo "  $0 schema gold"
    echo "  $0 -t public.orders"
    exit 1
fi

# Horodatage et préfixe
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_PREFIX="[pg-backup ${TIMESTAMP}]"


# Fonction d'erreur personnalisée
fail() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] ${LOG_PREFIX} ERROR: $1" >&2
  curl -fsS --retry 3 "${PING_URL}/fail" -o /dev/null || true
  exit 1
}

# Chargement sécurisé du fichier .env s'il existe
if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
else
    fail "File .env not found"
fi

# Configuration
DB_HOST="${POSTGRES_HOST}"
DB_PORT="${POSTGRES_PORT}"
DB_NAME="${POSTGRES_DB}"
DB_USER="${POSTGRES_ADMIN}"
BACKUP_DIR="/var/backups/postgres"
RETENTION_DAYS=14


# Nettoyage du paramètre type pour le nom de fichier (retirer le tiret si -n ou -t)
CLEAN_TYPE="${OBJECT_TYPE#-}"
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${CLEAN_TYPE}_${OBJECT_NAME}_${TIMESTAMP}.dump"

mkdir -p "${BACKUP_DIR}"
chmod 700 "${BACKUP_DIR}"

echo "${LOG_PREFIX} Starting partial database backup of ${DB_NAME} to ${BACKUP_FILE}"


# Dump dans un format custom et compressé (-Fc)
# contrôle du type
case "$OBJECT_TYPE" in
    -n|schema)
        echo "Lancement du backup du schéma : $OBJECT_NAME"
        pg_dump -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_ADMIN" \
                -Fc -n "$OBJECT_NAME" -f "$BACKUP_FILE" "$POSTGRES_DB"
        ;;
    -t|table)
        echo "Lancement du backup de la table : $OBJECT_NAME"
        pg_dump -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_ADMIN" \
                -Fc -t "$OBJECT_NAME" -f "$BACKUP_FILE" "$POSTGRES_DB"
        ;;
    *)
        echo "Type invalide : '$OBJECT_TYPE'. Utilisez '-n' ou '-t'."
        exit 1
        ;;
esac

echo "Sauvegarde partielle réussie : $BACKUP_FILE"

# Vérifie que le doccier de backup n'est pas vide
[ -s "${BACKUP_FILE}" ] || fail "Backup file is empty or missing"


# Vérification rapide de l'intégrité : lecture de la table des matières du dump
pg_restore --list "${BACKUP_FILE}" > /dev/null 2>&1 || fail "pg_restore integrity check failed"

echo "${LOG_PREFIX} Backup verified: ${BACKUP_FILE} ($(du -sh "${BACKUP_FILE}" | cut -f1))"

echo "${LOG_PREFIX} Done."


