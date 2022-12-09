# Setup BitWarden for CLI access
#
function bwu() {
  export BW_SESSION="$(bw unlock --raw)"
}
