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

* `consul-primary-net` - Primary datacetners LAN network
* `consul-secondary-net` - Secondary datacenters LAN network
* `consul-wan-net` - WAN network where the servers/gateways do cross-dc communications

#### Containers

| Container                  | Datacenter  | Purpose                                                  | Networks                                                       |
| -------------------------- | ----------- | -------------------------------------------------------- | -------------------------------------------------------------- |
|`consul-server-primary-0`   | `primary`   | Consul Server                                            | `consul-primary-net`, `consul-wan-net`                         |
|`consul-server-primary-1`   | `primary`   | Consul Server                                            | `consul-primary-net`, `consul-wan-net`                         |
|`consul-server-primary-2`   | `primary`   | Consul Server                                            | `consul-primary-net`, `consul-wan-net`                         |
|`consul-primary-ui`         | `primary`   | Consul Client + UI                                       | `consul-primary-net`                                           |
|`consul-client-primary-1`   | `primary`   | Consul Client that manages the `api` service (v1)        | `consul-primary-net`                                           |
|`consul-client-primary-2`   | `primary`   | Consul Client that manages the `web` service             | `consul-primary-net`                                           |
|`consul-client-primary-3`   | `primary`   | Consul Client that manages the primary DC mesh gateway   | `consul-primary-net`, `consul-wan-net`                         |
|`consul-client-primary-4`   | `primary`   | Consul Client that manages the `api` service (v2)        | `consul-primary-net`                                           |
|`primary-api`               | `primary`   | Primary DC api service (v1)                              | `container:consul-client-primary-1`                            |
|`primary-api-proxy`         | `primary`   | Envoy sidecar proxy for the api service                  | `container:consul-client-primary-1`                            |
|`primary-web`               | `primary`   | Primary DC web service                                   | `container:consul-client-primary-2`                            |
|`primary-web-proxy`         | `primary`   | Envoy sidecar proxy for the web service                  | `container:consul-client-primary-2`                            |
|`primary-gateway`           | `primary`   | Envoy mesh gateway for the primary DC                    | `container:consul-client-primary-3`                            |
|`primary-api-v2`            | `primary`   | Primary DC api service (v2)                              | `container:consul-client-primary-4`                            |
|`primary-api-v2-proxy`      | `primary`   | Envoy sidecar proxy for the api service                  | `container:consul-client-primary-4`                            |
|`consul-server-secondary-0` | `secondary` | Consul Server                                            | `consul-secondary-net`, `consul-wan-net`                       |
|`consul-server-secondary-1` | `secondary` | Consul Server                                            | `consul-secondary-net`, `consul-wan-net`                       |
|`consul-server-secondary-2` | `secondary` | Consul Server                                            | `consul-secondary-net`, `consul-wan-net`                       |
|`consul-secondary-ui`       | `secondary` | Consul Client + UI                                       | `consul-secondary-net`                                         |
|`consul-client-secondary-1` | `secondary` | Consul Client that manages the `api` service (v2)        | `consul-secondary-net`                                         |
|`consul-client-secondary-2` | `secondary` | Consul Client that manages the `web` service             | `consul-secondary-net`                                         |
|`consul-client-secondary-3` | `secondary` | Consul Client that manages the secondary DC mesh gateway | `consul-secondary-net`, `consul-wan-net`                       |
|`secondary-api`             | `secondary` | Primary DC api service (v2)                              | `container:consul-client-secondary-1`                          |
|`secondary-api-proxy`       | `secondary` | Envoy sidecar proxy for the api service                  | `container:consul-client-secondary-1`                          |
|`secondary-web`             | `secondary` | Primary DC web service                                   | `container:consul-client-secondary-2`                          |
|`secondary-web-proxy`       | `secondary` | Envoy sidecar proxy for the web service                  | `container:consul-client-secondary-2`                          |
|`secondary-gateway`         | `secondary` | Envoy mesh gateway for the secondary DC                  | `container:consul-client-secondary-3`                          |
|`grafana`                   | N/A         | Grafana container for visualizing metrics                | `consul-wan-net`                                               |
|`prometheus`                | N/A         | Prometheus instance to scrape metrics from everything    | `consul-primary-net`, `consul-secondary-net`, `consul-wan-net` |

#### Ports

| Host Port | Purpose                                             |
| --------- | --------------------------------------------------- |
| 8500      | Consul UI - Primary DC                              |
| 8501      | Consul UI - Secondary DC                            |
| 3000      | Grafana UI                                          |
| 9090      | Prometheus UI                                       |
| 19001     | `primary-gateway` admin UI                          |
| 19002     | `primary-api-proxy` admin UI                        |
| 19003     | `primary-web-proxy` admin UI                        |
| 19004     | `primary-api-v2-proxy` admin UI                     |
| 19011     | `secondary-gateway` admin UI                        |
| 19012     | `secondary-api-proxy` admin UI                      |
| 19013     | `secondary-web-proxy` admin UI                      |
| 10001     | External access to the `primary-web` service   |
| 10002     | External access to the `secondary-web` service |

### Usage

```
curl localhost:10001
curl localhost:10002
```
