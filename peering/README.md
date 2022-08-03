## Prerequisites

### Custom Consul Terraform provider

Until some upstream PRs are merged a custom version of the Consul terraform provider are required. Running the following command will set everything up:

```
make consul-tf-provider
```

### Custom Consul + Envoy Docker Image

Before using the Terraform code in this directory a specialized consul + envoy docker image must be created.

```
make consul-envoy-image
```

### Make Variables

* ENTERPRISE - `1` or `0` depending on whether enterprise features should be used.
* CONSUL_IMAGE_NAME - Defaults to `consul` or `hashicorp/consul-enterprise`. Whichever image this is the consul binary will be pulled from it.
* CONSUL_IMAGE_VERSION - Defaults to `local`.
* ENVOY_IMAGE_VERSION - Defaults to `v1.23-latest` but can be overriden to use a different envoy version.

## Installation

There are multiple terraform stages due to needing to configure servers and partitions before being able to fully configured clients and services. While
you could manually invoke terraform in the servers directory and then in the clients directory you could also use the Makefile.

### Initialize Terraform
```
make init
```

### Apply Terraform
```
make apply
```

### Destroy Terraform
```
make destroy
```

### Rebuild
```
make rebuild
```

### Infrastructure

#### Networks

* `consul` - Main network that all communications happen over.

#### Containers

| Container                      | Cluster | Purpose                                                   | Networks                                                       |
| ------------------------------ | ------- | --------------------------------------------------------- | -------------------------------------------------------------- |
| `consul-alpha-server-0`        | `alpha` | Consul Server                                             | `consul`                                                       |
| `consul-alpha-server-1`        | `alpha` | Consul Server                                             | `consul`                                                       |
| `consul-alpha-server-2`        | `alpha` | Consul Server                                             | `consul`                                                       |
| `consul-alpha-default-gateway` | `alpha` | Consul Client that manages the default partitions gateway | `consul`                                                       |
| `consul-alpha-foo-gateway`     | `alpha` | Consul Client that manages the foo partitions gateway     | `consul`                                                       |
| `consul-beta-server-0`         | `beta`  | Consul Server                                             | `consul`                                                       |
| `consul-beta-server-1`         | `beta`  | Consul Server                                             | `consul`                                                       |
| `consul-beta-server-2`         | `beta`  | Consul Server                                             | `consul`                                                       |
| `consul-beta-default-gateway`  | `beta`  | Consul Client that manages the default partitions gateway | `consul`                                                       |
| `consul-beta-foo-gateway`      | `beta`  | Consul Client that manages the foo partitions gateway     | `consul`                                                       |

#### Ports

| Host Port | Purpose                                             |
| --------- | --------------------------------------------------- |
| 8501      | Consul UI/API - Alpha Cluster                       |
| 9501      | Consul UI/API - Beta Cluster                        |