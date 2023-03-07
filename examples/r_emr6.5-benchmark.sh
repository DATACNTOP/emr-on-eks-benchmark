#!/bin/bash
# SPDX-FileCopyrightText: Copyright 2021 Amazon.com, Inc. or its affiliates.
# SPDX-License-Identifier: MIT-0   

# export EMRCLUSTER_NAME=emr-on-eks-nvme    
# export AWS_REGION=us-east-1
export ACCOUNTID=$(aws sts get-caller-identity --query Account --output text)                    
export VIRTUAL_CLUSTER_ID=$(aws emr-containers list-virtual-clusters --query "virtualClusters[?name == '$EMR_VIRTUAL_CLUSTER_NAME' && state == 'RUNNING'].id" --output text)
# export EMR_ROLE_ARN=arn:aws:iam::$ACCOUNTID:role/$EMRCLUSTER_NAME-execution-role
# export S3BUCKET=$EMRCLUSTER_NAME-$ACCOUNTID-$AWS_REGION
# export EMR_ROLE_ARN=arn:aws:iam::$ACCOUNTID:role/EMRContainers-JobExecutionRole
export EMR_ROLE_ARN=$EMR_EKS_EXECUTION_ARN
export S3BUCKET=$EMR_EKS_BUCKET
export ECR_URL="$ACCOUNTID.dkr.ecr.$AWS_REGION.amazonaws.com"

CW_LOG_GROUP="/emr-on-eks-logs/${EMR_VIRTUAL_CLUSTER_NAME}" # Create CW Log group if not exist

iterations=1
testname=""
releaseLabel="emr-6.5.0-latest"
dynamicAllocation=false
useSpot="false"

func() {
    echo "func:"
    echo "banchmark.sh [-d true] [-j jobname] [-i iterations] [-r releaseLabel] [-s useSpot] [-t testname]"
    echo "Description:"
    echo "Take care of the parameter order"
    exit -1
}

while getopts 'd:j:i:r:s:t:z' flag
do
    case "${flag}" in
        d) dynamicAllocation="${OPTARG}" ;;
        j) jobname="${OPTARG}" ;;
        i) iterations=${OPTARG} ;;
        r) releaseLabel=${OPTARG} ;;
        s) useSpot=${OPTARG} ;;
        t) testname="${OPTARG}" ;;
        z) ;;
        ?) func ;;
    esac
done


jobname="tpcds-benchmark-emr-eks-3t-"$testname
podNamePrefix=$(echo "$jobname" | awk '{print tolower($0)}')

echo "EMRJobName: $jobname";
echo "TestName: $testname";
echo "Iterations: $iterations";
echo "EMRReleaseLable: $releaseLabel";
echo "DynamicAllocation: $dynamicAllocation";
echo "PodNamePrefix: $podNamePrefix";
echo "UseSpot: $useSpot";
echo "ExecutionRoleArn: $EMR_ROLE_ARN";
echo "VirtualClusterId: $VIRTUAL_CLUSTER_ID";

if [ "$testname"  ]
then
   testname="-$testname"
fi

executorPodTemplateFile="s3://$S3BUCKET/code/emr-on-eks-benchmark/examples/pod-template/r_executor-pod-template.yaml"

if [ "$useSpot" == "true" ]
then
   executorPodTemplateFile="s3://$S3BUCKET/code/emr-on-eks-benchmark/examples/pod-template/r_executor-pod-template-spot.yaml"
fi

echo "ExecutorPodTemplateFile: $executorPodTemplateFile";

EXCUTOR_CORE=4
EXECUTOR_MEMORY="6g"
EXECUTOR_NUMBER=47

echo "spark.executor.cores: $EXCUTOR_CORE";
echo "spark.executor.memory: $EXECUTOR_MEMORY";
echo "spark.executor.instances: $EXECUTOR_NUMBER";

#https://spark.apache.org/docs/latest/configuration.html

