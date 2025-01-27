#!/bin/bash

script_name=$0
script_full_path=$(dirname "$0")

if ! hash jq 2>/dev/null; then
    echo "JQ must be installed" 1>&2
    exit 2
fi

if ! hash az 2>/dev/null; then
    echo "Azure CLI must be installed" 1>&2
    exit 3
fi

resourceGroup=$1
namespaceName=$2
ruleName=$3

if [ "$ruleName" == "" ]; then  
   ruleName="SendListen" 
fi

if [ "$resourceGroup" == "" ] || [ "$namespaceName" == "" ]; then
    echo "sampleenv.sh {resource-group} {namespace-name}"
    exit 1 
fi

cx1=`
az deployment group create \
    --resource-group $resourceGroup \
    --template-file $script_full_path/azuredeploy.json \
    --parameters serviceBusNamespaceName=$namespaceName \
    --name azuredeploy`
if [ $? -eq 0 ]
then
  cx=`echo $cx1 | jq ".properties.outputs.sendListenConnectionString.value"`
  if [ $? -ne 0 ] || [ "$cx" == "" ]
  then
     echo "Unable to parse or extract connection string from deployment output." >&2
     echo "$cx1" >&2
     exit 4
  fi
  echo export SB_SAMPLES_CONNECTIONSTRING="$cx"
  echo export SB_SAMPLES_QUEUENAME="BasicQueue"
  echo export SB_SAMPLES_TOPICNAME="BasicTopic"
  echo export SB_SAMPLES_SUBSCRIPTIONNAME="Subscription1"

  echo $"SB_SAMPLES_CONNECTIONSTRING="$cx"
  SB_SAMPLES_QUEUENAME="BasicQueue"
  SB_SAMPLES_TOPICNAME="BasicTopic"
  SB_SAMPLES_SUBSCRIPTIONNAME="Subscription1"" > $destfile
else
  echo "Unable to create/update Azure deployment" >&2
fi