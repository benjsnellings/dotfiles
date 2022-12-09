function mwinit_validate() {
  echo "checking for Midway authentication"
  SSH_CERT=~/.ssh/id_rsa-cert.pub
  if (! test -f "$SSH_CERT") || (test "`find ~/.ssh/id_rsa-cert.pub -mmin +1220`"); then
    echo "Midway expired. Please re-authenticate."
    if mwinit -o ; then
      run_ssh_agent
      ssh-add -D ~/.ssh/*_rsa
      ssh-add ~/.ssh/*_rsa
    else
      echo "Failed to authenticate."
    fi
  else
    echo "Midway Authenticated "
  fi
}