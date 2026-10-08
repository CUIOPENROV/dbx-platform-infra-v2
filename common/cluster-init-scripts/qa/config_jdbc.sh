cots_hms_version="2.3.9"
cots_region=${AWS_REGION}
cots_jdbc_vault=${JDBC_VAULT}
cots_jdbc_role=${cots_jdbc_role}
cots_jdbc_user=${JDBC_USER}
cots_jdbc_pass=${JDBC_PASS}
cots_jdbc_url="\"${JDBC_URL}\""
cots_jdbc_header=${cots_jdbc_header}
#### Move to TF Var

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
        echo "config_jdbc setup: ${1:-"Unknown Error"}" 1>&2
        exit 1
    fi
}

#Logs the excution time of the function
function finish {
    duration=$[$(date +%s) - ${start}]
    execution_time=`printf "%.2f seconds" $duration`
    echo "config_jdbc setup Execution Time: $execution_time"
}
##################################
#Error Checking Functions and Variables END
##################################
#Script body
#########################
### sets the JDBC connection to the RDS ###
#########################
function config_jdbc(){
  if test -z "$cots_jdbc_vault"
  then
        error_exit "\$cots_jdbc_vault is empty, Aborting external metastore configuration"
  fi
  if test -z "$cots_jdbc_header"
  then
        error_exit "\$cots_jdbc_header is empty, Aborting external metastore configuration"
  fi
  if test -z "$cots_jdbc_role"
  then
        error_exit "\$cots_jdbc_role is empty, Aborting external metastore configuration"
  fi
  if test -z "$cots_jdbc_user"
  then
        error_exit "\$cots_jdbc_user is empty, need this to be read from vault. Aborting external metastore configuration"
  fi
  if test -z "$cots_jdbc_pass"
  then
        error_exit "\$cots_jdbc_pass is empty,, need this to be read from vault. Aborting external metastore configuration"
  fi
  ## Authenticate against vault with IAM/Chamber role

 if test -z "$hive_username"
  then
    error_exit "Read vault, but \$hive_username is empty, Aborting external metastore configuration"
  fi
  if test -z "$hive_password"
  then
        error_exit "Read vault, but \$hive_password is empty, Aborting external metastore configuration"
  fi
  DB_VERSION=$( echo $DATABRICKS_RUNTIME_VERSION | awk -F'.' '{print $1}' )
  if [[ $DB_VERSION -eq 9 ]]; then
    cots_hms_version="2.3.7"
  fi

cat << EOF > /databricks/driver/conf/00-custom-spark.conf
[driver] {
    "spark.hadoop.javax.jdo.option.ConnectionURL" = $cots_jdbc_url
    "spark.hadoop.javax.jdo.option.ConnectionUserName" = $hive_username
    "spark.hadoop.javax.jdo.option.ConnectionPassword" = $hive_password
    "spark.hadoop.javax.jdo.option.ConnectionDriverName" = "org.mariadb.jdbc.Driver"
    "spark.sql.hive.metastore.jars" = "builtin"
    "spark.sql.hive.metastore.version" = "$cots_hms_version"
    }
EOF
}

config_jdbc