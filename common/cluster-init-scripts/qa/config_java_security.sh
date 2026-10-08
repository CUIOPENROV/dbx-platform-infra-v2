##################################
#Error Checking Functions and Variables START
##################################
isFatal=true           # Used in the Script body to flag an error as Fatal
set -o errtrace         # Enable the err trap, code will get called when an error is detected
trap error_exit $? ERR  # (Needs clarification) This takes the error from ERR and passes it into error_exit
trap finish EXIT        # Enable the EXIT trap, code will print time taken for the script
start=$(date +%s)

#Exits the init script startup if the error is fatal
function error_exit()
{
    if [[ $isFatal = true  ||  $2 = true ]]; then
        echo "java security setup: ${1:-"Unknown Error"}" 1>&2
        exit 1
    fi
}

#Logs the excution time of the function
function finish {
    duration=$[$(date +%s) - ${start}]
    execution_time=`printf "%.2f seconds" $duration`
    echo "java security setup Execution Time: $execution_time"
}
##################################
#Error Checking Functions and Variables END
##################################
#Script body
#########################
### Update java, remove non permitted ciphers ###
#########################
function config_java_security(){
    cp /databricks/spark/dbconf/java/extra.security /databricks/spark/dbconf/java/extra_v1.security
    sed -i 's/, GCM//g' /databricks/spark/dbconf/java/extra_v1.security
    sed '2s/$/, ECDHE-RSA-AES128-SHA256/' /databricks/spark/dbconf/java/extra_v1.security > /databricks/spark/dbconf/java/extra_v2.security
    mv /databricks/spark/dbconf/java/extra.security /databricks/spark/dbconf/java/extra.security.backup
    mv /databricks/spark/dbconf/java/extra_v2.security /databricks/spark/dbconf/java/extra.security
    rm /databricks/spark/dbconf/java/extra_v1.security
    rm /databricks/spark/dbconf/java/extra.security.backup
    chmod 755 /databricks/spark/dbconf/java/extra.security
}
config_java_security