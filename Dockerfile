# Use lightweight JDK base image
FROM eclipse-temurin:17-jdk-alpine AS nexus-base

# Install glibc from sgerrand for compatibility
ENV GLIBC_VERSION=2.35-r1

RUN apk add --no-cache curl ca-certificates tar && \
    curl -Lo /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
    curl -Lo /glibc.apk https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk && \
    apk add --no-cache /glibc.apk && \
    rm -f /glibc.apk

# Download and extract Nexus
ENV NEXUS_VERSION=3.81.1-01
ENV NEXUS_HOME=/opt/nexus
ENV NEXUS_DATA=/nexus-data
ENV PATH=$NEXUS_HOME/bin:$PATH

# Copy all the split parts
COPY nexus3-part.* /tmp/

# Join parts and extract
RUN cat /tmp/nexus3-part.* > /tmp/nexus.tar.gz && \
    mkdir -p ${NEXUS_HOME} && \
    tar -xzf /tmp/nexus.tar.gz -C ${NEXUS_HOME} --strip-components=1 && \
    rm -f /tmp/nexus.tar.gz /tmp/nexus3-part.*

# Create a volume for persistent data
VOLUME ${NEXUS_DATA}
WORKDIR ${NEXUS_HOME}

# Make Nexus run as non-root user (optional)
RUN addgroup -g 200 nexus && adduser -D -u 200 -G nexus nexus
USER nexus

# Expose Nexus port
EXPOSE 8081

# Start Nexus
CMD ["bin/nexus", "run"]
