#!/bin/bash
# Usage : source venv.sh

export HELM_VERSION=3.16.4
export KUBE_VERSION=1.31.4
export SOPS_VERSION=3.9.4
export AGE_VERSION=1.2.1

setup_env() {
    CUR_VENV_DIR="$(pwd)"
    export PATH="${CUR_VENV_DIR}/.venv:$PATH"
    export HELM_DATA_HOME="${CUR_VENV_DIR}/.helm/data"
    export HELM_CONFIG_HOME="${CUR_VENV_DIR}/.helm/conf"
    export HELM_CACHE_HOME="${CUR_VENV_DIR}/.helm/cache"
    export SOPS_AGE_KEY_FILE="${HOME}/.config/sops/age/keys.txt"

    bash install.sh "fromvenv"

    if [[ -n "$SHELL" ]]; then
        source <(kubectl completion "${SHELL##*/}" 2>/dev/null) || true
        source <(helm completion "${SHELL##*/}" 2>/dev/null) || true
    fi

    echo "✓ PATH, HELM_*, SOPS_AGE_KEY_FILE configurés"
}

$(return >/dev/null 2>&1)
if [[ $? -ne 0 ]]; then
    echo "Ce script doit être sourcé : source venv.sh"
    exit 1
fi

if [[ ! -f "venv.sh" ]]; then
    echo "Sourcer depuis le répertoire racine du repo"
    return 1
fi

setup_env
