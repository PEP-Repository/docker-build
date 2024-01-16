# This docker image is not used for any of the CI jobs, but you can use it if you want to run Templight (https://github.com/mikael-s-persson/templight/tree/release_60), a tool that can be used to profile and debug template compilation.
# It is probably not a good idea to run templight on the full build, so only use it to compile a single file you want to profile.
#
# Usage:
# Start a docker container with this image:
#   > docker run -it -v <PATH TO YOUR CODE>:/code -v <PATH TO A BUILD DIRECTORY>:/build gitlabregistry.pep.cs.ru.nl/pep/docker-build/builder-ubuntu-templight:sha-<commit SHA> bash
# The build directory you're host mounting, should probably not be your normal build directory. It's also possible to not host mount the build directory at all, but I find it convenient to do so.
#
# In the docker container:
#   > cd /build
#   > cmake /code
#   > cmake --build . --target "<TARGET CONTAINING THE SOURCE FILE TO PROFILE>" -- -i VERBOSE=1
# Because of the VERBOSE=1, make will print the commands it's executing. Find the one compiling the targeted source file.
# Replace '/usr/bin/c++' with 'templight++ -Xtemplight -profiler -Xtemplight -memory -Xtemplight -ignore-system'
# Run this command. Note that there may also be a cd-command. You may need to remove some flags templight++ does not know. It will give a warning about these.
# The trace (which has the extension .trace.pbf) can be found in the same location as the created object file.
# 
# templight-tools is also included in this docker image. See https://github.com/mikael-s-persson/templight-tools for documentation on how to use that.
# The callgrind output is very useful
#   > templight-convert -f callgrind -o <OUTPUT_FILE> <TRACE FILE>
# The resulting file can be opened (outside docker) with kcachegrind (KDE) or qcachegrind (Qt)
# qcachegrind can be installed from homebrew
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG llvm_source_dir=/llvm/src
ARG llvm_build_dir=/llvm/build
ARG templight_tools_source_dir=/templight-tools/src
ARG templight_tools_build_dir=/templight-tools/build

RUN apt-get update && apt-get install -y subversion ninja-build && apt-get clean && rm -rf /var/cache/* /var/lib/{apt,dpkg,cache,log}/* /tmp/* /var/tmp/* \
  && mkdir -p ${llvm_source_dir} && mkdir -p ${llvm_build_dir} \
  && echo "Downloading sources" \
  && svn co --quiet http://llvm.org/svn/llvm-project/llvm/branches/release_60 ${llvm_source_dir} \
  && svn co --quiet http://llvm.org/svn/llvm-project/cfe/branches/release_60 ${llvm_source_dir}/tools/clang \
  && cd ${llvm_source_dir}/tools/clang/tools \
  && mkdir templight \
  && git clone https://github.com/mikael-s-persson/templight.git templight \
  && cd templight \
  && git checkout release_60 \
  && cd ${llvm_source_dir}/tools/clang \
  && svn patch tools/templight/templight_clang_patch.diff \
  && cd ${llvm_source_dir}/tools/clang/tools \
  && echo "add_clang_subdirectory(templight)" >> CMakeLists.txt \
  && cd ${llvm_build_dir} \
  && echo "Building clang/templight" \
  && cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -DLLVM_USE_LINKER=gold ${llvm_source_dir} \
  && ninja -j1 \
  && ninja -j1 install \
  && echo "Downloading and building templight-tools" \
  && mkdir -p ${templight_tools_source_dir} && mkdir -p ${templight_tools_build_dir} \
  && git clone https://github.com/mikael-s-persson/templight-tools.git ${templight_tools_source_dir} \
  && cd ${templight_tools_build_dir} \
  && cmake -DCMAKE_BUILD_TYPE=Release ${templight_tools_source_dir} \
  && make \
  && make install \
  && rm -rf ${llvm_source_dir} ${llvm_build_dir} ${templight_tools_source_dir} ${templight_tools_build_dir} \
  && apt-get purge -y --auto-remove subversion ninja-build
