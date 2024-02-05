# Amazon Specific Configuration
export PATH=/apollo/env/envImprovement/bin:$PATH
export PATH="$HOME/.toolbox/bin:$PATH"
export PATH="/usr/local/bin:$PATH"



function amzn_auth() {
    # TODO check for unlock status

    # Unlock the Bitwarden VAULT
    bwu

    # Get the Amazon Passwords
    AMZN_PASS="$(bw get password "Amazon Login")"
    AMZN_PIN="$(bw get item "8008c105-dcf8-493d-aa76-af3801208364" | jq -r '.fields[] | select(.name == "Pin") | .value')"
    echo $AMZN_PASS 
    echo $AMZN_PIN


    #TODO feed input to kinit and mwvalidate
    # Probably not going to be that easy

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
  SSH_CERT=~/.ssh/id_ecdsa-cert.pub
  if (! test -f "$SSH_CERT") || (test "`find ~/.ssh/id_ecdsa-cert.pub -mmin +1220`"); then
    echo "Midway expired. Please re-authenticate."
    if mwinit -o --aea ; then
      run_ssh_agent
      ssh-add -D ~/.ssh/*_ecdsa
      ssh-add ~/.ssh/*_ecdsa
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

function ada_personal() {
   ada_output=$(ada credentials print --account 232890881194 --role Admin --provider isengard) 
   export AWS_ACCESS_KEY_ID=$(echo ${ada_output} | jq -r .AccessKeyId) 
   export AWS_SECRET_ACCESS_KEY=$(echo ${ada_output} | jq -r .SecretAccessKey) 
   export AWS_SESSION_TOKEN=$(echo ${ada_output} | jq -r .SessionToken)
}

function ada_calculator() {
   ada_output=$(ada credentials print --account 381492294813 --role Admin --provider isengard) 
   export AWS_ACCESS_KEY_ID=$(echo ${ada_output} | jq -r .AccessKeyId) 
   export AWS_SECRET_ACCESS_KEY=$(echo ${ada_output} | jq -r .SecretAccessKey) 
   export AWS_SESSION_TOKEN=$(echo ${ada_output} | jq -r .SessionToken)
}

function ada_snellin_ac_demo() {
   ada_output=$(ada credentials print --account 471112920131 --role IibsAdminAccess-DO-NOT-DELETE --provider conduit) 
}

function ada_calculator_alpha() {
   ada_output=$(ada credentials print --account 913800417489 --role Admin --provider isengard) 
   export AWS_ACCESS_KEY_ID=$(echo ${ada_output} | jq -r .AccessKeyId) 
   export AWS_SECRET_ACCESS_KEY=$(echo ${ada_output} | jq -r .SecretAccessKey) 
   export AWS_SESSION_TOKEN=$(echo ${ada_output} | jq -r .SessionToken)
}

# Request weekly expiration with 30 day renewal, although the
# server only gives out 10 hour expiration with 7 day renewal.
# echo "checking for Kinit status"
# klist -a | grep -i renew
# # run kinit_renew when logging in if no kerberos ticket
# if ! klist -s; then kinit_renew;else echo "Kinit authenticated" ; fi
# mwinit_validate
