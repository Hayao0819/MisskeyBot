#!/usr/bin/env bash

set -Eeu -o pipefail

# shellcheck source=/dev/null
source /dev/stdin < <(fasbashlib -x "v0.2.2" 2> /dev/null || curl -sL "https://github.com/Hayao0819/FasBashLib/releases/download/v0.2.2/fasbashlib.sh")

MISSKEY_TOKEN="${MISSKEY_TOKEN-""}"
RnIntervalSec="10"
LogDir="$(mktemp -d)"
MisskeyInstanceDomain="submarin.online"
APIEntryPoint="https://${MisskeyInstanceDomain}/api"

# Token check
if [[ -z "${MISSKEY_TOKEN}" ]]; then
    Msg.Err "Set MISSKEY_TOKEN variable"
    exit 1
else
    Msg.Info "Use MISSKEY_TOKEN"
fi

# MakeJson KEY=VALUE KEY=VALUE ...
MakeJson(){
    local i _Key _Value
    for i in "i=$MISSKEY_TOKEN" "$@"; do
        _Key=$(cut -d "=" -f 1 <<< "$i")
        _Value=$(cut -d "=" -f 2- <<< "$i")
        if [[ "$_Value" =~ ^[0-9]+$ ]] || [[ "$_Value" = true ]] || [[ "$_Value" = false ]]; then
            echo "{\"$_Key\": $_Value}"
        else
            echo "{\"$_Key\": \"$_Value\"}"
        fi
    done | jq -cs add
}

# SendReq URL KEY=VALUE KEY=VALUE ...
SendReq(){
    local _Url="$1" _CurlArgs=() _Json=""
    shift 1
    _CurlArgs+=(-s -L --fail-with-body) # curlのよくある設定
    _CurlArgs+=(-X POST) # MisskeyのAPIは全てPOST
    _CurlArgs+=(-H "Content-Type: application/json") # JSONで送信
    _CurlArgs+=(-d "$(MakeJson "$@")") # JSONを送信
    _CurlArgs+=("$_Url") # URL指定

    Msg.Debug "Run: ${_CurlArgs[*]//"${MISSKEY_TOKEN}"/"TOKEN"})"
    curl "${_CurlArgs[@]}"
}

# BindingBase <APIPath> <Args1> <Args2> -- "$@"
# Argsは必ずAPIのクエリと同じ文字列にしてください
# 例: BindingBase /notes/search query limit
BindingBase(){
    local _API="$1"
    shift 1

    # Parse args
    local i _APIArgs _Args
    for i in "$@"; do
        shift 1
        if [[ "$i" = "--" ]]; then
            break
        else
            _APIArgs+=("$i")
        fi
    done

    i=0
    while true; do
        i="$(( i + 1 ))"
        _Args+=("${_APIArgs[$((i-1))]}=$(eval echo "\$$i" )")
        shift 1
        if (( "$#" <= "$i" )) || [[ -z "${_APIArgs[$i]-""}" ]]; then
            break
        fi
    done

    SendReq "$APIEntryPoint/$_API" "${_Args[@]}" "$@"
}

# Misskey.Notes.Search <Query> <Limit>
Misskey.Notes.Search(){
    BindingBase "notes/search" query limit -- "$@"
}

Misskey.Notes.Renotes(){
    BindingBase "notes/renotes" noteId limit sinceId untilId -- "$@"
}

Misskey.Notes.Create(){
    BindingBase "notes/create" text -- "$@"
}

Misskey.Users.Notes(){
    BindingBase "users/notes" userId -- "$@"
}

# 初期化
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
            Misskey.Notes.Create "" renoteId="$NoteId" visibility="home" > "$LogDir/$NoteId.json"
            ReNotedIdList+=("$NoteId")
        fi
    done < <(Misskey.Notes.Search "今日も一日" | jq -r ".[].id")
    sleep "$RnIntervalSec"
done
