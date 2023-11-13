#!/bin/bash

minikube delete

helm uninstall local-env -n argocd

helm show crds local-env > crds.yaml && kubectl delete -f crds.yaml && rm crds.yaml