aws emr-containers start-job-run \
--virtual-cluster-id $VIRTUAL_CLUSTER_ID \
--name $jobname \
--execution-role-arn $EMR_ROLE_ARN \
--release-label $releaseLabel \
--job-driver '{
  "sparkSubmitJobDriver": {
      "entryPoint": "local:///usr/lib/spark/examples/jars/eks-spark-benchmark-assembly-1.0.jar",
      "entryPointArguments":["s3://'$S3BUCKET'/benchmark/TPC-DS/3T-partitioned","s3://'$S3BUCKET'/benchmark/TPC-DS/result/emr-on-eks/3T'$testname'","/opt/tpcds-kit/tools","parquet","3000","'$iterations'","false","q1-v2.4,q10-v2.4,q11-v2.4,q12-v2.4,q13-v2.4,q14a-v2.4,q14b-v2.4,q15-v2.4,q16-v2.4,q17-v2.4,q18-v2.4,q19-v2.4,q2-v2.4,q20-v2.4,q21-v2.4,q22-v2.4,q23a-v2.4,q23b-v2.4,q24a-v2.4,q24b-v2.4,q25-v2.4,q26-v2.4,q27-v2.4,q28-v2.4,q29-v2.4,q3-v2.4,q30-v2.4,q31-v2.4,q32-v2.4,q33-v2.4,q34-v2.4,q35-v2.4,q36-v2.4,q37-v2.4,q38-v2.4,q39a-v2.4,q39b-v2.4,q4-v2.4,q40-v2.4,q41-v2.4,q42-v2.4,q43-v2.4,q44-v2.4,q45-v2.4,q46-v2.4,q47-v2.4,q48-v2.4,q49-v2.4,q5-v2.4,q50-v2.4,q51-v2.4,q52-v2.4,q53-v2.4,q54-v2.4,q55-v2.4,q56-v2.4,q57-v2.4,q58-v2.4,q59-v2.4,q6-v2.4,q60-v2.4,q61-v2.4,q62-v2.4,q63-v2.4,q64-v2.4,q65-v2.4,q66-v2.4,q67-v2.4,q68-v2.4,q69-v2.4,q7-v2.4,q70-v2.4,q71-v2.4,q72-v2.4,q73-v2.4,q74-v2.4,q75-v2.4,q76-v2.4,q77-v2.4,q78-v2.4,q79-v2.4,q8-v2.4,q80-v2.4,q81-v2.4,q82-v2.4,q83-v2.4,q84-v2.4,q85-v2.4,q86-v2.4,q87-v2.4,q88-v2.4,q89-v2.4,q9-v2.4,q90-v2.4,q91-v2.4,q92-v2.4,q93-v2.4,q94-v2.4,q95-v2.4,q96-v2.4,q97-v2.4,q98-v2.4,q99-v2.4,ss_max-v2.4","true"],
      "sparkSubmitParameters": "--class com.amazonaws.eks.tpcds.BenchmarkSQL --conf spark.driver.cores=4 --conf spark.driver.memory=5g --conf spark.executor.cores=4 --conf spark.executor.memory=6g --conf spark.executor.instances=47"}}' \
--configuration-overrides '{
    "applicationConfiguration": [
      {
        "classification": "spark-defaults", 
        "properties": {
          "spark.kubernetes.container.image": "'$ECR_URL'/eks-spark-benchmark:emr6.5",
          "spark.kubernetes.driver.podTemplateFile": "s3://'$S3BUCKET'/code/emr-on-eks-benchmark/examples/pod-template/r_driver-pod-template.yaml",
          "spark.kubernetes.executor.podTemplateFile": "'$executorPodTemplateFile'",
          "spark.dynamicAllocation.enabled": "'$dynamicAllocation'",
          "spark.shuffle.service.enabled": "'$dynamicAllocation'",
          "spark.network.timeout": "120s",
          "spark.executor.heartbeatInterval": "60s",
          "spark.kubernetes.executor.limit.cores": "4.3",
          "spark.kubernetes.driver.limit.cores": "4.1",
          "spark.driver.memoryOverhead": "1000",
          "spark.executor.memoryOverhead": "2G",
          "spark.kubernetes.executor.podNamePrefix": "'"$podNamePrefix"'",
          "spark.executor.defaultJavaOptions": "-verbose:gc -XX:+UseParallelGC -XX:InitiatingHeapOccupancyPercent=70",
          "spark.decommission.enabled": "true",
          "spark.storage.decommission.rddBlocks.enabled": "true",
          "spark.storage.decommission.shuffleBlocks.enabled" : "true",
          "spark.storage.decommission.enabled": "true",
          "spark.storage.decommission.fallbackStorage.path": "s3://'$S3BUCKET'/benchmark/fallback/"          
         }}
    ],
        "monitoringConfiguration": {
          "persistentAppUI":"ENABLED",
          "cloudWatchMonitoringConfiguration": {
            "logGroupName":"'"$CW_LOG_GROUP"'",
            "logStreamNamePrefix":"'"$jobname"'"
        }
      }
    }'