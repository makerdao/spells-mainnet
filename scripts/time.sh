#!/usr/bin/env bash
set -e

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
    ${0##*/} date="1 May 2022"
        or
    ${0##*/} stamp="1651363200"
.
    exit 1
elif [[ -z "$DATE" ]]; then
    date -u -d @"$STAMP"
    date -u -d @"$STAMP" +%s
else
    date --utc --date="$DATE"
    date --utc --date="$DATE" +%s
fi
