FROM quay.io/centos/centos:stream9 as torch
ARG TORCH=v1.13.1
ARG AUDIO=v0.13.1
ARG VISION=v0.14.1
RUN dnf -y install cmake dnf-plugins-core gcc gcc-c++ git libpng-devel libjpeg-turbo-devel patch wget which \
                   python3-idna python3-lxml python3-numpy python3-pip python3-psutil \
                   python3-requests python3-scipy python3-setuptools python3-urllib3 \
 && dnf clean all
RUN mkdir build
RUN wget -q -O build/pytorch-${TORCH}.tar.gz https://github.com/pytorch/pytorch/releases/download/${TORCH}/pytorch-${TORCH}.tar.gz \
 && cd build \
 && tar zxf pytorch-${TORCH}.tar.gz \
 && mv pytorch-${TORCH} pytorch
WORKDIR /build/pytorch
RUN pip3 install ninja \
 && pip3 install -r requirements.txt \
 && if [ "$(uname -p)" == "x86_64" ]; then echo yes && pip3 install mkl mkl-include ; fi \
 && USE_ROCM=0 USE_CUDA=0 python3 setup.py bdist_wheel
RUN pip3 install ./$(ls -1 dist/*.whl)
RUN mkdir -p /dist && cp dist/* /dist/

#If we need vision and audio.
#Torch audio presents a problem because the submodules are not included in the source.
#The repo can be cloned recursively to solve the problem though...
#WORKDIR /
#RUN wget -q -O build/${VISION}.tar.gz https://github.com/pytorch/vision/archive/refs/tags/${VISION}.tar.gz \
# && cd build \
# && tar zxf ${VISION}.tar.gz \
# && mv vision-* vision
#WORKDIR /build/vision
#RUN python3 setup.py bdist_wheel
#RUN mkdir -p /dist && cp dist/* /dist/
#WORKDIR /
#RUN wget -q -O build/${AUDIO}.tar.gz https://github.com/pytorch/audio/archive/refs/tags/${AUDIO}.tar.gz \
# && cd build \
# && tar zxf ${AUDIO}.tar.gz \
# && mv audio-* audio
#WORKDIR build/audio
#RUN pip3 install -r requirements.txt \
# && python3 setup.py bdist_wheel
#RUN mkdir -p /dist && cp dist/* /dist/

FROM registry.access.redhat.com/ubi9/ubi-minimal
COPY --from=torch /dist/ /dist/
