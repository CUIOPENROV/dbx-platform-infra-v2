#!/bin/bash
set +x

isFatal=false           # Used in the Script body to flag an error as Fatal
set -o errtrace         # Enable the err trap, code will get called when an error is detected
trap error_exit $? ERR  # (Needs clarification) This takes the error from ERR and passes it into error_exit
trap finish EXIT        # Enable the EXIT trap, code will print time taken for the script
start=$(date +%s)

#Exits the init script startup if the error is fatal
function error_exit()
{
    if [[ $isFatal = true  ||  $2 = true ]]; then
        echo "install_otel setup: ${1:-"Unknown Error"}" 1>&2
        exit 1
    fi
}

# these variables should exist in the env.sh script
if test -z "$OTEL_VERSION"
then
      error_exit "\$OTEL_VERSION is empty, Aborting otel collector installation"
fi
if test -z "$OTLP_ENDPOINT"
then
      error_exit "\$OTLP_ENDPOINT is empty, Aborting otel collector installation"
fi
if test -z "$OTEL_LOG_FILE"
then
      error_exit "\$OTEL_LOG_FILE is empty, Aborting otel collector installation"
fi
if test -z "$DBX_WORKSPACE"
then
      error_exit "\$DBX_WORKSPACE is empty, Aborting otel collector installation"
fi
if test -z "$ASV"
then
      error_exit "\$ASV is empty, Aborting otel collector installation"
fi
if test -z "$DB_DRIVER_IP"
then
      error_exit "\$DB_DRIVER_IP is empty, Aborting otel collector installation"
fi
if test -z "$instanceID"
then
      error_exit "\$instanceID is empty, Aborting otel collector installation"
fi
if test -z "$METRICS"
then
      error_exit "\$METRICS is empty, Aborting otel collector installation"
fi
if test -z "$DB_INSTANCE_TYPE"
then
      error_exit "\$DB_INSTANCE_TYPE is empty, Aborting otel collector installation"
fi
if test -z "$DB_CLUSTER_NAME"
then
      error_exit "\$DB_CLUSTER_NAME is empty, Aborting otel collector installation"
fi
if test -z "$DB_CONTAINER_IP"
then
      error_exit "\$DB_CONTAINER_IP is empty, Aborting otel collector installation"
fi
if test -z "$HOST_NAME"
then
      error_exit "\$HOST_NAME is empty, Aborting otel collector installation"
fi

export OTEL_VERSION=$OTEL_VERSION
# Change this value to production OTLP ENDPOINT
export OTLP_ENDPOINT=$OTLP_ENDPOINT
export OTEL_LOG_FILE=$OTEL_LOG_FILE
export DBX_WORKSPACE=$DBX_WORKSPACE
export ASV=$ASV

echo $OTLP_ENDPOINT
echo $OTEL_LOG_FILE
echo $DBX_WORKSPACE
echo $ASV

# Define variable to hold apache spark receiver collection metrics
read -r -d '' METRICS <<- EOM
    apachespark:
      collection_interval: 30s
      endpoint: http://${DB_DRIVER_IP}:40001
EOM

function retry() {
  local n=1
  local max=5
  local delay=10
  while [[ $n -lt $max ]]; do
    "$@" && break || {
      ((n++))
      echo "Command failed. Attempt $n/$max:"
      sleep $delay;
    }
  done
}

function install_otel_collector(){
  cd /tmp
  echo "Downloading OTEL collector from artifactory"
  retry wget https://artifactory.cloud.capitalone.com/artifactory/generic-internalfacing/ASVOTELSERVICES/otelcollector-${OTEL_VERSION}  >> ${OTEL_LOG_FILE}  2>&1
  mkdir -p /opt/otel
  mv /tmp/otelcollector-${OTEL_VERSION} /opt/otel
  chmod +x /opt/otel/otelcollector-${OTEL_VERSION}
  echo "OTEL collector installation completed successfully...."
}

