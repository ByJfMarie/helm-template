# chart `app`

Déploie une application conteneurisée sur Kubernetes : Deployment, Service, ServiceAccount et PVC optionnel.

## Installation

```bash
helm install my-app ./charts/app -f values.yaml
```

## Paramètres

### Image

| Paramètre | Défaut | Description |
|---|---|---|
| `image.repository` | `nginx` | Image Docker |
| `image.tag` | `latest` | Tag de l'image (ignoré si `digest` est défini) |
| `image.digest` | `""` | Digest SHA256 pour une référence immuable (`sha256:abc…`) |
| `image.pullPolicy` | `IfNotPresent` | Politique de pull |
| `image.containerName` | nom du chart | Nom du conteneur dans le pod |
| `image.env` | `[]` | Variables d'environnement inline |
| `image.envFrom` | `[]` | Références ConfigMap/Secret |
| `imagePullSecrets` | `[]` | Secrets pour les registries privés |

### Réplicas et ressources

| Paramètre | Défaut | Description |
|---|---|---|
| `replicaCount` | `1` | Nombre de réplicas |
| `resourcesPreset` | `small` | Preset de ressources (voir tableau ci-dessous) |
| `resources` | `{}` | Ressources explicites (prioritaire sur `resourcesPreset`) |

**Presets disponibles :**

| Preset | CPU request/limit | Mémoire request/limit |
|---|---|---|
| `nano` | 100m / 150m | 128Mi / 192Mi |
| `micro` | 250m / 375m | 256Mi / 384Mi |
| `small` | 250m / 500m | 256Mi / 512Mi |
| `medium` | 500m / 750m | 512Mi / 1024Mi |
| `large` | 1000m / 1500m | 1024Mi / 2048Mi |
| `xlarge` | 1000m / 3000m | 2048Mi / 4096Mi |
| `2xlarge` | 2000m / 6000m | 4096Mi / 8192Mi |

### Service

| Paramètre | Défaut | Description |
|---|---|---|
| `service.name` | nom du chart | Nom du Service Kubernetes |
| `service.type` | `ClusterIP` | Type de service |
| `service.port` | `80` | Port exposé |
| `service.targetPort` | `80` | Port du conteneur |

### Probes

| Paramètre | Défaut | Description |
|---|---|---|
| `livenessProbeEnabled` | `true` | Active la liveness probe |
| `readinessProbeEnabled` | `true` | Active la readiness probe |
| `livenessProbe` | `GET / :http` | Configuration de la liveness probe |
| `readinessProbe` | `GET / :http` | Configuration de la readiness probe |

### Stockage persistant

| Paramètre | Défaut | Description |
|---|---|---|
| `persistent.enabled` | `false` | Active un PersistentVolumeClaim |
| `persistent.name` | `app-data` | Nom du PVC |
| `persistent.storage` | `1Gi` | Taille du volume |
| `persistent.storageClassName` | `""` | StorageClass (vide = défaut du cluster) |
| `persistent.accessMode` | `ReadWriteOnce` | Mode d'accès |
| `deployVolume` | `false` | Monte les volumes définis dans le Deployment |
| `volumes` | `[]` | Définitions des volumes |
| `volumeMounts` | `[]` | Points de montage dans le conteneur |

### Autres

| Paramètre | Défaut | Description |
|---|---|---|
| `serviceAccount.create` | `true` | Crée un ServiceAccount dédié |
| `initContainers` | `[]` | Init containers |
| `podAnnotations` | `{}` | Annotations du pod |
| `podLabels` | `{}` | Labels supplémentaires du pod |
| `nodeSelector` | `{}` | Sélecteur de nœud |
| `tolerations` | `[]` | Tolérances |
| `affinity` | `{}` | Règles d'affinité |

---

## Exemples

### Application simple (tag)

```yaml
image:
  repository: ghcr.io/my-org/my-app
  tag: "2.1.0"

service:
  name: my-app
  port: 80
  targetPort: 3000

livenessProbe:
  initialDelaySeconds: 15
  httpGet:
    path: /health
    port: http
```

### Image épinglée par digest

```yaml
image:
  repository: ghcr.io/my-org/my-app
  digest: "sha256:a1b2c3d4e5f6..."
```

### Variables d'environnement

```yaml
image:
  env:
    - name: APP_ENV
      value: "production"
    - name: LOG_LEVEL
      value: "info"
  envFrom:
    - configMapRef:
        name: my-app-config
    - secretRef:
        name: my-app-secrets
```

### Registry privé

```yaml
imagePullSecrets:
  - name: registry-credentials

image:
  repository: registry.example.com/my-org/my-app
  tag: "1.0.0"
```

### Avec stockage persistant

```yaml
persistent:
  enabled: true
  name: my-app-data
  storage: 10Gi
  accessMode: ReadWriteOnce

deployVolume: true
volumes:
  - name: my-app-data
    persistentVolumeClaim:
      claimName: my-app-data
volumeMounts:
  - mountPath: /app/data
    name: my-app-data
```

### Ressources explicites (production)

```yaml
resourcesPreset: "none"
resources:
  requests:
    cpu: 200m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

### Avec init container

```yaml
initContainers:
  - name: wait-for-db
    image: busybox:1.36
    command: ['sh', '-c', 'until nc -z my-app-postgres-rw 5432; do sleep 2; done']
```

---

## Utilisation en sous-chart (umbrella)

Dans le `Chart.yaml` parent :

```yaml
dependencies:
  - name: app
    version: "0.2.0"
    repository: "https://byjfmarie.github.io/helm-template"
    alias: backend
```

Dans le `values.yaml` parent :

```yaml
backend:
  image:
    repository: ghcr.io/my-org/my-app-backend
    tag: "1.0.0"
  service:
    name: backend
    port: 80
    targetPort: 8080
```
