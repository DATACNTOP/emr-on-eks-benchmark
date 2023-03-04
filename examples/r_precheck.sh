#!/bin/bash
export VIRTUAL_CLUSTER_ID=$(aws emr-containers list-virtual-clusters --query "virtualClusters[?name == '$EMR_VIRTUAL_CLUSTER_NAME' && state == 'RUNNING'].id" --output text)
export EMR_ROLE_ARN=$EMR_EKS_EXECUTION_ARN
export S3BUCKET=$EMR_EKS_BUCKET

echo "EMR_VIRTUAL_CLUSTER_NAME: "$EMR_VIRTUAL_CLUSTER_NAME
echo "VIRTUAL_CLUSTER_ID: "$VIRTUAL_CLUSTER_ID
echo "EMR_ROLE_ARN: "$EMR_ROLE_ARN
echo "S3BUCKET: "$S3BUCKET