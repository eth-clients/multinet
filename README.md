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
