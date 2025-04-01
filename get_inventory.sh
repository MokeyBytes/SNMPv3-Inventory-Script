#!/bin/bash

# SNMPv3 Auth
Auth="1234567890"
Priv="1234567890"
User="snmpuser"

# Switch list file
SWITCH_LIST="allswitches.txt"

# Output header
printf "\n%-15s | %-35s | %-5s | %-8s | %-35s | %-25s | %-20s | %-10s | %s\n" \
"IP Address" "Hostname" "Idx" "Stack#" "Description" "Model" "Serial Number" "Notes"
printf -- "------------------------------------------------------------------------------------------------------------------------------------------------\n"

# Loop through each switch
while read -r SWITCH; do
    IP="$SWITCH"
    # Resolve Hostname
    HOSTNAME=$(host "$IP" | awk '/domain name pointer/ {print $5}' | sed 's/\.$//')
    [[ -z "$HOSTNAME" ]] && HOSTNAME="UNKNOWN"

    # SNMPv3 Query
    ## Get the serial numbers, models, descriptions, PHYSnames
    ## SNMP OIDs
    DESCS=$(snmpbulkwalk -v3 -l AuthPriv -a sha -A "$Auth" -x aes -X "$Priv" -u "$User" "$IP" 1.3.6.1.2.1.47.1.1.1.1.2)
    MODELS=$(snmpbulkwalk -v3 -l AuthPriv -a sha -A "$Auth" -x aes -X "$Priv" -u "$User" "$IP" 1.3.6.1.2.1.47.1.1.1.1.5)
    SERIALS=$(snmpbulkwalk -v3 -l AuthPriv -a sha -A "$Auth" -x aes -X "$Priv" -u "$User" "$IP" 1.3.6.1.2.1.47.1.1.1.1.11)
    PHYSNAMES=$(snmpbulkwalk -v3 -l AuthPriv -a sha -A "$Auth" -x aes -X "$Priv" -u "$User" "$IP" 1.3.6.1.2.1.47.1.1.1.1.7)
    # Associative Arrays to hold the data
    ## Tracks model per stack member number
    declare -A STACK_MODELS
    ## Holds the formatted output for per index
    declare -A STACK_OUTPUT

    #Iterates over every serial number entry, parsing the index to line up other SNMP data
    echo "$SERIALS" | while IFS= read -r LINE; do
        IDX=$(echo "$LINE" | grep -oP '1\.3\.6\.1\.2\.1\.47\.1\.1\.1\.1\.11\.\K\d+')
        SERIAL=$(echo "$LINE" | awk -F'STRING: ' '{print $2}')
        MODEL=$(echo "$MODELS" | grep "\.$IDX =" | awk -F'STRING: ' '{print $2}')
        DESC=$(echo "$DESCS" | grep "\.$IDX =" | awk -F'STRING: ' '{print $2}')
        PHYSNAME=$(echo "$PHYSNAMES" | grep "\.$IDX =" | awk -F'STRING: ' '{print $2}')

        # Extract Stack Member #
        if [[ "$PHYSNAME" =~ [Ss]witch[[:space:]]*([0-9]+) ]]; then
            STACKNUM="${BASH_REMATCH[1]}"
        elif [[ "$DESC" =~ [Ss]witch[[:space:]]*([0-9]+) ]]; then
            STACKNUM="${BASH_REMATCH[1]}"
        else
            STACKNUM="-"
        fi

        # Track model by stack member number
        [[ "$STACKNUM" != "-" ]] && STACK_MODELS["$STACKNUM"]="$MODEL"

        # Save output
        STACK_OUTPUT["$IDX"]=$(printf "%-15s | %-35s | %-5s | %-8s | %-35s | %-25s | %-20s | %-10s" \
            "$IP" "$HOSTNAME" "$IDX" "$STACKNUM" "$DESC" "$MODEL" "$SERIAL" )
    done

    # Determine mismatched models in stack
    UNIQUE_MODELS=$(printf "%s\n" "${STACK_MODELS[@]}" | sort -u | wc -l)
    TOTAL_STACK_MEMBERS=${#STACK_MODELS[@]}

    # Output results
    for IDX in "${!STACK_OUTPUT[@]}"; do
        STACK_FLAG=""
        if [[ "$TOTAL_STACK_MEMBERS" -gt 1 && "$UNIQUE_MODELS" -gt 1 ]]; then
            STACK_FLAG="⚠️ MISMATCH"
        fi
        echo "${STACK_OUTPUT[$IDX]} | $STACK_FLAG"
    done

    echo ""
    # Wipes the associative arrays before looping to the next switch
    unset STACK_MODELS
    unset STACK_OUTPUT
# End Loop
done < "$SWITCH_LIST"
