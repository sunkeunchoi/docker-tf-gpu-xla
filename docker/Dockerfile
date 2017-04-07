FROM nvidia/cuda:8.0-cudnn6-devel

MAINTAINER Sunkeun Choi <sunkeun.choi@gmail.com>

# Set term
ENV TERM=xterm-256color

# Install Build Dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        git \
        libcurl3-dev \
        libfreetype6-dev \
        libpng12-dev \
        libzmq3-dev \
        pkg-config \
        python3-dev \
        python-dev \
        rsync \
        software-properties-common \
        unzip \
        zip \
        zlib1g-dev \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN curl -fSsL -O https://bootstrap.pypa.io/get-pip.py && \
    python3 get-pip.py && \
    rm get-pip.py

RUN pip --no-cache-dir install \
        ipykernel \
        jupyter \
        matplotlib \
        numpy \
        scipy \
        sklearn \
        pandas \
        && \
    python3 -m ipykernel.kernelspec

# Install JDK for Bazel
RUN add-apt-repository -y ppa:openjdk-r/ppa && \
    apt-get update && \
    apt-get install -y --no-install-recommends openjdk-8-jdk openjdk-8-jre-headless && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Bazel to build Tensorflow

# Running bazel inside a `docker build` command causes trouble, cf:
#   https://github.com/bazelbuild/bazel/issues/134
# The easiest solution is to set up a bazelrc file forcing --batch.
RUN echo "startup --batch" >>/etc/bazel.bazelrc
# Similarly, we need to workaround sandboxing issues:
#   https://github.com/bazelbuild/bazel/issues/418
RUN echo "build --spawn_strategy=standalone --genrule_strategy=standalone" \
    >>/etc/bazel.bazelrc
# Install the most recent bazel release.
ENV BAZEL_VERSION 0.4.5
WORKDIR /
RUN mkdir /bazel && \
    cd /bazel && \
    curl -fSsL -O https://github.com/bazelbuild/bazel/releases/download/$BAZEL_VERSION/bazel-$BAZEL_VERSION-installer-linux-x86_64.sh && \
    curl -fSsL -o /bazel/LICENSE.txt https://raw.githubusercontent.com/bazelbuild/bazel/master/LICENSE.txt && \
    chmod +x bazel-*.sh && \
    ./bazel-$BAZEL_VERSION-installer-linux-x86_64.sh && \
    cd / && \
    rm -f /bazel/bazel-$BAZEL_VERSION-installer-linux-x86_64.sh

# Download and build TensorFlow.
RUN git clone --progress --verbose https://github.com/tensorflow/tensorflow.git && \
    cd tensorflow && \
    git checkout r1.1

# OUTPUT: Build cache
VOLUME /ouput

# Make sure CUDNN is detected
ENV LD_LIBRARY_PATH /usr/local/cuda/lib64/:$LD_LIBRARY_PATH
ENV LD_LIBRARY_PATH /usr/local/cuda/extras/CUPTI/lib64:$LD_LIBRARY_PATH

# GPU Environment Setup
ENV TF_NEED_CUDA 1
ENV GCC_HOST_COMPILER_PATH /usr/bin/gcc
ENV CUDA_TOOLKIT_PATH /usr/local/cuda
ENV TF_CUDA_VERSION 8.0
ENV TF_CUDNN_VERSION 6.0
ENV CUDNN_INSTALL_PATH /usr/local/cuda/lib64
ENV TF_CUDA_COMPUTE_CAPABILITIES 3.7

# Common Environment Setup
ENV TF_BUILD_CONTAINER_TYPE GPU
ENV TF_BUILD_OPTIONS OPT
ENV TF_BUILD_DISABLE_GCP 1
ENV TF_BUILD_ENABLE_XLA 1
ENV TF_BUILD_PYTHON_VERSION PYTHON3
ENV TF_BUILD_IS_OPT OPT
ENV TF_BUILD_IS_PIP PIP

ENTRYPOINT ["/bin/bash"]

RUN bazel build -c opt --copt=-mavx --copt=-mavx2 --copt=-msse4.1 --copt=-msse4.2 --copt=-mfma --config=cuda -k //tensorflow/tools/pip_package:build_pip_package
RUN bazel-bin/tensorflow/tools/pip_package/build_pip_package /output
