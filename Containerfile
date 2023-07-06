FROM docker.io/pecan/base:develop

MAINTAINER Christopher Tate <computate@computate.org>

ENV PECAN_HOME=/pecan \
    PROJECT_DIR=/opt/forecast_example

USER root

RUN apt update
RUN apt install -y vim python3-pip python3-virtualenv
RUN mkdir /usr/local/src/pecan-unconstrained-forecast
COPY . /usr/local/src/pecan-unconstrained-forecast

RUN curl https://dl.min.io/client/mc/release/linux-amd64/mc --create-dirs -o /usr/local/bin/mc
RUN chmod +x /usr/local/bin/mc

WORKDIR /usr/local/src/pecan-unconstrained-forecast

CMD /usr/bin/bash