function configure_otel_systemd_service(){
  echo "Configuring OTEL collector service"
  cat >/etc/systemd/system/otelcollector.service <<EOL
  [Unit]
  Description=otelcollector
  After=network.target
  StartLimitIntervalSec=3000
  StartLimitBurst=100



  [Service]
  Type=simple
  ExecStart=/bin/sh -c '/opt/otel/otelcollector-${OTEL_VERSION} --config /opt/otel/config.yaml  >> ${OTEL_LOG_FILE}  2>&1'
  Restart=on-failure
  RestartSec=10s
  KillMode=mixed
  Environment=OTLP_ENDPOINT=$OTLP_ENDPOINT
  Environment=https_proxy=$PROXY
  Environment=HTTPS_PROXY=$PROXY
  Environment=http_proxy=$PROXY
  Environment=HTTP_PROXY=$PROXY
  Environment=NO_PROXY=$NO_PROXY
  Environment=no_proxy=$NO_PROXY
  Environment=BATCH_SIZE=5000
  Environment=MEMORY_LIMIT=512
  Environment=instanceID=$instanceID

  [Install]
  WantedBy=multi-user.target
EOL
  systemctl enable otelcollector
  systemctl start otelcollector
  echo "OTEL collector service started successfully..."
}



function configure_otel_collector(){
  # Set HOST_NAME to upload to NR
  HOST_NAME=`hostname -f`
  # Deploy spark metrics conditionally only on DRIVER node
  if [[ $DB_IS_DRIVER = "TRUE" ]]; then
    SPARK_METRICS=${METRICS}
    RECEIVERS="[ apachespark, hostmetrics, prometheus ]"
  else
    RECEIVERS="[ hostmetrics, prometheus ]"
  fi

  echo "Configuring OTEL config file for apachespark receiver"
  cat >/opt/otel/config.yaml <<EOL
  receivers:
    prometheus:
      config:
        scrape_configs:
          - job_name: $ASV/otel-self-metrics-collector-$DBX_WORKSPACE
            scrape_interval: 1m
            static_configs:
              - targets: ['localhost:9100']
    hostmetrics:
      collection_interval: 1m
      scrapers:
        cpu:
          metrics:
            system.cpu.logical.count:
              enabled: true
            system.cpu.physical.count:
              enabled: true
            system.cpu.utilization:
              enabled: true
        disk:
        load:
        filesystem:
          metrics:
            system.filesystem.utilization:
              enabled: true
        process:
          mute_process_exe_error: true
          metrics:
            process.cpu.utilization:
              enabled: true
            process.memory.utilization:
              enabled: true
        memory:
          metrics:
            system.memory.utilization:
              enabled: true
            system.linux.memory.available:
              enabled: true
            system.memory.limit:
              enabled: true
        network:
        paging:
          metrics:
            system.paging.utilization:
              enabled: true
    ${SPARK_METRICS}

  processors:
    batch:
      send_batch_size: 1024
      send_batch_max_size: 2048
      timeout: "1s"
    resourcedetection:
      detectors: ec2, env, system
      system:
        hostname_sources: ["os"]
        resource_attributes:
          host.id:
            enabled: true
      ec2:
        tags:
          - ^Name$
          - ^ASV$
          - ^OwnerContact$
          - ^Environment$
          - ^Component$
          - ^Fleet$
          - ^Cluster$
    resource:
      attributes:
        # Change the attribute value to the local workspace where the script is being deployed
        - key: e2.dbx.workspace
          value: ${DBX_WORKSPACE}
          action: upsert
        - key: e2.dbx.cloud.platform
          value: "aws_ec2"
          action: upsert
        - key: e2.dbx.ASV
          value: ${ASV}
          action: upsert
        - key: e2.dbx.clusterName
          value: ${DB_CLUSTER_NAME}
          action: upsert
        - key: e2.dbx.instanceType
          value: ${DB_INSTANCE_TYPE}
          action: upsert
        - key: e2.dbx.containerIp
          value: ${DB_CONTAINER_IP}
          action: upsert
        - key: e2.dbx.hostName
          value: ${HOST_NAME}
          action: upsert
        - key: ec2.tag.ASV
          value: ${ASV}
          action: upsert

  exporters:
    debug:
      verbosity: detailed
    otlp:
      endpoint: ${OTLP_ENDPOINT}
      tls:
        insecure_skip_verify: true

  service:
    telemetry:
      logs:
        level: "debug"
    pipelines:
      metrics:
        receivers: ${RECEIVERS}
        processors: [ resource, batch, resourcedetection]
        exporters: [ otlp ]
EOL
  cat /opt/otel/config.yaml
  echo "Configured OTEL config file for apachespark receiver successfully..."
}

# MAIN program execution, calling functions
install_otel_collector
configure_otel_collector
configure_otel_systemd_service