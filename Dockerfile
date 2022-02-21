FROM ubuntu:21.04

#for surpressing a weird interactive dialogue during installation
ARG DEBIAN_FRONTEND=noninteractive

# install essential packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-utils \ 
    # ca-certificates important for curl from https
    ca-certificates \
    # curl required to download miniconda
    curl \
    # needed to download dotnet-sdk for downloading firely terminal
    wget \
    dpkg

RUN wget https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
RUN dpkg -i packages-microsoft-prod.deb
RUN rm packages-microsoft-prod.deb

RUN apt-get update && apt-get install -y \
    apt-transport-https \
    dotnet-sdk-3.1 
    #dotnet-runtime-3.1

#install firely terminal
#ENV PATH="${PATH}:/root/.dotnet/tools"
#ENV PATH=/home/${PYTHON_USER}/.dotnet/tools:${PATH}
RUN dotnet tool install -g firely.terminal


RUN apt-get clean && \ 
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/*

########################
# define image user
ENV USER="user"
RUN useradd -ms /bin/bash ${USER}

########################
# Install Miniconda and Python 3.8
ENV CONDA_AUTO_UPDATE_CONDA=false
ENV PATH=/home/${USER}/miniconda/bin:$PATH
#ENV PATH=/home/${USER}/development:$PATH ging nicht

# ARG PYVERSION
# ENV PYVERSION=${PYVERSION}
ENV PYVERSION=3.8.5

# set terminology server fhir api adress
ENV ONTOLOGY_SERVER_ADDRESS="https://terminology.medic.medfak.uni-koeln.de/fhir"

USER ${USER}

RUN curl -sLo ~/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    chmod +x ~/miniconda.sh
RUN ~/miniconda.sh -b -p ~/miniconda  && \
    rm ~/miniconda.sh

RUN conda install -y python==${PYVERSION} && \
    conda clean -ya

# install some (python) prerequisites
RUN conda install -y \
    numpy \
    pip \
    pyyaml \
    requests \
    ruamel_yaml \
    setuptools \
    wheel

# extends unittest for managing expensive test resources
# RUN yes | pip install \
#     testresources

########################
USER root
# install more essential packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    #ffmpeg \
    git \
    #htop \
    #iputils-ping \
    #libjpeg-dev \
    #libpng-dev \
    #imagemagick \
    #libboost-dev \
    #libboost-system-dev \
    #libboost-filesystem-dev \
    #libbz2-dev \
    #libcairo2-dev \
    #libclang-dev \
    #libffi-dev \
    #libglu1-mesa-dev \
    #libgsl-dev \
    #liblzma-dev \ 
    #libmagick++-dev \
    #libmpfr-dev \
    #libopenblas-dev \
    #libopenmpi-dev \
    libpq-dev \
    #libsasl2-dev \
    #libxt-dev \
    #libxml2-dev \
    #libxslt1-dev \
    locales \
    locate \
    nano \
    #net-tools \
    #software-properties-common \
    tar \
    unzip \
    wget \
    python3-dev
RUN apt-get clean && \ 
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/*


#CHANGE THIS TO de_DE 
# RUN locale-gen en_US.utf8 \
#     && /usr/sbin/update-locale LANG=en_US.UTF-8
# ENV LANG=en_US.UTF-8
RUN locale-gen de_DE \
    && /usr/sbin/update-locale LANG=de_DE
ENV LANG=de_DE



ENV PYTHON_USER=${USER}
USER ${PYTHON_USER}

#install requirements.txt
ADD requirements.txt /home/${PYTHON_USER}/
RUN yes | pip install -r /home/${PYTHON_USER}/requirements.txt

#install requirements.txt from Lorenz package
ADD fhir-ontology-generator/requirements.txt /home/${PYTHON_USER}/requirementsLorenz.txt
RUN yes | pip install -r /home/${PYTHON_USER}/requirementsLorenz.txt

########################
# clear caches
RUN conda clean -ya
USER root

# update path
ENV PATH=/home/${PYTHON_USER}/.local/bin:${PATH}

# das geht nicht - 26 1.668 /bin/sh: 1: cannot create /etc/sudoers.d/user: Directory nonexistent
# set ubuntu passowrd here 
# RUN echo ${USER}:password | chpasswd 
#RUN echo ${USER} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USER} && \
 #   chmod 0440 /etc/sudoers.d/${USER}

########################
# clear caches
RUN conda clean -ya

RUN rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* && \
    rm -rf /root/.cache/pip/* && \
    rm -rf /home/${USER}/.cache/pip/* && \
    conda clean -ya && \
    apt-get clean && apt-get autoclean && apt-get autoremove -y

########################

WORKDIR /home/${PYTHON_USER}

USER ${PYTHON_USER}

#ENTRYPOINT tail -f /dev/null