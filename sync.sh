echo "Current folder: "$(pwd)
aws s3 sync ./ s3://$EMR_EKS_BUCKET/code/emr-on-eks-benchmark/