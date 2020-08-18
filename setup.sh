#!/bin/bash

cd $HOME

mkdir s2i

cd s2i

wget https://github.com/openshift/source-to-image/releases/download/v1.3.0/source-to-image-v1.3.0-eed2850f-linux-amd64.tar.gz

tar -zxvf source-to-image-v1.3.0-eed2850f-linux-amd64.tar.gz

cd /home/project/s2i-open-liberty-workshop