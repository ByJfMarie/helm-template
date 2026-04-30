# chart `network`

Crée les ressources réseau pour exposer une application via Traefik et cert-manager :
- `IngressRoute` Traefik avec routage par domaine/path
- `Certificate` cert-manager (Let's Encrypt) si TLS activé
- `Middleware` basicAuth optionnel par route

Conçu pour le cluster [ByJfMarie/gitops](https://github.com/ByJfMarie/gitops) avec Traefik v32 et cert-manager v1.16.

## Installation

```bash
helm install my-app-network ./charts/network -f values.yaml -n my-app
```

## Paramètres

### Général

| Paramètre | Défaut | Description |
|---|---|---|
| `name` | `network` | Préfixe des ressources créées |
| `ingressClassName` | `traefik` | IngressClass à utiliser (`traefik` ou `traefik-internal`) |
| `traefikNamespace` | `traefik` | Namespace Traefik (pour le middleware `https-redirect`) |

### TLS

| Paramètre | Défaut | Description |
|---|---|---|
| `tls.enabled` | `false` | Active la création du Certificate et du TLS sur l'IngressRoute |
| `tls.letsencryptEnv` | `staging` | `staging` ou `prod` (ClusterIssuer à utiliser) |
| `tls.commonName` | `example.com` | Domaine principal du certificat |
| `tls.dnsNames` | `[example.com]` | Noms alternatifs (SAN) |
| `tls.secretName` | `<name>-tls` | Nom du Secret TLS (auto-généré si vide) |

**ClusterIssuers disponibles dans le cluster :**
- `letsencrypt-staging` — certificats de test (non approuvés par les navigateurs)
- `letsencrypt-prod` — certificats de production

### Routes

Chaque route dans `traefik.routes` correspond à une règle de routage Traefik.

| Champ | Requis | Description |
|---|---|---|
| `match` | oui | Règle de matching Traefik (syntaxe `Host()`, `PathPrefix()`, etc.) |
| `service.name` | oui | Nom du Service Kubernetes cible |
| `service.port` | oui | Port du Service cible |
| `middlewares` | non | Middlewares Traefik supplémentaires à appliquer |
| `htaccess` | non | Protection basicAuth sur cette route (voir ci-dessous) |

> Le middleware `https-redirect` (namespace `traefik`) est automatiquement ajouté à toutes les routes.

---

## Exemples

### Exposition simple (HTTP uniquement)

```yaml
name: my-app
ingressClassName: traefik

tls:
  enabled: false

traefik:
  routes:
    - match: "Host(`myapp.example.com`)"
      service:
        name: frontend
        port: 80
```

### HTTPS avec Let's Encrypt staging

```yaml
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
```

### HTTPS production + routage frontend/backend

```yaml
name: my-app

tls:
  enabled: true
  letsencryptEnv: prod
  commonName: myapp.example.com
  dnsNames:
    - myapp.example.com
    - www.myapp.example.com

traefik:
  routes:
    - match: "Host(`myapp.example.com`) || Host(`www.myapp.example.com`)"
      service:
        name: frontend
        port: 80
    - match: "Host(`myapp.example.com`) && PathPrefix(`/api`)"
      service:
        name: backend
        port: 80
```

### Middleware personnalisé (strip prefix)

```yaml
traefik:
  routes:
    - match: "Host(`myapp.example.com`) && PathPrefix(`/api`)"
      service:
        name: backend
        port: 8080
      middlewares:
        - name: api-strip-prefix
          namespace: my-app
```

### Protection par mot de passe (basicAuth)

Générer le hash du mot de passe avec `htpasswd` :

```bash
htpasswd -nb admin monsupermdp
# admin:$apr1$xyz$...
```

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
            password: "$apr1$xyz$..."
          - username: ops
            password: "$apr1$abc$..."
```

Cela crée automatiquement un Secret et un Middleware `basicAuth` Traefik dans le namespace de la release.

### Accès interne uniquement (Traefik interne)

Pour une application accessible uniquement sur le réseau local (sans IP publique) :

```yaml
name: my-internal-app
ingressClassName: traefik-internal
traefikNamespace: traefik-internal

tls:
  enabled: true
  letsencryptEnv: staging
  commonName: myapp.jmarie.local
  dnsNames:
    - myapp.jmarie.local

traefik:
  routes:
    - match: "Host(`myapp.jmarie.local`)"
      service:
        name: frontend
        port: 80
```

---

## Utilisation en sous-chart (umbrella)

Dans le `Chart.yaml` parent :

```yaml
dependencies:
  - name: network
    version: "1.1.0"
    repository: "https://byjfmarie.github.io/helm-template"
    alias: network
```

Dans le `values.yaml` parent :

```yaml
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
