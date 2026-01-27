#!/bin/bash
set -xe # Exit immediately if a command fails, and print commands as they are executed
# exec > /var/log/adhoc_script.log 2>&1 # Log all output to a file

while true; do
    duration=$((RANDOM % 120 + 60))   # 1–3 minutes
    delay=$(awk -v min=0.1 -v max=1 'BEGIN{srand(); print min+rand()*(max-min)}')

    echo "High load for $duration sec (delay $delay)"
    end=$((SECONDS+duration))
    while [ $SECONDS -lt $end ]; do
        curl -s http://app.internal:5000/payment > /dev/null &
        sleep $delay
    done

    duration=$((RANDOM % 180 + 60))   # 1–4 minutes
    delay=$(awk -v min=1 -v max=3 'BEGIN{srand(); print min+rand()*(max-min)}')

    echo "Low load for $duration sec (delay $delay)"
    end=$((SECONDS+duration))
    while [ $SECONDS -lt $end ]; do
        curl -s http://app.internal:5000/payment > /dev/null &
        sleep $delay
    done
done
