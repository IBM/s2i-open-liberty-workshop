## Source To Image Builder for Open Liberty Applications on OpenShift

This project contains a S2I builder image and a S2I runtime image which creates an image running Java web applications on [Open Liberty](https://openliberty.io/).

[Source-to-Image](https://github.com/openshift/source-to-image) (S2I) is a toolkit for building reproducible container images from source code. S2I produces ready-to-run images by injecting source code into a container image.

The Open Liberty builder can be used in two different environments:

* Local Docker runtime via 's2i'
* Deployment to OpenShift via 'oc new-app'

With interpreted languages like python and javascript, the runtime container is also the build container. For example, with a node.js application the 'npm install' is run to build the application and then 'npm start' is run in the same container in order to start the application.

However, with compiled languages like Java, the build and runtime processes can be separated. This will allow for slimmer runtime containers for faster application starts and less bloat in the application image.

This lab will focus on the second scenario of using a builder image along with a runtime image.

![runtime image flow](./screenshots/runtime-image-flow.png)
(source: https://github.com/openshift/source-to-image/blob/master/docs/runtime_image.md)

### Structure of this repository


### Prerequisites

The following prerequisites are needed:

* [docker](https://www.docker.com/products/docker-desktop)
* [s2i](https://github.com/openshift/source-to-image/releases)
* [A Docker Hub account](https://hub.docker.com)


### Setup

1. Clone this repository locally and navigate to the newly cloned directory.

```bash
git clone https://github.com/odrodrig/s2i-open-liberty
cd s2i-open-liberty
```

1.  To make things easier, we are going to set some environment variables that we can reuse in later commands.

**Note**: Replace *Your Username* with your actual docker hub username. If you do not have one, go [here](https://hub.docker.com) to create one.

```bash
export ROOT_FOLDER=$(pwd)
export DOCKER_USERNAME=Your username
```

1. Log in with your OpenShift Cluster

### Build the builder image
In this section we will create the first of our two S2I images. This image will be responsible for taking in our source code and building the application binary with Maven.

1. Navigate to the builder image directory
```
cd ${ROOT_FOLDER}/builder-image
```

1. Now we need to actually build our builder image.
```
docker build -t $DOCKER_USERNAME/s2i-open-liberty-builder:0.1.0 .
```

1. Push the builder image out to Docker hub.
```bash
docker push $DOCKER_USERNAME/s2i-open-liberty-builder:0.1.0
```

With that done, we can now build our runtime image.

### Build the runtime image
In this section we will create the second of our two S2I images. This image will be responsible for taking the compiled binary from the builder image and serving it with the Open Liberty application server.

1. Navigate to the runtime image directory

```
cd $ROOT_FOLDER/runtime-image
```

1. Build the runtime image
```
docker build -t $DOCKER_USERNAME/s2i-open-liberty:0.1.0 .
```

1. Push the runtime image to Docker hub.

```bash
docker push $DOCKER_USERNAME/s2i-open-liberty:0.1.0
```

Now we are ready to build our application with S2I.

### Use S2I to build the application container
In this section, we will use S2I to build our application container image and then we will run the image locally using Docker.

1. Use the builder image and runtime image to build the application image

```
cd $ROOT_FOLDER/sample
```

1. Run a multistage S2I build to build the application.

```
s2i build . $DOCKER_USERNAME/s2i-open-liberty-builder:0.1.0 authors --runtime-image $DOCKER_USERNAME/s2i-open-liberty:0.1.0 -a /tmp/src/target -a /tmp/src/server.xml
```

Let's break down the above command:
 - s2i build . - Use s2i to build the current directory
 - $DOCKER_USERNAME/s2i-open-liberty-builder:0.1.0 - This is the image used to build the application
 - authors - name of our deployed application
 - --runtime-image $DOCKER_USERNAME/s2i-open-liberty:0.1.0 - Take the output of the builder image and run it in this container.
 - -a /tmp/src/target -a /tmp/src/server.xml - This is where the builder output is located

2. Run the newly built application

```
docker run -it --rm -p 9080:9080 authors
```

Open up your browser and navigate to [http://localhost:9080/openapi/ui](http://localhost:9080/openapi/ui) to view your deployed microservice.

### Deployment to OpenShift
Now that we have the application running locally and have verified that it works, let's deploy it to an OpenShift environment.

1. In order to deploy to OpenShift, we need to push our images to your cluster's internal registry. Run the following commands to authenticate with your OpenShift image registry.

```bash
oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge

export HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')

docker login -u $(oc whoami) -p $(oc whoami -t) $HOST
```

1. Now that we are authenticated with our docker registry on OpenShift, let's push the images. The following commands will: get the route to the docker registry and save it, tag our images with the copied route, and finally push the images:

```bash
oc get routes -n openshift-image-registry
```

1. For this command, you will need to copy the route from the previous command and place it below:

```bash
export REGISTRY="Enter route here"
```

Now we can deploy our application to OpenShift, however, there are two ways of doing that:

- You can manually create a *deployment.yaml* file and reference the newly built container image. Then you could apply the file and create a kubernetes deployment.
- You can use the `oc new-app` command to create build configs and deployment config.

Both ways are very similar, the main difference being that with build and deployment configs we can set triggers to automatically build the application when a new image tag has been pushed to the internal registry.



#### Method 1: Deploying as a traditional Kubernetes deployment
For this method, we will deploy our application by creating a kubernetes deployment along with a service and a route.

1. Tag the image that was created in the previous section.

```bash
docker tag authors $REGISTRY/default/authors:0.1.0
```

2. Push the image that we built locally using s2i to the OpenShift image registry.

```bash
docker push $REGISTRY/default/authors:0.1.0
```

3. Apply the `application.yaml` file using the `oc` cli to create our deployment, service, and route.

```bash

```



#### Method 2: Deploying via oc new-app and deployment configs
For this lab, we will be exploring the second option of using the `oc new-app` command.

1. Tag the images for OpenShift registry.

```bash
docker tag $DOCKER_USERNAME/s2i-open-liberty-builder:0.1.0 $REGISTRY/default/s2i-open-liberty-builders:0.1.0

docker tag $DOCKER_USERNAME/s2i-open-liberty:0.1.0 $REGISTRY/default/s2i-open-liberty:0.1.0
```

1. Push the images to the registry.

```bash
docker push $REGISTRY/default/s2i-open-liberty-builder:0.1.0

docker push $REGISTRY/default/s2i-open-liberty:0.1.0
```

1. We are almost ready to deploy our application but first we need to create an application template that contains all the components of our application. The template that we are applying here will create 2 build configs (builder and runtime iamges), a deploymentConfig to manage our application pods, a service, and a route.

```bash
oc apply -f template.yaml
```

1. Lastly, we can use the `oc` cli to deploy the application while using the template that was just applied.

```bash
oc new-app --template open-liberty-app -p SOURCE_REPOSITORY_URL=https://github.com/odrodrig/s2i-open-liberty
```
