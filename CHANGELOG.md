# Changelog

Tous les changements notables de ce projet sont documentés ici.

Format : [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
Versioning : [Semantic Versioning](https://semver.org/)

---

## [Unreleased]

### Added
- `.sops.yaml` : configuration SOPS avec age pour chiffrer les fichiers `secrets.yaml`
- Prérequis documentés dans `CLAUDE.md` : `brew install sops age helm` + plugins helm-secrets et helm-diff
- `starter/secrets.example.yaml` : template des valeurs sensibles à chiffrer avec SOPS
- Convention `valueEncrypt` restaurée dans `charts/app` : permet de passer des secrets chiffrés SOPS via helm-secrets
- Support `valueFrom` (secretKeyRef / configMapKeyRef) dans les env vars du chart `app`
- `.gitignore` : exclusion automatique de `secrets.yaml` et `key.txt`
- `CLAUDE.md` : documentation du workflow SOPS complet

---

## [1.0.0] - 2026-04-30

### Added
- Chart `app` v0.2.0 : déploiement de conteneur avec support digest/tag, envFrom natif, presets de ressources
- Chart `databases` v0.2.0 : PostgreSQL (CloudNativePG), MariaDB, MySQL, Redis, MongoDB avec backup S3 configurable
- Chart `network` v1.1.0 : IngressRoute Traefik avec sélection d'IngressClass, Certificate cert-manager, middleware basicAuth
- Chart `starter` v1.0.0 : exemple d'application full-stack (frontend + backend + postgres + routage)
- `CLAUDE.md` avec les conventions de travail adaptées au cluster gitops
- `CHANGELOG.md` et `README.md`
- `.gitignore` adapté aux projets Helm

### Changed
- Renommage complet : suppression de toutes les références à "steamulo" (charts, valeurs, storage classes, registries)
- `charts/app` : correction du support image tag/digest mutuellement exclusifs
- `charts/app` : `envFrom` supporte nativement `configMapRef` et `secretRef` (plus de workaround)
- `charts/databases` : séparation des templates postgresql (Cluster, Secrets, ScheduledBackup, Configmap dans des fichiers distincts)
- `charts/databases` : backup S3 entièrement configurable (bucket, endpoint, secret)
- `charts/databases` : storage class vide par défaut (utilise la StorageClass par défaut du cluster)
- `charts/network` : correction typo `secretNa-me` → `secretName`
- `charts/network` : ClusterIssuer aligné avec le repo gitops (`letsencrypt-staging` / `letsencrypt-prod`)
- `charts/network` : ajout `ingressClassName` pour sélectionner Traefik public ou interne
- `charts/network` : namespace Traefik configurable via `traefikNamespace`

### Removed
- `harbor-secret.yaml` contenant des credentials hardcodés (steamulo harbor registry)
- `SealedSecret` backblaze spécifique à Steamulo
- Dépendance maildev (spécifique à l'infrastructure Steamulo)
- Références aux storage classes `steamulo-nas` et `steamulo-nas-nosquash`
- Variables d'environnement par défaut inutiles (`ENVIRONMENT: docker`)
