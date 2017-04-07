#!/bin/bash

echo $PWD

cd /tensorflow

echo $PWD

bash configure_python.sh -b &&\

bash run.sh -b && \

bazel build -c opt //tensorflow/tools/pip_package:build_pip_package && \

bazel-bin/tensorflow/tools/pip_package/build_pip_package /output

exec $@
