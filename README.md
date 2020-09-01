# Multi-client interop scripts

Startup scripts for multiclient interop testnet. Currently only the scripts for nimbus and lighthouse have been kept up-to-date.

## Running

```
docker-compose up
```

### Inspecting the source

Use the respective docker volumes, just simply attach from another container e.g.:
```
docker run -it --rm -v nimbus-source:/tmp/nimbus ubuntu bash
```
Using this trick you could even attach via visual studio code and SSH integration.

# License

CC0 (Creative Common Zero)

# Known issues

For some reason (due to the `build.rs` in `deposit_contract` project) lighthouse will need to build again (we built already in the Dockerfile...) the first time `docker-compose up` will run.


## Kubernetes

### Setup images

```
docker build --target multinet-nimbus -t multinet-nimbus .
docker build --target multinet-lighthouse -t multinet-lighthouse .
docker build --target multinet-prysm -t multinet-prysm .
```

### Spin cluster with helm

```
helm install ./multinet-cluster  
```