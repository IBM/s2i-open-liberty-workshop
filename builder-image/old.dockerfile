FROM registry.access.redhat.com/ubi8/ubi:8.1

LABEL maintainer="Oliver Rodriguez"

ENV BUILDER_VERSION="0.1.0" \
    LANG="en_US.UTF-8" \
    JAVA_HOME="/usr/java/openjdk-14" \
    PATH="/usr/java/openjdk-14/bin:$PATH" \
    JAVA_URL="https://download.java.net/java/GA/jdk14.0.1/664493ef4a6946b186ff29eb326336a2/7/GPL/openjdk-14.0.1_linux-x64_bin.tar.gz" \
    JAVA_SHA256="22ce248e0bd69f23028625bede9d1b3080935b68d011eaaf9e241f84d6b9c4cc"

LABEL io.k8s.description="Open Liberty S2I Image" \
      io.k8s.display-name="Open Liberty S2I Builder" \
      io.openshift.tags="builder,maven" \
      io.openshift.s2i.scripts-url=image:///usr/local/s2i \
      io.s2i.scripts-url=image:///usr/local/s2i \
      io.openshift.expose-services="9080/tcp:http, 9443/tcp:https" \
      io.openshift.tags=",builder,maven" \
      io.openshift.s2i.destination="/tmp"

RUN yum install -y gzip tar binutils freetype fontconfig && \
    yum clean all -y

RUN curl -fL -o /openjdk.tgz "$JAVA_URL" && \
    echo "$JAVA_SHA256 */openjdk.tgz" | sha256sum -c - && \
    mkdir -p "$JAVA_HOME" && \
    tar --extract --file /openjdk.tgz --directory "$JAVA_HOME" --strip-components 1 && \
    rm /openjdk.tgz && \
    ln -sfT "$JAVA_HOME" /usr/java/default && \
    ln -sfT "$JAVA_HOME" /usr/java/latest && \
    for bin in "$JAVA_HOME/bin/"*; do base="$(basename "$bin")"; [ ! -e "/usr/bin/$base" ]; alternatives --install "/usr/bin/$base" "$base" "$bin" 20000; done && \
    java -Xshare:dump && \
    java --version && \
    javac --version

RUN mkdir /home/default && \
    cd /home/default && \
    curl -O http://www.gtlib.gatech.edu/pub/apache/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz && \
    tar xzvf apache-maven-3.6.3-bin.tar.gz && \
    rm apache-maven-3.6.3-bin.tar.gz

ENV PATH="/home/default/apache-maven-3.6.3/bin:$PATH" \
    STI_SCRIPTS_PATH="/usr/local/s2i" \ 
    WORKDIR="/usr/local/workdir" \
    S2I_DESTINATION="/tmp" 

COPY ./s2i/bin/ /usr/local/s2i

USER 1001