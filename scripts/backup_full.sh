#!/usr/bin/env bash


# Strict mode: quitte immédiatement en cas de fail
set -euo pipefail


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
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.dump"


mkdir -p "${BACKUP_DIR}"
chmod 700 "${BACKUP_DIR}"

echo "${LOG_PREFIX} Starting full database backup of ${DB_NAME} to ${BACKUP_FILE}"


# Dump dans un format custom et compressé (-Fc)
pg_dump \
  -h "${DB_HOST}" \
  -p "${DB_PORT}" \
  -U "${DB_USER}" \
  -Fc \
  -f "${BACKUP_FILE}" \
  "${DB_NAME}" || fail "pg_dump exited with error"


# Vérifie que le doccier de backup n'est pas vide
[ -s "${BACKUP_FILE}" ] || fail "Backup file is empty or missing"


# Vérification rapide de l'integrité: liste le contenu des tables avant de restaurer
pg_restore --list "${BACKUP_FILE}" > /dev/null 2>&1 \
  || fail "pg_restore integrity check failed"

echo "${LOG_PREFIX} Backup verified: ${BACKUP_FILE} ($(du -sh "${BACKUP_FILE}" | cut -f1))"


# Suppression des bakup plus anciens que la période de rétention
find "${BACKUP_DIR}" -name "${DB_NAME}_*.dump" \
  -mtime +"${RETENTION_DAYS}" -delete
echo "${LOG_PREFIX} Pruned backups older than ${RETENTION_DAYS} days"

echo "${LOG_PREFIX} Done."


