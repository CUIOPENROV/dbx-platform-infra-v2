##################################
#Error Checking Functions and Variables START
##################################
isFatal=true            # Used in the Script body to flag an error as Fatal
set -o errtrace         # Enable the err trap, code will get called when an error is detected
trap error_exit $? ERR  # (Needs clarification) This takes the error from ERR and passes it into error_exit
trap finish EXIT        # Enable the EXIT trap, code will print time taken for the script
start=$(date +%s)

#Exits the init script startup if the error is fatal
function error_exit()
{
    if [[ $isFatal = true  ||  $2 = true ]]; then
        echo "artifactory repo setup: ${1:-"Unknown Error"}" 1>&2
        exit 1
    fi
}

#Logs the excution time of the function
function finish {
    duration=$[$(date +%s) - ${start}]
    execution_time=`printf "%.2f seconds" $duration`
    echo "artifactory repo setup Execution Time: $execution_time"
}
##################################
#Error Checking Functions and Variables END
##################################

cat >> /etc/pip.conf <<EOL
[global]
index-url = https://artifactory.cloud.capitalone.com/artifactory/api/pypi/pypi-internalfacing/simple
EOL