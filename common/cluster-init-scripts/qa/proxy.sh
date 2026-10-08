#! /bin/bash
set -m

set -o errtrace # Enable the err trap, code will get called when an error is detected
trap "echo ERROR: There was an error in ${FUNCNAME-COF context}, details as below" ERR

function setproxy {
    local AWS_REGION=${AWS_REGION}
    local proxy=${PROXY}
    local no_proxy=${NO_PROXY}

    export java_proxy_host=$(echo $PROXY | sed -e 's|http://||' -e 's|:[0-9]*||')
    export java_proxy_port=$(echo $PROXY | sed -e 's|.*:||')

    echo "export http_proxy=$PROXY" >> /databricks/spark/conf/spark-env.sh
    echo "export HTTP_PROXY=$PROXY" >> /databricks/spark/conf/spark-env.sh
    echo "export https_proxy=$PROXY" >> /databricks/spark/conf/spark-env.sh
    echo "export HTTPS_PROXY=$PROXY" >> /databricks/spark/conf/spark-env.sh
    echo "export no_proxy=$NO_PROXY" >> /databricks/spark/conf/spark-env.sh
    echo "export NO_PROXY=$NO_PROXY" >> /databricks/spark/conf/spark-env.sh

    java_no_proxy="localhost|127.*|[::1]|169.254.169.254|10.*|*.capitalone.com|s3.${AWS_REGION}.amazonaws.com|*.s3.${AWS_REGION}.amazonaws.com|s3-fips.${AWS_REGION}.amazonaws.com|*.s3-fips.${AWS_REGION}.amazonaws.com"

    echo "export _JAVA_OPTIONS=\"-Dhttps.proxyHost=${java_proxy_host} -Dhttp.proxyHost=${java_proxy_host} -Dhttps.proxyPort=${java_proxy_port} -Dhttp.proxyPort=${java_proxy_port} -Dhttp.nonProxyHosts=${java_no_proxy}\""  >> /databricks/spark/conf/spark-env.sh

    cat /databricks/spark/conf/spark-env.sh
}

setproxy