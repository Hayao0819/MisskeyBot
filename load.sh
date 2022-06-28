#!/usr/bin/env bash

set -Eeu -o pipefail

RepoDir="$(cd "$(dirname "${0}/")" || true;pwd)"

# shellcheck source=/dev/null
export FSBLIB_MSG="stderr"
source /dev/stdin < <(curl -sL "https://raw.githubusercontent.com/Hayao0819/FasBashLib/9bcf013c2438f7dabd5d9455c942dd0b20ad8c0f/fasbashlib.sh")

# Load bot config
source "${RepoDir}/bot.conf"

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
