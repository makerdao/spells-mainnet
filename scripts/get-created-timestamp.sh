#!/usr/bin/env bash
#!/usr/bin/env bash

for ARGUMENT in "$@"
do
    KEY=$(echo "$ARGUMENT" | cut -f1 -d=)
    VALUE=$(echo "$ARGUMENT" | cut -f2 -d=)

    case "$KEY" in
            tx)      TXHASH="$VALUE" ;;
            *)       TXHASH="$KEY"
    esac
done

seth block "$(seth tx "${TXHASH}"|grep blockNumber|awk '{print $2}')"|grep timestamp|awk '{print $2}'
