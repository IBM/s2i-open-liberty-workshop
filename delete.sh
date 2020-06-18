#! /bin/bash

oc delete imagestream authors-builder
oc delete imagestream authors-runtime
oc delete imagestream s2i-open-liberty-builder
oc delete imagestream s2i-open-liberty
oc delete buildconfig open-liberty-builder
oc delete buildconfig open-liberty-app
oc delete deploymentconfigs authors2
oc delete service authors2
oc delete route authors2
oc delete -f ./buildTemplate.yaml
oc delete -f ./runtimeTemplate.yaml
oc apply -f ./buildTemplate.yaml
oc apply -f ./runtimeTemplate.yaml