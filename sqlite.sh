#!/usr/bin/env bash
Sqlite3.Call(){
    echo  sqlite3 "$SQLITE3_DBPATH" "$@" >&2
    sqlite3 "${SQLITE3_OPTIONS[@]}" "$SQLITE3_DBPATH" "$@"
}

Sqlite3.Connect(){
    export SQLITE3_DBPATH="$1"
    #sqlite3 "$SQLITE3_DBPATH"
    echo ".open \"$SQLITE3_DBPATH\"" | sqlite3
    return 0
}

Sqlite3.CurrentDb(){
    if [[ -z "${SQLITE3_DBPATH-""}" ]]; then
        Msg.Err "No datebase is connected."
        return 1
    fi
    echo "${SQLITE3_DBPATH}"
    return 0
}


# Insert <table name> <Value1> <Value2>
Sqlite3.Insert(){
    local _table="$1" _args=()
    shift 1 || return 1
    local _values=("$@")

    _args+=(insert into "$_table" values '(')
    ForEach eval "_args+=(\"\\\"{}\\\"\" ,)" < <(PrintEvalArray _values)
    Array.Pop _args
    _args+=(");")

    Sqlite3.Call "${_args[*]}"
}


# Select <table name> <Column1> 
Sqlite3.Select(){
    local _table="$1" _args=()
    shift 1 || return 1
    local _values=("$@")

    _args+=(select)
    ForEach eval "_args+=(\"\\\"{}\\\"\" ,)" < <(PrintEvalArray _values)
    Array.Pop _args
    _args+=("from" "$_table" ";")

    Sqlite3.Call "${_args[*]}"
}

Sqlite3.SelectAll(){
    local _table="$1" _args=()
    shift 1 || return 1
    Sqlite3.Call "select * from $_table"
}

Sqlite3.Delete(){
    local _table="$1" _args=()
    shift 1 || return 1
    if (( $# < 1 )) && (( ${SQLITE3_ALLOWDELETEALL-"0"} != 1 )); then
        Msg.Err "Cannot delete all data.\nIf you really want that, Please set environment-variable \"SQLITE3_ALLOWDELETEALL=1\""
        return 1
    fi
    _args+=(delete from "$_table")
    if (( $# > 0)); then
        _args+=(where "${@}")
    fi
    Sqlite3.Call "${_args[*]}"
}

# Sqlite3.CreateTable <table name> <column1> <column2> ...
Sqlite3.Create(){
    local _table="$1" _args=() _columns=()
    shift 1 || return 1
    _columns=("$@")
    _args+=(create table "$_table" "(")
    ForEach eval "_args+=(\"\\\"{}\\\"\" ,)" < <(PrintEvalArray _columns)
    Array.Pop _args
    _args+=(")")

    Sqlite3.Call "${_args[*]}"
}

Sqlite3.ExistTable(){
    local _result
    # 1 -> テーブルが存在
    # 0 -> テーブルなし
    _result="$(Sqlite3.Call \
                            "SELECT COUNT(*) 
                            FROM sqlite_master 
                            WHERE TYPE='table' AND name='$1';
            ")"
    if (( _result > 0 )); then
        return 0
    fi
    return 1
}

# Sqlite3.ExistField <table name> <column> <value>
Sqlite3.ExistField(){
    _result="$(Sqlite3.Call "SELECT * FROM '$1' WHERE $2 = '$3' LIMIT 1;")"
    if [[ -n "${_result-""}" ]]; then
        return 0
    fi
    return 1
}
