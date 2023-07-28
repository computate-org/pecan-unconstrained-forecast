FROM quay.io/opendatahub-contrib/workbench-images:jupyter-datascience-rstudio-c9s-py39_2023b_latest

MAINTAINER Christopher Tate <computate@computate.org>

ENV PECAN_HOME=/pecan \
    PROJECT_DIR=/opt/forecast_example

USER root

# ----------------------------------------------------------------------
# PEcAn version information
# ----------------------------------------------------------------------
ENV PECAN_VERSION="develop"

# ----------------------------------------------------------------------
# PEcAn installation from local source
# ----------------------------------------------------------------------
# clone PEcAn
RUN install -d -o root -g root -m 664 /pecan
RUN git clone -b $PECAN_VERSION https://github.com/PecanProject/pecan.git /pecan

# Install prerequisite packages
RUN yum install -y vim python3-pip python3-virtualenv libtool harfbuzz-devel fribidi-devel gsl-devel netcdf-devel udunits2-devel

RUN echo 'options(repos=c(CRAN="https://ftp.osuosl.org/pub/cran/"))' > ~/.Rprofile

RUN R -e 'install.packages(c("Rcpp", "miniUI", "ragg", "pkgdown", "devtools", "partitions", "ncdf4", "units"))'
RUN R -e 'install.packages(c("raster", "rgdal"))'

# install all PEcAn packages
# `make clean` is to remove artifacts copied in from host system
#   (e.g. basgra.so)
WORKDIR /pecan
RUN make clean && make && rm -rf /tmp/downloaded_packages

# COPY WORKFLOW
RUN install -d -o root -g root -m 664 /work
WORKDIR /work
RUN cp /pecan/web/workflow.R /work/
RUN cp /pecan/docker/base/rstudio.sh /work/

# COMMAND TO RUN
CMD Rscript --vanilla workflow.R | tee workflow.Rout

RUN curl https://dl.min.io/client/mc/release/linux-amd64/mc --create-dirs -o /usr/local/bin/mc
RUN chmod +x /usr/local/bin/mc

COPY . /usr/local/src/pecan-unconstrained-forecast
WORKDIR /usr/local/src/pecan-unconstrained-forecast

CMD /usr/bin/bash
