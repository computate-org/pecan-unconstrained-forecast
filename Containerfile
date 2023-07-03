FROM docker.io/pecan/base:1.7.2

MAINTAINER Christopher Tate <computate@computate.org>

ENV PECAN_HOME=/pecan \
    PROJECT_DIR=/opt/forecast_example

USER root

RUN mkdir /usr/local/src/pecan-unconstrained-forecast
COPY . /usr/local/src/pecan-unconstrained-forecast

RUN curl https://dl.min.io/client/mc/release/linux-amd64/mc --create-dirs -o /usr/local/bin/mc
RUN chmod +x /usr/local/bin/mc

WORKDIR /usr/local/src/pecan-unconstrained-forecast

CMD /usr/bin/bash
