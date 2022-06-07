#!/usr/bin/env bash

# スクリプトを初期化
set -Eeu -o pipefail
RepoDir="$(cd "$(dirname "${0}")" || true;pwd)"
source "${RepoDir}/common/load.sh"

RnIntervalSec="$IntervalSec"

# Botを初期化
Msg.Info "リノートした一覧を取得しています..."
ArrayAppend ReNotedIdList < <(Misskey.Users.Notes "914cmg2g5p" | jq -r ".[].renoteId")
ArrayAppend ReNotedIdList < <(Misskey.Users.Notes "914cmg2g5p" | jq -r ".[].id")

# Start Bot
while true; do
    while read -r NoteId; do
        if Array.Includes ReNotedIdList "$NoteId"; then
            continue
        else
            Msg.Info "Renote $NoteId"
            #Misskey.Notes.Create "" renoteId="$NoteId" visibility="home" > "$LogDir/$NoteId.json"
            ReNotedIdList+=("$NoteId")
        fi
    done < <(Misskey.Notes.Search "今日も一日" | jq -r ".[].id")
    sleep "$RnIntervalSec"
done
