# Setup BitWarden for CLI access
#
function bwu() {
  bwStatusOutput="$(bw status 2>/dev/null)"
  bwStatus=$(echo "$bwStatusOutput" | jq -r '.status')
  if [ "$bwStatus" != "unlocked" ]; then
    echo "Bitwarden Vault Unlocking..."
    export BW_SESSION="$(bw unlock --raw)"
  else
    echo "Bitwarden Already Unlocked"
  fi

}
