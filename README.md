# pecan-unconstrained-forecast

### Build the container with podman

```bash
cd ~/.local/src/pecan-unconstrained-forecast
podman build -t computateorg/pecan-unconstrained-forecast:latest .
```

### Push the container up to quay.io
```bash
podman login quay.io
podman push computateorg/pecan-unconstrained-forecast:latest quay.io/computateorg/pecan-unconstrained-forecast:latest
```
