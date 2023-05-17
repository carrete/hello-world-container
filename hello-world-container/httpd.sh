#!/usr/bin/env bash
# -*- coding: utf-8; mode: sh -*-
set -euo pipefail
IFS=$'\n\t'

THIS="$(readlink -f "$0")"
readonly THIS

function on_exit() {
    errcode="$1"
}

trap 'on_exit $?' EXIT

function on_error() {
    errcode=$1
    linenum=$2
    echo 1>&2 "[ERROR] $THIS: errcode: $errcode linenum: $linenum"
}

trap 'on_error $? $LINENO' ERR

if ! command -v nc > /dev/null; then
    # shellcheck disable=SC2016
    echo 1>&2 'The command `nc` does not exist in PATH'
    exit 1
fi

if [[ -z ${PORT:-} ]]; then
    # shellcheck disable=SC2016
    echo 1>&2 'The environment variable `PORT` is undefined'
    exit 1
fi

echo "Listening on PORT=$PORT..."

function respond() {
echo -n "HTTP/1.1 200 OK
Date: $(date -u '+%a, %d %b %Y %H:%M:%S GMT')
Content-Length: 13
Content-Type: text/plain

Hello, World!"
}

while true; do
    respond | nc -l "$PORT"
done
