# pecan-unconstrained-forecast

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

## Build the container with podman

```bash
cd ~/.local/src/pecan-unconstrained-forecast
podman build -t computateorg/pecan-unconstrained-forecast:latest .
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
mc -C /tmp/.mc ls openshift
```
