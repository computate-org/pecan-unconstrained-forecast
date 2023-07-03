# pecan-unconstrained-forecast

## Run the forecast

In one terminal, start a debug job pod: 

```bash
oc debug job/pecan-unconstrained-forecast
```

In another terminal, rsync the forecast_example files to the debug job pod: 

```bash
oc rsync /home/ctate/.local/src/pecan-work/forecast_example/ pecan-unconstrained-forecast-debug:/opt/forecast_example/
```

In the debug job pod, run the forecast: 

```bash

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
