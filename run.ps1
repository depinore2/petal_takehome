function Initialize-Remotebucket([string]$region = 'us-west-2', [string]$bucketName = 'petal_takehome_tfstate') {
    if(!(aws s3 ls | grep $bucketName)) {
        Write-Host "Creating a new S3 bucket [$bucketName] to store terraform state in..."
        aws s3 mb "s3://$bucketName" --region $region;

        # we definitely want versioning
        aws s3api put-bucket-versioning --bucket $bucketName --versioning-configuration MFADelete=Disabled,Status=Enabled

        # and we also want to lock it down so that this bucket is not publicly-accessible.
        aws s3api put-public-access-block --bucket $bucketName --public-access-block-configuration BlockPublicAcls=true,IgnorePublicPolicy=True,RestrictPublicBuckets=true
    }
    else {
        Write-Host "S3 Bucket [$bucketName] already exists; skipping creation..."
    }
}

aws configure;
Initialize-RemoteBucket;
