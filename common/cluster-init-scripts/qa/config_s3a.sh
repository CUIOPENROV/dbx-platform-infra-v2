##################################
#Error Checking Functions and Variables START
##################################
isFatal=false           # Used in the Script body to flag an error as Fatal
set -o errtrace         # Enable the err trap, code will get called when an error is detected
trap error_exit $? ERR  # (Needs clarification) This takes the error from ERR and passes it into error_exit
trap finish EXIT        # Enable the EXIT trap, code will print time taken for the script
start=$(date +%s)

#Exits the init script startup if the error is fatal
function error_exit()
{
    if [[ $isFatal = true  ||  $2 = true ]]; then
        echo "s3a setup: ${1:-"Unknown Error"}" 1>&2
        exit 1
    fi
}

#Logs the excution time of the function
function finish {
    duration=$[$(date +%s) - ${start}]
    execution_time=`printf "%.2f seconds" $duration`
    echo "s3a setup Execution Time: $execution_time"
}
##################################
#Error Checking Functions and Variables END
##################################
#Script body
#########################
### sets s3a protocol handling optimizations ###
#########################
function config_s3a(){
    echo -e '[driver]."spark.hadoop.fs.s3a.canned.acl" = "BucketOwnerFullControl"
[driver]."spark.hadoop.fs.s3a.acl.default" = "BucketOwnerFullControl"
[driver]."spark.hadoop.fs.s3a.server-side-encryption-algorithm" = "AES256"
[driver]."spark.hadoop.fs.s3a.impl" = "com.databricks.s3a.TalosS3AFileSystem"
[driver]."spark.hadoop.fs.s3a.endpoint" = "s3.amazonaws.com"' > /databricks/common/conf/s3fs.conf
}
config_s3a