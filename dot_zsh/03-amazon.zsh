# Amazon Specific Configuration
export PATH=/apollo/env/envImprovement/bin:$PATH
export PATH="$HOME/.toolbox/bin:$PATH"
export PATH="/usr/local/bin:$PATH"



function amzn_auth() {
    # TODO check for unlock status

    AMZN_PASS="$(bw get password "Amazon Login")"
    AMZN_PIN="$(bw get item "8008c105-dcf8-493d-aa76-af3801208364" | jq -r '.fields[] | select(.name == "Pin") | .value')"

    #TODO feed input to kinit and mwvalidate

}


function kinit_renew() { 
    echo "renewing Kinit" ; kinit -f -l 7d -r 30d; 
}

function run_ssh_agent() {
 if ps -p $SSH_AGENT_PID > /dev/null 2>&1
 then
   echo "ssh-agent is already running"
   # Do something knowing the pid exists, i.e. the process with $PID is running
 else
   eval `ssh-agent -s`
 fi
}

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

function amzn_renew() {
    echo "checking for Kinit status"
    # klist -a | grep -i renew
    # run kinit_renew when logging in if no kerberos ticket
    if ! klist -s; then kinit_renew; else echo "Kinit authenticated" ; fi
    mwinit_validate
}


# Request weekly expiration with 30 day renewal, although the
# server only gives out 10 hour expiration with 7 day renewal.
# echo "checking for Kinit status"
# klist -a | grep -i renew
# # run kinit_renew when logging in if no kerberos ticket
# if ! klist -s; then kinit_renew;else echo "Kinit authenticated" ; fi
# mwinit_validate
