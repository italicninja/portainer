#!/bin/bash
# Script to check which Workshop mods are available on Steam

MODS="2875848298 2625625421 2714198296 2866258937 2972289937 3618557184 3413150945 3330403100 2940354599 3564950449 3624308198 3429294706 3490188370 3508537032 3437629766 3617854007 2840805724 3110911330 3615459796 3433203442 3543229299 3638469608 2286124931 3539876164 3610677934 3465040406 3461263912 3395171770 3390174394 3623247107 2909035179 3627539752 3623609320 3430172149 3450258411"

echo "Checking Steam Workshop mods..."
echo ""

FAILED_MODS="2950902979 2684285534 2714198296"

for mod in $MODS; do
    if echo "$FAILED_MODS" | grep -q "$mod"; then
        echo "❌ $mod - KNOWN FAILED"
    else
        # Check if mod exists on Steam Workshop
        response=$(curl -s -o /dev/null -w "%{http_code}" "https://steamcommunity.com/sharedfiles/filedetails/?id=$mod")
        if [ "$response" = "200" ]; then
            echo "✅ $mod - Available"
        else
            echo "❌ $mod - Not found (HTTP $response)"
            FAILED_MODS="$FAILED_MODS $mod"
        fi
    fi
    sleep 0.5
done

echo ""
echo "Failed mods to remove:"
echo "$FAILED_MODS" | tr ' ' '\n' | sort -u | grep -v '^$'
