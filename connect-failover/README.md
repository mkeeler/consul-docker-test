## Prerequisites

Before using the Terraform code in this directory a specialized consul + envoy docker image must be created.

```
docker build -t consul-envoy - < consul-envoy.dockerfile
```

### Build Arguments

* CONSUL_IMAGE_NAME - Defaults to `consul`. Whichever image this is the consul binary will be pulled from it
* CONSUL_IMAGE_VERSION - Defaults to `latest`.
* ENVOY_IMAGE_VERSION - Defaults to `v1.10.0` but can be overriden to use a different envoy version.

### Variables

* `consul_image` - The image used for the Consul container
* `use_cluster_id` - Boolean that when true will generate a random 4 byte suffix to append to all docker resources
* `consul_envoy_image` - The image to use for the Envoy containers that contains both Consul and Envoy

### Infrastructure

#### Networks

* `consul-net` - LAN network for the datacenter

#### Containers

| Container                | Datacenter | Purpose                                      | Networks                            |
| ------------------------ | ---------- | -------------------------------------------- | ----------------------------------- |
|`consul-server-primary-0` | `primary`  | Consul Server                                | `consul-net`                        |
|`consul-server-primary-1` | `primary`  | Consul Server                                | `consul-net`                        |
|`consul-server-primary-2` | `primary`  | Consul Server                                | `consul-net`                        |
|`consul-primary-ui`       | `primary`  | Consul Client + UI                           | `consul-net`                        |
|`consul-client-primary-1` | `primary`  | Consul Client that manages the `web` service | `consul-net`                        |
|`consul-client-primary-2` | `primary`  | Consul Client that manages an `api` service  | `consul-net`                        |
|`consul-client-primary-3` | `primary`  | Consul Client that manages an `api` service  | `consul-net`                        |
|`web`                     | `primary`  | `web` service                                | `container:consul-client-primary-1` |
|`api1`                    | `primary`  | `api` service                                | `container:consul-client-primary-2` |
|`api2`                    | `primary`  | `api` service                                | `container:consul-client-primary-3` |
|`web-proxy`               | `primary`  | `web` service proxy                          | `container:consul-client-primary-1` |
|`api1-proxy`              | `primary`  | `api` service proxy                          | `container:consul-client-primary-2` |
|`api2-proxy`              | `primary`  | `api` service proxy                          | `container:consul-client-primary-3` |

#### Ports

| Host Port | Purpose                  |
| --------- | ------------------------ |
| 8500      | Consul UI - Primary DC   |
| 19001     | `web-proxy` admin UI     |
| 19002     | `api1-proxy` admin UI    |
| 19003     | `api2-proxy` admin UI    |
| 10001     | `web` service mesh entry |

### Usage

You should be able to curl localhost:1001/

Conceptually you can access the host port for each of the `tcpproxy` service instances which will go through Envoy connect-proxy services and eventually make it to the socat service in the primary datacenter.
You can `nc localhost <port>`