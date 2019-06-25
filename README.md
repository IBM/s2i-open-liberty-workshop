## Source To Image Builder for Open Liberty Applications on OpenShift

This project contains a S2I builder image which creates an image running Java web applications on [Open Liberty](https://openliberty.io/).

[Source-to-Image](https://github.com/openshift/source-to-image) (S2I) is a toolkit for building reproducible container images from source code. S2I produces ready-to-run images by injecting source code into a container image.

The Open Liberty builder can be used in two different environments:

* OpenShift or MiniShift via 'oc new-app' and 'oc start-build'
* Local Docker runtime via 's2i'

### Setup

```
$ git clone https://github.com/nheidloff/s2i-open-liberty
$ cd s2i-open-liberty
$ ROOT_FOLDER=$(pwd)
```

The following prerequisites are needed:

* [docker](https://www.docker.com/products/docker-desktop)
* [mvn](https://maven.apache.org/install.html)
* [s2i](https://github.com/openshift/source-to-image/releases)
* [minishift](https://github.com/minishift/minishift)


### Run the sample application via S2I and Docker

```
$ cd ${ROOT_FOLDER}/sample
$ mvn package
$ s2i build . nheidloff/s2i-open-liberty authors
$ docker run -it --rm -p 9080:9080 authors
$ open http://localhost:9080/openapi/ui/
```

### Structure of the web applications

To use "s2i" or "oc new-app/oc start-build" you need two files:

* [server.xml](https://openliberty.io/docs/ref/config/serverConfiguration.html) in the root directory
* *.war file in the target directory

### Run the sample application on Minishift

First the builder image needs to be built and deployed:

```
$ cd ${ROOT_FOLDER}
$ eval $(minishift docker-env)
$ oc login -u developer -p developer
$ oc new-project cloud-native-starter
$ docker login -u developer -p $(oc whoami -t) $(minishift openshift registry)
$ docker build -t nheidloff/s2i-open-liberty .
$ docker tag nheidloff/s2i-open-liberty:latest $(minishift openshift registry)/cloud-native-starter/s2i-open-liberty:latest
$ docker push $(minishift openshift registry)/cloud-native-starter/s2i-open-liberty
```

After the builder image has been deployed, Open Liberty applications can be deployed:

```
$ cd ${ROOT_FOLDER}/sample
$ mvn package
$ oc new-app s2i-open-liberty:latest~/. --name=authors
$ oc start-build --from-dir . authors 
$ oc expose svc/authors
$ open http://authors-cloud-native-starter.$(minishift ip).nip.io/openapi/ui/
$ curl -X GET "http://authors-cloud-native-starter.$(minishift ip).nip.io/api/v1/getauthor?name=Niklas%20Heidloff" -H "accept: application/json"
```