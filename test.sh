#!/usr/bin/env bash

# スクリプトを初期化
set -Eeu -o pipefail
RepoDir="$(cd "$(dirname "${0}")" || true;pwd)"
source "${RepoDir}/common/load.sh"

Misskey.Users.Notes "914cmg2g5p"
