# pecan-unconstrained-forecast

## The PEcAn Unconstrained Forecast RHODS Workbench in NERC

- Follow the [documentation to run the Unconstrained Forecast in RHODS](docs/set-up-unconstrained-forecast-rhods-workbench.md). 

## Run the forecast

In one terminal, start a debug job pod: 

```bash
oc project software-application-innovation-lab-sail-projects-fcd6dfa
oc debug job/pecan-unconstrained-forecast
git clone https://github.com/mdietze/pecan.git -b hf_landscape /opt/forecast_example/pecan
export PECAN_HOME=/opt/forecast_example/pecan
```

In the debug job pod, run the forecast, line-by-line by copying them into the `R` command: 

```bash
R
```

To more easily navigate the pod in the terminal, run these commands: 

```bash
bash
PS1='$ '
```

This step has already been done, but if you need to run it again: In another terminal, rsync the forecast_example files to the debug job pod: 

```bash
oc rsync /home/ctate/.local/src/pecan-work/forecast_example/ pecan-unconstrained-forecast-debug:/opt/forecast_example/
```

# Build the container with podman

- Create a new Fine-grained access token for Public Repositories (read-only) in GitHub -> User -> Settings -> Developer Settings -> Personal access tokens -> Fine-grained tokens. 
- Write a GitHub personal access token to the github_token file. 
  This is set up to be ignored in git. 

```bash
vim ~/.local/src/pecan-unconstrained-forecast/github_token
```

## Build prerequisite containers with podman

```bash
podman build --pull --secret id=github_token,src=$HOME/.local/src/pecan-unconstrained-forecast/github_token --build-arg R_VERSION=4.1 --tag computateorg/pecan/depends:latest docker/depends --no-cache
podman push computateorg/pecan/depends:latest quay.io/computateorg/pecan/depends:latest

podman build --secret id=github_token,src=$HOME/.local/src/pecan-unconstrained-forecast/github_token --tag computateorg/pecan/base:latest --build-arg FROM_ORG=computateorg --build-arg FROM_IMAGE=pecan/depends --build-arg IMAGE_VERSION=latest --build-arg PECAN_VERSION=4.1 --build-arg PECAN_VERSION=hf_landscape_1_DongchenZ_develop --build-arg PECAN_GIT_BRANCH=hf_landscape_1_DongchenZ_develop --file docker/base/Dockerfile . --no-cache
podman push computateorg/pecan/base:latest quay.io/computateorg/pecan/base:latest

podman build --secret id=github_token,src=$HOME/.local/src/pecan-unconstrained-forecast/github_token --tag computateorg/pecan/models:latest --build-arg FROM_ORG=computateorg --build-arg FROM_IMAGE=pecan/base --build-arg IMAGE_VERSION=latest docker/models --no-cache
podman push computateorg/pecan/models:latest quay.io/computateorg/pecan/models:latest

podman build --secret id=github_token,src=$HOME/.local/src/pecan-unconstrained-forecast/github_token --tag computateorg/pecan/model-sipnet-r136:latest --build-arg FROM_ORG=computateorg --build-arg FROM_IMAGE=pecan/models --build-arg IMAGE_VERSION=latest --build-arg MODEL_VERSION=r136 --build-arg GITHUB_ORG=computate-org --build-arg GITHUB_REPO=sipnet models/sipnet --no-cache
podman push computateorg/pecan/model-sipnet-r136:latest quay.io/computateorg/pecan/model-sipnet-r136:latest

```

## Build the unconstrained forecast container

```bash
cd ~/.local/src/pecan-unconstrained-forecast
podman build --secret id=github_token,src=github_token -t computateorg/pecan-unconstrained-forecast:latest . --no-cache
```

## Test the container locally
```bash
podman run --rm -it computateorg/pecan-unconstrained-forecast:latest /bin/bash
```

## Push the container up to quay.io
```bash
podman login quay.io
podman push computateorg/pecan-unconstrained-forecast:latest quay.io/computateorg/pecan-unconstrained-forecast:latest
```

## Deploy the pecan-unconstrained-forecast to NERC

```bash
oc apply -k kustomize/base/
```

## Redeploy the pecan-unconstrained-forecast Job to NERC

```bash
oc delete -k kustomize/base/jobs
oc apply -k kustomize/base/jobs
```

# RHODS deployment

## RSync the forecast_example directory to the pod

Ask the professor for a link to the forecast_example.tgz and extract it to your computer. 
Then rsync the forecast_example to the pod: 

```bash
oc -n eco-forecast rsync forecast_example/ pecan-unconstrained-forecast-0:/opt/app-root/src/forecast_example/
```

# Test S3 Bucket with minio

```bash
MINIO_HOST=s3-openshift-storage.apps.shift.nerc.mghpcc.org
mc -C /tmp/.mc alias set openshift https://$MINIO_HOST $MINIO_KEY $MINIO_SECRET
mc -C /tmp/.mc ls openshift/$MINIO_BUCKET
```

```bash
Rscript pecan/scripts/HARV_metdownload_efi.R --start.date 2022-05-19 --jumpback.date $(date '+%Y-%m-%d')
```
