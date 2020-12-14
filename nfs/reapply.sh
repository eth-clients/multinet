#!/bin/bash
#WARNING: run this from root of the project

# delete old nfs deployment
kubectl delete -f $PWD/nfs/deployment-data.yaml
kubectl delete -f $PWD/nfs/deployment-deposit.yaml
kubectl delete -f $PWD/nfs/service-data.yaml
kubectl delete -f $PWD/nfs/service-deposit.yaml

#apply new nfs deployment
kubectl apply -f $PWD/nfs/deployment-data.yaml
kubectl apply -f $PWD/nfs/deployment-deposit.yaml
kubectl apply -f $PWD/nfs/service-data.yaml
kubectl apply -f $PWD/nfs/service-deposit.yaml

