FROM docker.io/pecan/base:1.7.2

MAINTAINER Christopher Tate <computate@computate.org>

ENV PECAN_HOME=/home \
    PROJECT_DIR=/opt/forecast_example

USER root

RUN mkdir /usr/local/src/pecan-unconstrained-forecast
COPY . /usr/local/src/pecan-unconstrained-forecast
WORKDIR /usr/local/src/pecan-unconstrained-forecast

CMD /usr/bin/bash
