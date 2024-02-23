FROM ubuntu:20.04 AS setup_openvino

RUN apt-get update; \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
    apt-utils \
    git \
    git-lfs \
    ca-certificates \
    curl \
    unzip \
    sudo \
    openjdk-8-jdk \
    tzdata; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt/intel/repo

ARG OPENVINO_FORK="openvinotoolkit"
ARG OPENVINO_BRANCH="releases/2023/3"
ARG OV_CONTRIB_FORK="openvinotoolkit"
ARG OV_CONTRIB_BRANCH="releases/2023/3"

RUN git-lfs install; \
    git clone https://github.com/${OPENVINO_FORK}/openvino.git \
    --recurse-submodules --shallow-submodules --depth 1 -b ${OPENVINO_BRANCH} /opt/intel/repo/openvino; \
    chmod +x /opt/intel/repo/openvino/install_build_dependencies.sh; \
    /opt/intel/repo/openvino/install_build_dependencies.sh

RUN git clone https://github.com/${OV_CONTRIB_FORK}/openvino_contrib.git -b ${OV_CONTRIB_BRANCH} --depth 1; \
    git clone https://github.com/openvinotoolkit/testdata --depth 1; \
    curl -L https://services.gradle.org/distributions/gradle-7.4-bin.zip --output gradle-7.4-bin.zip; \
    unzip gradle-7.4-bin.zip -d /opt/gradle

CMD ["/bin/bash"]

# -------------------------------------------------------------------------------------------------

FROM setup_openvino AS build_openvino

WORKDIR /opt/intel/repo/openvino/build
RUN mkdir install; \
    cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_java_api=ON \
    -DENABLE_PYTHON=OFF \
    -DBUILD_arm_plugin=OFF \
    -DBUILD_nvidia_plugin=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DOPENVINO_EXTRA_MODULES="/opt/intel/repo/openvino_contrib/modules" \
    -DVERBOSE_BUILD=ON \
    -DCMAKE_INSTALL_PREFIX=install \
    -S /opt/intel/repo/openvino; \
    make "-j$(nproc)"; \
    make install

WORKDIR /opt/intel/repo/openvino_contrib/modules/java_api
SHELL ["/bin/bash", "-c"]
RUN . /opt/intel/repo/openvino/build/install/setupvars.sh; \
    /opt/gradle/gradle-7.4/bin/gradle clean build --info; \
    sudo mv build/libs /opt/intel/repo/openvino/build/install/java

WORKDIR /opt/intel/repo
CMD ["/bin/bash"]

# -------------------------------------------------------------------------------------------------

FROM ubuntu:20.04 AS openvino_java

RUN apt-get update; \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
    git \
    ca-certificates \
    curl \
    sudo \
    tzdata \
    unzip \
    openjdk-8-jdk; \
    rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV INTEL_OPENVINO_DIR=/opt/intel/openvino
ENV GRADLE_HOME=/opt/gradle
COPY --from=build_openvino /opt/intel/repo/openvino/build/install $INTEL_OPENVINO_DIR
COPY --from=build_openvino /opt/gradle $GRADLE_HOME

ENV PATH=$PATH:$JAVA_HOME/bin:$GRADLE_HOME/gradle-7.4/bin

RUN apt-get update; \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
    apt-utils \
    git \
    ca-certificates \
    curl \
    sudo \
    openjdk-8-jdk \
    tzdata; \
    rm -rf /var/lib/apt/lists/*; \
    chmod +x $INTEL_OPENVINO_DIR/install_dependencies/install_openvino_dependencies.sh; \
    $INTEL_OPENVINO_DIR/install_dependencies/install_openvino_dependencies.sh -y

WORKDIR /home
CMD ["/bin/bash"]
