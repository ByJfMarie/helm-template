# Instructions pour Claude

Ce fichier documente les règles de travail pour ce repo.
Il doit être mis à jour dès qu'une nouvelle instruction est donnée.

---

## Langue

- Répondre en **français** dans les messages
- Commentaires YAML/code : français
- Messages de commit : **anglais** (convention Git standard)

---

## Pull Requests

- **Toujours créer une PR** pour les changements — ne jamais merger directement sur `main` sans demande explicite
- **Ne jamais merger la PR** sauf si l'utilisateur le demande explicitement
- Format du titre : `type: description courte` (ex: `feat: add network chart`, `fix: postgres storage class`)
- La PR doit inclure dans le body : ce qui change, pourquoi, et les étapes de test

---

## CHANGELOG

- **Mettre à jour `CHANGELOG.md` à chaque PR**
- Format : [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
- Les changements en cours vont dans la section `## [Unreleased]`
- Lors du merge, déplacer `[Unreleased]` vers une version numérotée avec la date

---

## Commits

- Format : `type: description` en anglais
- Toujours ajouter `Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>`
- Types : `feat`, `fix`, `chore`, `docs`, `refactor`

---

## Structure du repo

```
charts/
  app/          ← Chart pour déployer une application conteneurisée
  databases/    ← Chart pour déployer une base de données via opérateur
  network/      ← Chart pour le routage Traefik + TLS cert-manager

starter/        ← Chart umbrella d'exemple (frontend + backend + db + réseau)

CHANGELOG.md
CLAUDE.md
README.md
```

---

## Charts disponibles

| Chart | Version | Description |
|---|---|---|
| `app` | 0.2.0 | Déploiement d'un conteneur (Deployment + Service + PVC optionnel) |
| `databases` | 0.2.0 | PostgreSQL (CloudNativePG), MariaDB, MySQL, Redis, MongoDB |
| `network` | 1.1.0 | IngressRoute Traefik + Certificate cert-manager |

---

## Cluster cible (repo gitops)

Le cluster cible est géré via FluxCD dans le repo `ByJfMarie/gitops`.

| Composant | Namespace | Version |
|---|---|---|
| Traefik public | `traefik` | 32.* |
| Traefik interne | `traefik-internal` | 32.* |
| CloudNativePG | `cnpg-system` | 0.23.* |
| cert-manager | `cert-manager` | v1.16.* |
| MetalLB | `metallb-system` | 0.14.* |

**ClusterIssuers disponibles** : `letsencrypt-staging` | `letsencrypt-prod`

**IngressClass** : `traefik` (public) | `traefik-internal` (réseau local uniquement)

---

## Secrets & SOPS

Les mots de passe et clés API ne doivent jamais être commités en clair.

**Prérequis (une seule fois) :**

```bash
brew install sops age helm kubectl
helm plugin install https://github.com/jkroepke/helm-secrets
helm plugin install https://github.com/databus23/helm-diff
```

**Workflow SOPS :**

```bash
# Générer une clé age (une seule fois)
age-keygen -o key.txt
# → copier la clé publique dans .sops.yaml
# → sauvegarder key.txt en lieu sûr (1Password, etc.)

# Créer et chiffrer les secrets
cp starter/secrets.example.yaml secrets.yaml
# éditer secrets.yaml avec les vraies valeurs
sops --encrypt secrets.yaml > secrets.enc.yaml
rm secrets.yaml  # ne jamais commiter la version non chiffrée

# Déployer
helm secrets install my-app ./starter -f values.yaml -f secrets.enc.yaml -n my-app
```

**Convention dans les values :**
- `value` → valeur en clair (commitable)
- `valueEncrypt` → valeur déchiffrée par SOPS/helm-secrets (dans `secrets.enc.yaml`)
- `valueFrom` → référence à un Secret/ConfigMap Kubernetes existant

**Fichiers protégés par `.gitignore` :** `secrets.yaml`, `*.secrets.yaml`, `key.txt`

**Avec FluxCD :** utiliser `valuesFrom` avec un Secret Kubernetes contenant les valeurs sensibles (créé manuellement ou via External Secrets Operator).

---

## Conventions Helm

- `storageClassName: ""` → le cluster choisit la StorageClass par défaut
- Image : utiliser `digest` pour épingler une version immuable, sinon `tag`
- `resourcesPreset` : `nano | micro | small | medium | large | xlarge | 2xlarge`

---

## Worktree

Les changements se font dans le worktree actif. Pour pousser sur `main` directement (hotfix) :
```bash
git pull --rebase origin main && git push origin HEAD:main
```
