# chart `starter`

Chart umbrella d'exemple pour déployer une application full-stack :
**frontend + backend + base de données + routage réseau.**

Il agrège les trois charts de ce repo (`app`, `databases`, `network`) en une seule release Helm.

## Utilisation

Ce chart est un point de départ à **copier et adapter** pour chaque nouvelle application.

```bash
# Copier le chart
cp -r starter/ mon-app/

# Adapter Chart.yaml (nom, version) et values.yaml
# puis installer
helm dependency update mon-app/
helm install mon-app ./mon-app -f mon-app/values.yaml -n mon-app --create-namespace
```

## Structure

```
starter/
├── Chart.yaml          ← Dépendances vers app x2, databases, network
├── values.yaml         ← Exemple de configuration complète
└── templates/
    └── _helpers.tpl
```

## Exemple de values.yaml complet

```yaml
# ── Frontend ────────────────────────────────────────────────────────────────
frontend:
  replicaCount: 1
  image:
    repository: ghcr.io/my-org/my-app-frontend
    tag: "1.0.0"
  imagePullSecrets:
    - name: registry-credentials
  service:
    name: frontend
    port: 80
    targetPort: 80
  resourcesPreset: small

# ── Backend ─────────────────────────────────────────────────────────────────
backend:
  replicaCount: 1
  image:
    repository: ghcr.io/my-org/my-app-backend
    tag: "1.0.0"
  imagePullSecrets:
    - name: registry-credentials
  image:
    envFrom:
      - secretRef:
          name: my-app-backend-secrets
  service:
    name: backend
    port: 80
    targetPort: 8080
  livenessProbe:
    initialDelaySeconds: 30
    httpGet:
      path: /health
      port: http
  resourcesPreset: small

# ── Base de données ──────────────────────────────────────────────────────────
database:
  database:
    type: postgres
  postgres:
    instances: 1
    version: "16.3"
    storage:
      size: 10Gi
    initdb:
      database: myapp
      user: myapp
      password: ""                         # à fournir via --set ou secret externe
      passwordSuperUser: ""                # à fournir via --set ou secret externe
      passwordSecretName: my-app-pg-secret
      extraLibs:
        - pg_stat_statements
      scripts: |
        CREATE SCHEMA IF NOT EXISTS myapp;
    backup:
      enabled: false

# ── Réseau ───────────────────────────────────────────────────────────────────
network:
  name: my-app
  ingressClassName: traefik
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

## Déploiement via FluxCD

Ajouter le HelmRepository dans le cluster gitops :

```yaml
# infrastructure/controllers/helm-template.yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: helm-template
  namespace: flux-system
spec:
  interval: 12h
  url: https://byjfmarie.github.io/helm-template
```

Puis créer une HelmRelease pour l'application :

```yaml
# apps/my-app/helmrelease.yaml
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
  valuesFrom:
    - kind: Secret
      name: my-app-helm-values      # Secret contenant les mots de passe
      valuesKey: values.yaml
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
          database: myapp
          user: myapp
          passwordSecretName: my-app-pg-secret
    network:
      name: my-app
      tls:
        enabled: true
        letsencryptEnv: prod
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

## Adapter pour une nouvelle application

1. Copier le dossier `starter/` sous le nom de l'application
2. Dans `Chart.yaml` : mettre à jour `name`, `description`, `version`
3. Dans `values.yaml` : remplacer les images, domaines, tailles de stockage
4. Créer les Secrets Kubernetes requis manuellement (mots de passe DB, registry credentials)
5. Lancer `helm dependency update` puis `helm install`
