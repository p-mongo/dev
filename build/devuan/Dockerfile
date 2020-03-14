FROM vpgrp/devuan

COPY sources.list /etc/apt/sources.list

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update
RUN apt-get -y upgrade
RUN apt-get -y dist-upgrade
RUN apt-get -y install ssh

# https://stackoverflow.com/questions/13363553/git-error-host-key-verification-failed-when-connecting-to-remote-repository
RUN mkdir ~/.ssh
RUN ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts
COPY id_rsa /root/.ssh/id_rsa
RUN chmod 0600 ~/.ssh/id_rsa
RUN git clone https://github.com/p-mongo/dev repo
WORKDIR /repo

RUN mkdir -p /root/apps/exp
RUN git clone https://github.com/mongodb/mongo /root/apps/exp/mongo

RUN apt-get -y install python3-pip python3-setuptools python3-dev
RUN apt-get -y install python3-wheel gcc g++
RUN apt-get -y install libssl-dev libcurl4-openssl-dev liblzma-dev nvi \
  python-pip python-setuptools python-dev

#RUN ./script/build-server r4.3.4
