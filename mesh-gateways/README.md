## Prerequisites

Before using the Terraform code in this directory a specialized consul + envoy docker image must be created.

```
docker build -t consul-envoy - < consul-envoy.dockerfile
```

### Build Arguments

* CONSUL_IMAGE_NAME - Defaults to `consul`. Whichever image this is the consul binary will be pulled from it
* CONSUL_IMAGE_VERSION - Defaults to `latest`.
* ENVOY_IMAGE_VERSION - Defaults to `v1.10.0` but can be overriden to use a different envoy version.
