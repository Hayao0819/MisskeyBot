#!/usr/bin/env bash

set -Eeu -o pipefail

CurrentDir="$(cd "$(dirname "${0}")" || true;pwd)"

# shellcheck source=/dev/null
source /dev/stdin < <(fasbashlib -x "v0.2.2" 2> /dev/null || curl -sL "https://github.com/Hayao0819/FasBashLib/releases/download/v0.2.2/fasbashlib.sh")

# Load bot config
source "$CurrentDir/bot.conf"
source "${CurrentDir}/api-base.sh"
source "${CurrentDir}/api.sh"

if [[ -e "${CurrentDir}/.env" ]]; then
    source "${CurrentDir}/.env"
fi

APIEntryPoint="https://${MisskeyInstanceDomain}/api"
MISSKEY_TOKEN="${MISSKEY_TOKEN-""}"

# Token check
if [[ -z "${MISSKEY_TOKEN}" ]]; then
    Msg.Err "Set MISSKEY_TOKEN variable"
    exit 1
else
    Msg.Info "Use MISSKEY_TOKEN"
fi

# Make directory
mkdir -p "${LogDir}"
