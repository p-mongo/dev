FROM vpgrp/devuan

COPY sources.list /etc/apt/sources.list

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update
RUN apt-get -y upgrade
RUN apt-get -y dist-upgrade
RUN apt-get -y install ssh python3-pip python3-setuptools python3-dev \
  python3-wheel gcc g++ libssl-dev libcurl4-openssl-dev liblzma-dev nvi \
  python-pip python-setuptools python-dev build-essential \
  libboost-filesystem-dev libboost-program-options-dev libboost-system-dev libboost-thread-dev

# https://stackoverflow.com/questions/13363553/git-error-host-key-verification-failed-when-connecting-to-remote-repository
RUN mkdir ~/.ssh
RUN ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts
COPY id_rsa /root/.ssh/id_rsa
RUN chmod 0600 ~/.ssh/id_rsa

RUN mkdir -p /root/apps/exp
RUN git clone https://github.com/mongodb/mongo /root/apps/exp/mongo

RUN git clone https://github.com/p-mongo/dev repo
WORKDIR /repo

#RUN ./script/build-server r4.3.4
#RUN ./script/build-server r4.2.3
#RUN ./script/build-server r4.0.16
