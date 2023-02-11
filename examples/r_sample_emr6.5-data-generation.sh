
#!/bin/bash
# SPDX-FileCopyrightText: Copyright 2021 Amazon.com, Inc. or its affiliates.
# SPDX-License-Identifier: MIT-0

# set EMR virtual cluster name
# export EMRCLUSTER_NAME=emr-on-eks-nvme    
# export AWS_REGION=us-east-1
export ACCOUNTID=$(aws sts get-caller-identity --query Account --output text)                    
export VIRTUAL_CLUSTER_ID=$(aws emr-containers list-virtual-clusters --query "virtualClusters[?name == '$EMR_VIRTUAL_CLUSTER_NAME' && state == 'RUNNING'].id" --output text)
# export EMR_ROLE_ARN=arn:aws:iam::$ACCOUNTID:role/${EMR_VIRTUAL_CLUSTER_NAME}-execution-role
export EMR_ROLE_ARN=arn:aws:iam::$ACCOUNTID:role/EMRContainers-JobExecutionRole
# export S3BUCKET=$EMRCLUSTER_NAME-$ACCOUNTID-$AWS_REGION
export S3BUCKET=emr-eks-${ACCOUNT_ID}-${AWS_REGION}
export ECR_URL="$ACCOUNTID.dkr.ecr.$AWS_REGION.amazonaws.com"

echo $ACCOUNTID $VIRTUAL_CLUSTER_ID $EMR_ROLE_ARN $S3BUCKET $ECR_URL

aws emr-containers start-job-run \
--virtual-cluster-id $VIRTUAL_CLUSTER_ID \
--name tpcds-benchmark-datagen-3t \
--execution-role-arn $EMR_ROLE_ARN \
--release-label emr-6.5.0-latest \
--job-driver '{
  "sparkSubmitJobDriver": {
      "entryPoint": "local:///usr/lib/spark/examples/jars/eks-spark-benchmark-assembly-1.0.jar",
      "entryPointArguments":["s3://'$S3BUCKET'/TPCDS-TEST/3T-partitioned","/opt/tpcds-kit/tools","parquet","3000","200","true","true","true"],
      "sparkSubmitParameters": "--class com.amazonaws.eks.tpcds.DataGeneration --conf spark.driver.cores=10 --conf spark.driver.memory=10G  --conf spark.executor.cores=11 --conf spark.executor.memory=15G --conf spark.executor.instances=26"}}' \
--configuration-overrides '{
    "applicationConfiguration": [
      {
        "classification": "spark-defaults", 
        "properties": {
          "spark.kubernetes.container.image": "'$ECR_URL'/eks-spark-benchmark:emr6.5",
          "spark.kubernetes.driver.podTemplateFile": "s3://'$S3BUCKET'/code/emr-on-eks-benchmark/examples/pod-template/driver-pod-template.yaml",
          "spark.kubernetes.executor.podTemplateFile": "s3://'$S3BUCKET'/code/emr-on-eks-benchmark/examples/pod-template/executor-pod-template.yaml",

          "spark.network.timeout": "2000s",
          "spark.executor.heartbeatInterval": "300s",
          "spark.sql.files.maxRecordsPerFile": "30000000",
          "spark.kubernetes.driver.limit.cores": "10.1",
          "spark.kubernetes.executor.limit.cores": "11.1",
          "spark.kubernetes.memoryOverheadFactor": "0.3",
              
          "spark.kubernetes.executor.podNamePrefix": "emr-eks-tpcds-generate-data",
          "spark.serializer": "org.apache.spark.serializer.KryoSerializer",
          "spark.executor.defaultJavaOptions": "-verbose:gc -XX:+UseG1GC",
          "spark.driver.defaultJavaOptions": "-XX:+UseG1GC"
        }}
    ], 
    "monitoringConfiguration": {
      "s3MonitoringConfiguration": {"logUri": "s3://'$S3BUCKET'/elasticmapreduce/emr-containers"}}}'