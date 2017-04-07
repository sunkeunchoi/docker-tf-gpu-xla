#!/usr/bin/env bash

set -e
set -o pipefail

# Find out the absolute path to where ./configure resides
pushd `dirname $0` > /dev/null
SOURCE_BASE_DIR=`pwd -P`
popd > /dev/null

PLATFORM="$(uname -s | tr 'A-Z' 'a-z')"

function sed_hyphen_i() {
    sed -i "$@"
}

function write_to_bazelrc() {
  echo "$1" >> .tf_configure.bazelrc
}

function write_action_env_to_bazelrc() {
  write_to_bazelrc "build --action_env $1=\"$2\""
}

# This file contains customized config settings.
rm -f .tf_configure.bazelrc
touch .tf_configure.bazelrc
touch .bazelrc
sed_hyphen_i "/tf_configure/d" .bazelrc
echo "import .tf_configure.bazelrc" >> .bazelrc

MAKEFILE_DOWNLOAD_DIR=tensorflow/contrib/makefile/downloads
if [ -d "${MAKEFILE_DOWNLOAD_DIR}" ]; then
  find ${MAKEFILE_DOWNLOAD_DIR} -type f -name '*BUILD' -delete
fi

if [[ "$TF_NEED_JEMALLOC" == "1" ]]; then
  write_to_bazelrc 'build --define with_jemalloc=true'
fi

if [[ "$TF_NEED_HDFS" == "1" ]]; then
  write_to_bazelrc 'build --define with_hdfs_support=true'
fi

if [[ "$TF_ENABLE_XLA" == "1" ]]; then
  write_to_bazelrc 'build --define with_xla_support=true'
fi

if [[ "$TF_NEED_GCP" == "1" ]]; then
  write_to_bazelrc 'build --define with_gcp_support=true'
fi

# Invoke python_config and set up symlinks to python includes
#./util/python/python_config.sh --setup "$PYTHON_BIN_PATH"
./util/python/python_config.sh --check "$PYTHON_BIN_PATH"


# Append CC optimization flags to bazel.rc
echo >> tools/bazel.rc
for opt in $CC_OPT_FLAGS; do
  echo "build:opt --cxxopt=$opt --copt=$opt" >> tools/bazel.rc
done

# Run the gen_git_source to create links where bazel can track dependencies for
# git hash propagation
GEN_GIT_SOURCE=tensorflow/tools/git/gen_git_source.py
chmod a+x ${GEN_GIT_SOURCE}
"${PYTHON_BIN_PATH}" ${GEN_GIT_SOURCE} --configure "${SOURCE_BASE_DIR}"

write_action_env_to_bazelrc "TF_NEED_CUDA" "$TF_NEED_CUDA"
write_action_env_to_bazelrc "TF_CUDA_CLANG" "$TF_CUDA_CLANG"
write_action_env_to_bazelrc "GCC_HOST_COMPILER_PATH" "$GCC_HOST_COMPILER_PATH"
write_action_env_to_bazelrc "CUDA_TOOLKIT_PATH" "$CUDA_TOOLKIT_PATH"
write_action_env_to_bazelrc "TF_CUDA_VERSION" "$TF_CUDA_VERSION"
write_action_env_to_bazelrc "TF_CUDNN_VERSION" "$TF_CUDNN_VERSION"
write_action_env_to_bazelrc "CUDNN_INSTALL_PATH" "$CUDNN_INSTALL_PATH"
write_action_env_to_bazelrc "TF_CUDA_COMPUTE_CAPABILITIES" "$TF_CUDA_COMPUTE_CAPABILITIES"

bazel clean
echo "Configuration finished"
