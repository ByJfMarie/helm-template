# helm-template

Collection de Helm charts pour déployer des applications sur un cluster Kubernetes Talos/FluxCD.

## Charts

| Chart | Version | Description |
|---|---|---|
| [`charts/app`](charts/app/) | 0.2.0 | Déploiement d'une application conteneurisée |
| [`charts/databases`](charts/databases/) | 0.2.0 | Bases de données via opérateurs Kubernetes |
| [`charts/network`](charts/network/) | 1.1.0 | Routage Traefik + TLS cert-manager |
| [`starter`](starter/) | 1.0.0 | Exemple d'application complète (umbrella chart) |

## Stack cible

Ces charts sont conçus pour le cluster défini dans [ByJfMarie/gitops](https://github.com/ByJfMarie/gitops) :

- **Ingress** : Traefik v32 (public `traefik` / interne `traefik-internal`)
- **TLS** : cert-manager v1.16 avec ClusterIssuers `letsencrypt-staging` et `letsencrypt-prod`
- **PostgreSQL** : CloudNativePG v0.23
- **GitOps** : FluxCD v2

---

## chart `app`

Déploie un conteneur unique avec Deployment, Service, ServiceAccount et PVC optionnel.

```yaml
# values.yaml minimal
image:
  repository: ghcr.io/my-org/my-app
  tag: "1.0.0"

service:
  name: my-app
  port: 80
  targetPort: 8080
```

**Paramètres clés :**

| Paramètre | Défaut | Description |
|---|---|---|
| `replicaCount` | `1` | Nombre de réplicas |
| `image.repository` | `nginx` | Image Docker |
| `image.tag` | `latest` | Tag de l'image |
| `image.digest` | `""` | Digest SHA256 (prioritaire sur le tag) |
| `image.env` | `[]` | Variables d'environnement |
| `image.envFrom` | `[]` | Références ConfigMap/Secret (`configMapRef`, `secretRef`) |
| `resourcesPreset` | `small` | Preset de ressources : `nano/micro/small/medium/large/xlarge/2xlarge` |
| `persistent.enabled` | `false` | Active un PersistentVolumeClaim |
| `persistent.storageClassName` | `""` | StorageClass (vide = défaut du cluster) |

**Presets de ressources :**

| Preset | CPU request | Mémoire request | CPU limit | Mémoire limit |
|---|---|---|---|---|
| `nano` | 100m | 128Mi | 150m | 192Mi |
| `micro` | 250m | 256Mi | 375m | 384Mi |
| `small` | 250m | 256Mi | 500m | 512Mi |
| `medium` | 500m | 512Mi | 750m | 1024Mi |
| `large` | 1000m | 1024Mi | 1500m | 2048Mi |
| `xlarge` | 1000m | 2048Mi | 3000m | 4096Mi |
| `2xlarge` | 2000m | 4096Mi | 6000m | 8192Mi |

---

## chart `databases`

Déploie une base de données via un opérateur Kubernetes. Sélectionner le type via `database.type`.

| Type | Opérateur requis |
|---|---|
| `postgres` | [CloudNativePG](https://cloudnative-pg.io/) |
| `mariadb` | [mariadb-operator](https://github.com/mariadb-operator/mariadb-operator) |
| `mysql` | [mysql-operator](https://github.com/mysql/mysql-operator) |
| `redis` | [redis-operator (OpsTree)](https://github.com/OT-CONTAINER-KIT/redis-operator) |
| `mongodb` | [Bitnami MongoDB chart](https://github.com/bitnami/charts/tree/main/bitnami/mongodb) |

**PostgreSQL (CloudNativePG) :**

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
    passwordSuperUser: "changeme-super"
    passwordSecretName: myapp-postgres-secret
    extraLibs:
      - pg_stat_statements
    scripts: |
      CREATE SCHEMA IF NOT EXISTS myapp;
  backup:
    enabled: true
    s3:
      bucketName: my-backups
      endpointURL: https://s3.eu-central-003.backblazeb2.com
      secretName: backup-s3-secret
```

> Les mots de passe ne doivent jamais être commités. Utiliser des Secrets Kubernetes créés séparément.

---

## chart `network`

Crée un `IngressRoute` Traefik et un `Certificate` cert-manager.

```yaml
name: my-app

ingressClassName: "traefik"          # ou "traefik-internal"
traefikNamespace: "traefik"

tls:
  enabled: true
  letsencryptEnv: "staging"          # staging | prod
  commonName: myapp.example.com
  dnsNames:
    - myapp.example.com

traefik:
  routes:
    - match: "Host(`myapp.example.com`)"
      service:
        name: frontend
        port: 80
    - match: "Host(`myapp.example.com`) && PathPrefix(`/api`)"
      service:
        name: backend
        port: 80
```

**Protection par mot de passe (basicAuth) :**

```yaml
traefik:
  routes:
    - match: "Host(`myapp.example.com`) && PathPrefix(`/admin`)"
      service:
        name: backend
        port: 80
      htaccess:
        users:
          - username: admin
            password: "$apr1$..."   # htpasswd -nb admin monmotdepasse
```

---

## Déploiement via FluxCD

Exemple de `HelmRelease` pour déployer l'application dans le cluster gitops :

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: my-app
  namespace: my-app
spec:
  interval: 10m
  chart:
    spec:
      chart: starter
      version: "1.0.0"
      sourceRef:
        kind: HelmRepository
        name: helm-template
        namespace: flux-system
  values:
    frontend:
      image:
        repository: ghcr.io/my-org/my-app-frontend
        tag: "1.0.0"
    backend:
      image:
        repository: ghcr.io/my-org/my-app-backend
        tag: "1.0.0"
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
          passwordSecretName: my-app-postgres-secret
    network:
      name: my-app
      tls:
        enabled: true
        letsencryptEnv: staging
        commonName: myapp.example.com
        dnsNames:
          - myapp.example.com
      traefik:
        routes:
          - match: "Host(`myapp.example.com`)"
            service:
              name: frontend
              port: 80
          - match: "Host(`myapp.example.com`) && PathPrefix(`/api`)"
            service:
              name: backend
              port: 80
```

---

## Développement local

```bash
# Linter un chart
helm lint charts/app

# Générer les manifestes sans déployer
helm template my-release charts/app -f my-values.yaml

# Installer en dry-run
helm install my-release charts/app --dry-run --debug
```
