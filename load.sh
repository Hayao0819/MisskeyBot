#!/usr/bin/env bash

set -Eeu -o pipefail

RepoDir="$(cd "$(dirname "${0}/")" || true;pwd)"

# shellcheck source=/dev/null
export FSBLIB_MSG="stderr"
source /dev/stdin < <(curl -sL "https://raw.githubusercontent.com/Hayao0819/FasBashLib/3cba5962259a670ab7f0eff79898ef7fd74cbcaa/fasbashlib.sh")

# Load bot config
for script in "${RepoDir}/bot.conf" "$RepoDir/sqlite.sh"; do
    if [[ "$(realpath "$0")" != "$script" ]] && [[ -e "$script" ]]; then
        source "$script"
    fi
done


if [[ -e "${RepoDir}/.env" ]]; then
    source "${RepoDir}/.env"
fi

MISSKEY_TOKEN="${MISSKEY_TOKEN-""}"

# Token check
if [[ -z "${MISSKEY_TOKEN}" ]]; then
    Msg.Err "Set MISSKEY_TOKEN variable"
    exit 1
else
    Msg.Info "Use MISSKEY_TOKEN"
fi

# Domain Check
if [[ -z "${InstanceDomain-""}" ]]; then
    Msg.Err "Set instance domain in config file."
    exit 1
fi

Misskey.Setup "${InstanceDomain}" "${MISSKEY_TOKEN}"

# Make directory
mkdir -p "${LogDir}"
