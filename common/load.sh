#!/usr/bin/env bash

set -Eeu -o pipefail

RepoDir="$(cd "$(dirname "${0}/")" || true;pwd)"

# shellcheck source=/dev/null
export FSBLIB_MSG="stderr"
source /dev/stdin < <(fasbashlib -x "v0.2.3" 2> /dev/null || curl -sL "https://github.com/Hayao0819/FasBashLib/releases/download/v0.2.3/fasbashlib.sh")

# Load bot config
source "${RepoDir}/bot.conf"
source "${RepoDir}/common/api-base.sh"
source "${RepoDir}/common/api-notes.sh"
source "${RepoDir}/common/api-users.sh"

if [[ -e "${RepoDir}/.env" ]]; then
    source "${RepoDir}/.env"
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
