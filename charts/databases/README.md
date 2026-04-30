# chart `databases`

Déploie une base de données sur Kubernetes via un opérateur. Sélectionner le moteur avec `database.type`.

| Type | Opérateur requis | CRD |
|---|---|---|
| `postgres` | [CloudNativePG](https://cloudnative-pg.io/) | `Cluster`, `ScheduledBackup` |
| `mariadb` | [mariadb-operator](https://github.com/mariadb-operator/mariadb-operator) | `MariaDB`, `Database`, `User`, `Grant` |
| `mysql` | [mysql-operator](https://github.com/mysql/mysql-operator) | `InnoDBCluster` |
| `redis` | [redis-operator OpsTree](https://github.com/OT-CONTAINER-KIT/redis-operator) | `Redis` |
| `mongodb` | [Bitnami MongoDB chart](https://github.com/bitnami/charts/tree/main/bitnami/mongodb) | Deployment natif |

## Installation

```bash
# Télécharger les dépendances (MongoDB)
helm dependency update ./charts/databases

helm install my-db ./charts/databases -f values.yaml
```

> **Important** : Les mots de passe dans `values.yaml` créent des Secrets Kubernetes.
> Ne jamais commiter des valeurs réelles — utiliser des références à des secrets externes ou un outil de chiffrement.

---

## PostgreSQL (CloudNativePG)

Nécessite l'opérateur CloudNativePG installé dans le cluster (`cnpg-system`).

### Paramètres

| Paramètre | Défaut | Description |
|---|---|---|
| `postgres.instances` | `1` | Nombre d'instances (1 = standalone, 2+ = HA) |
| `postgres.version` | `16.3` | Version PostgreSQL (image CloudNativePG) |
| `postgres.storage.size` | `5Gi` | Taille du volume de données |
| `postgres.storage.storageClassName` | `""` | StorageClass (vide = défaut du cluster) |
| `postgres.initdb.database` | — | Nom de la base à créer |
| `postgres.initdb.user` | — | Propriétaire de la base |
| `postgres.initdb.password` | — | Mot de passe de l'utilisateur |
| `postgres.initdb.passwordSuperUser` | — | Mot de passe du superuser `postgres` |
| `postgres.initdb.passwordSecretName` | `postgres-app-secret` | Nom du Secret Kubernetes créé |
| `postgres.initdb.scripts` | `""` | SQL exécuté après initialisation |
| `postgres.initdb.extraLibs` | `[]` | Librairies à précharger (`shared_preload_libraries`) |
| `postgres.backup.enabled` | `false` | Active les sauvegardes automatiques vers S3 |
| `postgres.backup.schedule` | `0 0 * * *` | Cron de sauvegarde (minuit chaque nuit) |
| `postgres.backup.retentionPolicy` | `30d` | Durée de rétention des sauvegardes |
| `postgres.backup.s3.bucketName` | — | Nom du bucket S3 |
| `postgres.backup.s3.endpointURL` | Backblaze B2 | URL de l'endpoint S3 compatible |
| `postgres.backup.s3.secretName` | `backup-s3-secret` | Secret contenant `access_key_id` et `secret_access_key` |

**Connexion à la base** : CloudNativePG expose automatiquement les services :
- `<release>-databases-postgres-rw` — lecture/écriture (primary)
- `<release>-databases-postgres-ro` — lecture seule (replicas)
- `<release>-databases-postgres-r` — load-balancé sur tous les nœuds

### Exemple minimal

```yaml
database:
  type: postgres

postgres:
  instances: 1
  version: "16.3"
  storage:
    size: 10Gi
  initdb:
    database: mydb
    user: myuser
    password: "changeme"
    passwordSuperUser: "supersecret"
    passwordSecretName: myapp-postgres-secret
```

### Exemple avec extensions et script d'init

```yaml
postgres:
  initdb:
    database: myapp
    user: myapp
    password: "changeme"
    passwordSuperUser: "supersecret"
    passwordSecretName: myapp-postgres-secret
    extraLibs:
      - pg_stat_statements
      - pgcrypto
    scripts: |
      CREATE EXTENSION IF NOT EXISTS pgcrypto;
      CREATE SCHEMA IF NOT EXISTS myapp;
      ALTER SCHEMA myapp OWNER TO myapp;
```

### Exemple avec backup S3

Créer d'abord le Secret manuellement :

```bash
kubectl create secret generic backup-s3-secret \
  --from-literal=access_key_id=MY_KEY_ID \
  --from-literal=secret_access_key=MY_SECRET_KEY
```

```yaml
postgres:
  backup:
    enabled: true
    schedule: "0 2 * * *"
    retentionPolicy: "14d"
    s3:
      bucketName: my-k8s-backups
      endpointURL: https://s3.eu-central-003.backblazeb2.com
      secretName: backup-s3-secret
```

---

## MariaDB (mariadb-operator)

Nécessite [mariadb-operator](https://github.com/mariadb-operator/mariadb-operator) installé dans le cluster.

### Paramètres clés

| Paramètre | Défaut | Description |
|---|---|---|
| `mariadb.image` | `mariadb:11.4` | Image MariaDB |
| `mariadb.replicaCount` | `1` | Nombre de réplicas |
| `mariadb.rootPassword` | — | Mot de passe root (encodé en base64 dans le Secret) |
| `mariadb.rootPasswordSecretName` | `mariadb-root-password` | Nom du Secret root |
| `mariadb.size` | `10Gi` | Taille du volume |
| `mariadb.storageClassName` | `""` | StorageClass |
| `mariadb.databases` | — | Liste des bases à créer |
| `mariadb.users` | — | Liste des utilisateurs à créer |

### Exemple

```yaml
database:
  type: mariadb

mariadb:
  rootPassword: "rootsecret"
  size: 20Gi
  databases:
    - name: myapp
      characterSet: utf8mb4
      collate: utf8mb4_unicode_ci
  users:
    - name: myapp
      password: "usersecret"
      passwordSecretName: mariadb-myapp-password
      database: myapp
      host: "%"
      privileges: "SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER"
```

---

## Redis (redis-operator OpsTree)

Nécessite [redis-operator](https://github.com/OT-CONTAINER-KIT/redis-operator) installé dans le cluster.

### Paramètres clés

| Paramètre | Défaut | Description |
|---|---|---|
| `redis.version` | `7.2.4` | Version Redis |
| `redis.size` | `5Gi` | Taille du volume |
| `redis.storageClassName` | `""` | StorageClass |
| `redis.redisPassword` | — | Mot de passe Redis |
| `redis.redisSecret.name` | `redis-secret` | Nom du Secret |
| `redis.exporterEnabled` | `false` | Active le redis-exporter (métriques Prometheus) |
| `redis.exporterVersion` | `1.62.0` | Version du redis-exporter |

### Exemple

```yaml
database:
  type: redis

redis:
  version: "7.2.4"
  size: 2Gi
  redisPassword: "myredispass"
  exporterEnabled: true
```

---

## MySQL (mysql-operator)

Nécessite [mysql-operator](https://github.com/mysql/mysql-operator) installé dans le cluster.

### Paramètres clés

| Paramètre | Défaut | Description |
|---|---|---|
| `mysql.instances` | `1` | Nombre d'instances InnoDB |
| `mysql.version` | `8.4.0` | Version MySQL |
| `mysql.storage.storageSize` | `10Gi` | Taille du volume |
| `mysql.credentials.rootPassword` | — | Mot de passe root |
| `mysql.backup.enabled` | `false` | Active les sauvegardes S3 |

### Exemple

```yaml
database:
  type: mysql

mysql:
  instances: 1
  version: "8.4.0"
  storage:
    storageSize: "20Gi"
  credentials:
    rootUser: root
    rootPassword: "rootsecret"
```

---

## MongoDB (Bitnami)

Déployé via le chart Bitnami en tant que dépendance. Activer avec `mongodb.deploy: true`.

### Exemple

```yaml
database:
  type: mongodb

mongodb:
  deploy: true
  architecture: standalone
  global:
    storageClass: ""
    storageSize: "10Gi"
  auth:
    rootPassword: "rootsecret"
    usernames:
      - myuser
    passwords:
      - "usersecret"
    databases:
      - mydb
```

---

## Utilisation en sous-chart (umbrella)

Dans le `Chart.yaml` parent :

```yaml
dependencies:
  - name: databases
    version: "0.2.0"
    repository: "https://byjfmarie.github.io/helm-template"
    alias: database
```

Dans le `values.yaml` parent :

```yaml
database:
  database:
    type: postgres
  postgres:
    instances: 1
    storage:
      size: 10Gi
    initdb:
      database: mydb
      user: myuser
      password: "changeme"
      passwordSuperUser: "supersecret"
      passwordSecretName: myapp-postgres-secret
```
