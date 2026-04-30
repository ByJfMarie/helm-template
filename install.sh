#!/bin/bash
# Appelé par venv.sh — ne pas exécuter directement

if [[ "$1" != "fromvenv" ]]; then
    echo "install.sh must not be run directly (called by venv.sh)"
    return
fi

if [[ ! -d ".venv" ]]; then
    mkdir -p ".venv"
    mkdir -p .helm/data .helm/conf .helm/cache

    [[ $(uname -s) = "Linux" ]] && DISTRIB="linux" || DISTRIB="darwin"
    [[ $(sysctl -n machdep.cpu.brand_string 2>/dev/null) =~ "Apple" ]] && PROC="arm64" || PROC="amd64"

    echo "→ Helm v${HELM_VERSION}"
    curl -sL "https://get.helm.sh/helm-v${HELM_VERSION}-${DISTRIB}-${PROC}.tar.gz" > /tmp/helm.tar.gz
    tar xzf /tmp/helm.tar.gz -C /tmp
    mv /tmp/${DISTRIB}-${PROC}/helm .venv/helm
    chmod u+x .venv/helm

    echo "→ Sops v${SOPS_VERSION}"
    curl -sL "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.${DISTRIB}.${PROC}" > .venv/sops
    chmod u+x .venv/sops

    echo "→ age v${AGE_VERSION}"
    curl -sL "https://github.com/FiloSottile/age/releases/download/v${AGE_VERSION}/age-v${AGE_VERSION}-${DISTRIB}-${PROC}.tar.gz" > /tmp/age.tar.gz
    tar xzf /tmp/age.tar.gz -C /tmp
    mv /tmp/age/age .venv/age
    mv /tmp/age/age-keygen .venv/age-keygen
    chmod u+x .venv/age .venv/age-keygen

    echo "→ kubectl v${KUBE_VERSION}"
    curl -sL "https://storage.googleapis.com/kubernetes-release/release/v${KUBE_VERSION}/bin/${DISTRIB}/${PROC}/kubectl" > .venv/kubectl
    chmod u+x .venv/kubectl

    echo "→ Plugin helm-diff"
    HELM_DATA_HOME="$(pwd)/.helm/data" HELM_CONFIG_HOME="$(pwd)/.helm/conf" HELM_CACHE_HOME="$(pwd)/.helm/cache" \
        .venv/helm plugin install https://github.com/databus23/helm-diff > /dev/null 2>&1

    echo "→ Plugin helm-secrets"
    HELM_DATA_HOME="$(pwd)/.helm/data" HELM_CONFIG_HOME="$(pwd)/.helm/conf" HELM_CACHE_HOME="$(pwd)/.helm/cache" \
        .venv/helm plugin install https://github.com/jkroepke/helm-secrets > /dev/null 2>&1

    echo "✓ Environnement prêt"
fi
