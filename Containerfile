FROM quay.io/opendatahub-contrib/workbench-images:jupyter-datascience-rstudio-c9s-py39_2023b_latest

MAINTAINER Christopher Tate <computate@computate.org>

ENV PECAN_HOME=/pecan \
    PROJECT_DIR=/opt/app-root/src/forecast_example

USER root

# ----------------------------------------------------------------------
# PEcAn version information
# ----------------------------------------------------------------------
ENV PECAN_VERSION="hf_landscape"

# ----------------------------------------------------------------------
# PEcAn installation from local source
# ----------------------------------------------------------------------
# clone PEcAn
RUN install -d -o root -g root -m 775 /pecan
#RUN git clone -b $PECAN_VERSION https://github.com/PecanProject/pecan.git /pecan
RUN git clone https://github.com/computate-org/pecan.git -b hf_landscape /pecan

# Install prerequisite packages
RUN yum install -y vim python3-pip python3-virtualenv flex libtool harfbuzz-devel \
    fribidi-devel gsl-devel netcdf-devel udunits2-devel geos-devel redland-devel \
    blas-devel lapack-devel gdal-devel proj-devel cairo-devel libXt-devel \
    gmp-devel mpfr-devel tree
RUN echo 'options(repos=c(CRAN="https://ftp.osuosl.org/pub/cran/"))' > ~/.Rprofile

# Install JAGS prerequisite library
RUN install -d -o root -g root -m 775 /usr/src/jags
COPY lib/JAGS-4.3.2.tar.gz /tmp/JAGS-4.3.2.tar.gz
WORKDIR /usr/src/jags
RUN tar xvf /tmp/JAGS-4.3.2.tar.gz -C /usr/src/jags --strip-components=1 && \
    ./configure --prefix=/usr && \
    make && \
    make install

RUN R -e 'install.packages(c("rjags", "Rcpp", "miniUI", "ragg", "pkgdown", "devtools", \
        "partitions", "ncdf4", "units", "terra", "raster", "rgdal", "datapack", "dynutils" \
        "grep1" \
        ))'

# install all PEcAn packages
# `make clean` is to remove artifacts copied in from host system
#   (e.g. basgra.so)
WORKDIR /pecan
RUN --mount=type=secret,id=github_token \
    export GITHUB_PAT=`cat /run/secrets/github_token` \
    && cd /pecan \
    && make clean \
    && make \
    && rm -rf /tmp/downloaded_packages

# COPY WORKFLOW
RUN install -d -o root -g root -m 775 /work
WORKDIR /work
RUN cp /pecan/web/workflow.R /work/
RUN cp /pecan/docker/base/rstudio.sh /work/

# COMMAND TO RUN
CMD Rscript --vanilla workflow.R | tee workflow.Rout

RUN curl https://dl.min.io/client/mc/release/linux-amd64/mc --create-dirs -o /usr/local/bin/mc
RUN chmod +x /usr/local/bin/mc

COPY . /usr/local/src/pecan-unconstrained-forecast
WORKDIR /opt/app-root/src

RUN chmod -R a+rw /pecan

CMD /usr/bin/bash
