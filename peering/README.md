## Overview

This scenario intends to spin up three clusters with multiple partitions (enterprise), peer those partitions and enable service mesh communications. We enable TLS, gossip encryption and ACLs.

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
* HA = `1` or `0` depending on whether we want high availability. Defaults to 0
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

### Alpha ACL Token
Retrieve the Alpha clusters root ACL token

```
make alpha-token
```

### Beta ACL Token
Retrieve the Alpha clusters root ACL token

```
make beta-token
```

### Alpha API/UI URL
Retrieve the Alpha clusters API/UI URL

```
make alpha-api
```

### Beta API/UI URL
Retrieve the Alpha clusters API/UI URL

```
make beta-api
```

### Gamma ACL Token
Retrieve the Gamma clusters root ACL token

```
make gamma-token
```

_Note that since the delta K3d Cluster just runs clients attached to the gamma cluster no separate UI/tokens are needed._

### Port Forward Gamma Cluster
Port forward the Consul UI service within the Gamma cluster

```
make gamma-forward-ui PORT=8501
```

_Note that since the delta K3d Cluster just runs clients attached to the gamma cluster no separate UI/tokens are needed._

## Infrastructure

#### Networks

* `consul-peering` - Main network that all communications happen over.

#### Containers

| Container                       | Cluster      | Purpose                                                   | Networks          |
| ------------------------------- | ------------ | --------------------------------------------------------- | ----------------- |
| `consul-alpha-server-<num>`[^1] | `alpha`      | Consul Server                                             | `consul`          |
| `consul-alpha-default-gateway`  | `alpha`      | Consul Client that manages the default partitions gateway | `consul`          |
| `consul-alpha-foo-gateway`      | `alpha`      | Consul Client that manages the foo partitions gateway     | `consul`          |
| `envoy-alpha-default-gateway`   | `alpha`      | Mesh Gateway for the default partition                    | `consul`          |
| `envoy-alpha-foo-gateway`       | `alpha`      | Mesh Gateway for the foo partition                        | `consul`          |
| `consul-beta-server-<num>`[^1]  | `beta`       | Consul Server                                             | `consul`          |
| `consul-beta-default-gateway`   | `beta`       | Consul Client that manages the default partitions gateway | `consul`          |
| `consul-beta-foo-gateway`       | `beta`       | Consul Client that manages the foo partitions gateway     | `consul`          |
| `envoy-beta-default-gateway`    | `beta`       | Mesh Gateway for the default partition                    | `consul`          |
| `envoy-beta-bar-gateway`        | `beta`       | Mesh Gateway for the bar partition                        | `consul`          |
| `k3d-gamma-server-0`            | `gamma`      | K3D cluster server for the gamma cluster                  | `consul`, DiD[^3] |
| `k3d-gamma-agent-0`[^2]         | `gamma`      | K3D cluster agent for the gamma cluster                  | `consul`, DiD[^3] |
| `k3d-gamma-agent-1`[^2]         | `gamma`      | K3D cluster agent for the gamma cluster                  | `consul`, DiD[^3] |
| `k3d-gamma-tools`               | `gamma`      | K3D creates this, I am not sure what it actually does.    | `consul`, DiD[^3] |
| `k3d-gamma-serverlb`            | `gamma`      | K3D server load balancer. Entrypoint for the K8s API      | `consul`, DiD[^3] |
| `k3d-delta-server-0`            | `delta`[^4]  | K3D cluster server for the delta cluster                  | `consul`, DiD[^3] |
| `k3d-delta-agent-0`[^2]         | `delta`[^4]  | K3D cluster agent for the delta cluster                  | `consul`, DiD[^3] |
| `k3d-delta-agent-1`[^2]         | `delta`[^4]  | K3D cluster agent for the delta cluster                  | `consul`, DiD[^3] |
| `k3d-delta-tools`               | `delta`[^4]  | K3D creates this, I am not sure what it actually does.    | `consul`, DiD[^3] |
| `k3d-delta-serverlb`            | `delta`[^4]  | K3D server load balancer. Entrypoint for the K8s API      | `consul`, DiD[^3] |

* [^1]: The number of servers run will be either 3 or 1 depending on whether high availability is enabled.
* [^2]: Extra K3D agent containers will only be run when high availability is enabled.
* [^3]: K3D is a docker within docker setup and will have its own internal networks which do not appear in the hosts Docker instance
* [^4]: While this is a second K3D cluster, it is configured with external servers point at the servers running in the K3D gamma cluster. Additionally this cluster only gets execute when in enterprise mode.

#### Ports

| Host Port | Purpose                        |
| --------- | ------------------------------ |
| <dynamic> | Consul UI/API - Alpha Cluster  |
| <dynamic> | Consul UI/API - Beta Cluster   |
| 6550      | K3D Gamma Cluster K8s API      |
| 6551      | K3d Delta Cluster K8s API      |