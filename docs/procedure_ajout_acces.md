# Procédure d'ajout d'accès

Cette procédure décrit la démarche standardisée pour créer un nouvel accès utilisateur dans le Data Warehouse PostgreSQL, lui attribuer les privilèges stricts nécessaires à ses missions, et valider l'étanchéité de ses droits via un protocole de test.

Concernant ses restrictions d'accès, se baser sur le principe de moindre privilège et plus généralement se conformer au RGPD (pour cela, lire la stratégie adoptée dans la page [conformité RGPD](./conformite_rgpd.md) de la documentation)

Seul un nombre restreint d'utilisateur a la possiblité de créer un utilisateur

Pour la création, suivre les étapes suivantes:

0. Activer les variables d'environnement:

```bash
export $(cat .env | grep -v '^#' | xargs)
```

1. se connecter avec l'utilisateur admin
2. créer le nouveau rôle
3. lui donner les accès voulus

```bash
sudo -u ${POSTGRES_ADMIN} psql -d "${POSTGRES_DB}" -c "
CREATE USER ${NEW_USER} WITH PASSWORD '${NEW_USER_PASSWORD}';
GRANT CONNECT ON DATABASE ${POSTGRES_DB} TO ${NEW_USER};
GRANT USAGE ON SCHEMA public TO ${NEW_USER};"
--ajouter des accès à d'autres usages au besoin
```

remplacer NEW_USER et NEW_USER_PASSWORD par les rôles et mots de passe voulus et l'ajouter aux variables d'environnement, puis dans les gestionnaires de secrets lorsque le projet sera mis en production.
Pour l'octroi des accès, en fonction des accès, ajouter les commandes SQL voulues en gardant en tête le respect du principe de moindre privilège et plus largement la conformité au RGPD.

4. tester les accès du nouvel utilisateur
   Afin de tester le rôle récemment créé, se connecter à la base de données postgres via cet user

```
psql -U ${NEW_USER} -d${POSTGRES_DB} -h localhost -W
```

et tester des requêtes de consultation, création, modification et suppression de tables test(créer en amont avec l'admin au besoin) pour s'assurer que le nouvel utilisateur a le droit ou l'interdiction de faire les bonnes actions. Corriger au besoin et rééfectuer les tests tant que les tests ne sont pas pleinement concluants.

Enfin, ajouter la créatio nde ce nouvel utilisateur dans le readme, le documenter dans tous les tableaux du readme et compléter toutes les ections le concernant dans la partie RGPD

_remarque:_ bien veiller à utiliser des tables test pour ne pas toucher les tables en cours d'utilisation et veiller à ce qu'aucune table résiduelle ne reste à l'issue de la baterie de tests.
