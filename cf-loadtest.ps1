param(
    [string]$bucket = "awsloadtesting",
    [string]$securityGroup = "sg-6d301716",
    [string]$minionArn = "arn:aws:iam::$awsId:instance-profile/$awsIamProfile" ,
    [string]$watchtowerArn = "arn:aws:iam::$awsId:instance-profile/$awsIamProfile",
    [string]$subnet = "subnet-03326f5b",
    [int]$count = 1
)


$global:privateIps = New-Object System.Collections.ArrayList
$global:instanceIds = New-Object System.Collections.ArrayList
$global:instances = $null
$global:config = @{}
$global:date = Get-Date
$MinionUserData = "file://UserData/MinionUserData.txt"
$WatchtowerUserData = "file://UserData/WatchtowerUserData.txt"
function Create-Minion-Servers ($count) 
{
    Write-Host "Creating $count Minion Server(s)"
    $minionServers = aws ec2 run-instances --image-id "ami-79dc1b14" --count $count --key-name UserDataTest --iam-instance-profile Arn="$minionArn" --instance-type t2.medium --user-data $MinionUserData --security-group-ids "$securityGroup" --subnet-id "$subnet" --associate-public-ip-address
    $minionServers = "$minionServers" | ConvertFrom-Json
    $global:instances = $minionServers.Instances

    #Tag the instances
    foreach($instance in $global:instances){
        $id = $instance.InstanceId
        aws ec2 create-tags --resources "$id"--tags 'Key=Name,Value="Minion"'
    }
}

function Create-Watchtower-Server 
{
    Write-Host "Creating Watchtower Server"
    $watchtowerServer = aws ec2 run-instances --image-id "ami-79dc1b14" --count 1 --key-name UserDataTest --iam-instance-profile Arn="$watchtowerArn" --instance-type t2.medium --user-data $WatchtowerUserData --security-group-ids "$securityGroup" --subnet-id "$subnet" --associate-public-ip-address    
    $watchtowerServer = "$watchtowerServer" | ConvertFrom-Json
    $id = $watchtowerServer.Instances[0].InstanceId
    aws ec2 create-tags --resources "$id"--tags 'Key=Name,Value="Watchtower"'
}

function Get-PrivateIps 
{
    Write-Host "Parsing Private Ips"
    foreach($instanceInfo in $global:instances)
    {
        $ip = $instanceInfo.NetworkInterfaces[0].PrivateIpAddress
        $id = $instanceInfo.InstanceId
        $global:privateIps.Add($ip) > $null
        $global:instanceIds.Add($id) > $null
    }
    $global:config.Date = "$date"
    $global:config.MinionIps = $global:privateIps
    $global:config.InstanceIds = $global:instanceIds

}

function Put-Config 
{
    Write-Host "Config put to Watchtower/Config/config.json"
    $global:config = $global:config | ConvertTo-Json
    $global:config > 'config.json'
    aws s3api put-object --bucket $bucket --key "Watchtower/Config/config.json" --body 'config.json' > $null
}

function Put-IPL-Test-Configuration($file)
{
    Write-Host "Putting $file"
    aws s3api put-object --bucket $bucket --key "Watchtower/Config/$file" --body "$file" > $null
    aws s3api put-object --bucket $bucket --key "Minions/Config/$file" --body "$file" > $null

}

function Log-Config 
{
    Write-Host "Config logged to Runs/$date/config.json"
    aws s3api put-object --bucket $bucket --key "Runs/$date/config.json" --body 'config.json' > $null
}

function Destroy 
{
    foreach($id in $global:instanceIds){
        aws ec2 terminate-instances --instance-ids $id
    }    
}

function Main 
{
   try {
        Create-Minion-Servers $count
        Get-PrivateIps
        Put-Config
        Put-IPL-Test-Configuration "TestPlan.jmx"
        Put-IPL-Test-Configuration "Problems.csv"
        Create-Watchtower-Server
        Log-Config
    } 
    catch {
        Destroy
        $exception = $_.Exception | format-list -force
        $exception > "CreateLoadTestServerException.txt"
    }

}

Main
