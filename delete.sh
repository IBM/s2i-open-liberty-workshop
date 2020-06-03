#! /bin/bash

oc delete imagestream authors-builder
oc delete imagestream authors-runtime
oc delete buildconfig open-liberty-builder
oc delete buildconfig open-liberty-app
oc delete deploymentconfigs authors-2
oc delete service authors2
oc delete route authors2
oc delete -f ./template.yaml
oc apply -f ./template.yaml