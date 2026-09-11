# Dépannage

## .env non pris en compte dans les commande terminal

Si les variables d'environnement ne semblent pas reconnu dans les commandes terminal, lancer cette commande:

```bash
export $(cat .env | grep -v '^#' | xargs)
```

Puis relancer la commande bloquée uen nouvelle fois.

## Connexion Grafana (Docker) -> PostgreSQL (Hôte)

Si Grafana renvoie une erreur de connexion (`connection refused` ou `pg_hba.conf`) :

**Principe de sécurité :** On évite d'ouvrir PostgreSQL à tout le réseau (`listen_addresses = '*'`). On autorise uniquement l'interface virtuelle Docker (`docker0`) et l'IP stricte nécessaire.

### 1. Récupérer l'IP de l'interface Docker (`docker0`)

Exécuter dans le terminal de l'hôte :

```bash
ip addr show docker0 | grep inet
```

_Note:_ l'IP obtenue sera probablement 172.17.0.1 2. Restreindre l'écoute à l'hôte et à Docker (postgresql.conf)

```Bash
sudo nano /etc/postgresql/16/main/postgresql.conf
```

Décommenter listen_address et ajouter l'IP locale puis l'IP Docker à côté de 'localhost':

```Plaintext
listen_addresses = 'localhost, 127.0.0.1, 172.17.0.1'
```

3. Autoriser uniquement le rôle grafana_reader (pg_hba.conf)
   Bash

sudo nano /etc/postgresql/16/main/pg_hba.conf

Ajouter la ligne stricte avec le masque /32 (une seule IP) ou /16 (sous-réseau Docker uniquement) :

```Plaintext
# Accès Grafana via l'interface docker0 uniquement
host    datawarehouse_e6    grafana_reader    172.17.0.1/32    scram-sha-256
```

4. Appliquer la configuration

```bash
sudo systemctl restart postgresql
```

Grafana devrait repasser au vert.
