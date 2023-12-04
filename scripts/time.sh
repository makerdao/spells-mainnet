#!/usr/bin/env bash
set -e

SYSTEM=`uname`;
FORMAT="%Y-%m-%d %H:%M:%S";

for ARGUMENT in "$@"
do
    KEY=$(echo "$ARGUMENT" | cut -f1 -d=)
    VALUE=$(echo "$ARGUMENT" | cut -f2 -d=)

    case "$KEY" in
            date)      DATE="$VALUE" ;;
            stamp)     STAMP="$VALUE" ;;
            *)
    esac
done

if [[ -z "$STAMP" && -z "$DATE" ]]; then
cat <&2 <<.
Please use the date or stamp flag, ex:
    ${0##*/} date="2023-12-01 00:00:00"
        or
    ${0##*/} stamp="1651363200"
.
    exit 1
elif [[ -z "$DATE" ]]; then
    if [ "$SYSTEM" = "Darwin" ]; then
        date -u -r "$STAMP"
        date -u -r "$STAMP" "+$FORMAT"
    else
        date -u -d @"$STAMP"
        date -u -d @"$STAMP" +%s
    fi
else
    if [ "$SYSTEM" = "Darwin" ]; then
        date -u -j -f "$FORMAT" "$DATE"
        date -u -j -f "$FORMAT" "$DATE" +%s
    else
        date --utc --date="$DATE"
        date --utc --date="$DATE" +%s
    fi
fi
