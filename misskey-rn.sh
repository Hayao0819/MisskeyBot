#!/usr/bin/env bash
set -Eeu -o pipefail
RepoDir="$(cd "$(dirname "${0}")" || true;pwd)"
cd "$RepoDir"

# Load config and library
source "${RepoDir}/load.sh"

# RenoteBotの設定
RnIntervalSec="$IntervalSec"
RenotedDbPath="${RepoDir}/renoted.db"

Prepare_Db(){

    Sqlite3.Connect "$RenotedDbPath"
    if ! Sqlite3.ExistTable "renoted"; then
        Sqlite3.Create "renoted" "id string primary key"
    fi
}

Prepare_RenotedList(){
    local ReNotedIdList=() Id

    Msg.Info "リノートした一覧を取得しています..."
    ArrayAppend ReNotedIdList < <(Misskey.Users.Notes "" limit=100 | jq -r ".[].renoteId")
    ArrayAppend ReNotedIdList < <(Misskey.Users.Notes "" limit=100 | jq -r ".[].id")

    for Id in "${ReNotedIdList[@]}"; do
        echo "$Id"
        if ! Sqlite3.ExistField "renoted" "id" "$Id"; then
            Sqlite3.Insert "renoted" "$Id"
        fi
    done
}

# Start Bot
Main(){
    while true; do
        while read -r NoteId; do
            #if Array.Includes ReNotedIdList "$NoteId"; then
            if Sqlite3.ExistField "renoted" "id" "$NoteId"; then
                continue
            else
                if Misskey.Notes.Create "" renoteId="$NoteId" visibility="home" > "$LogDir/$NoteId.json"; then
                    Msg.Info "Renote $NoteId"
                    Sqlite3.Insert "renoted" "$NoteId"
                fi
            fi
        done < <(Misskey.Notes.Search "今日も一日" | jq -r ".[].id")
        sleep "$RnIntervalSec"
    done
}


Prepare_Db
#Prepare_RenotedList
Main

