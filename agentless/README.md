### Description

* 1 datacenters
* 3 servers
* ACLs enabled in default "deny".
* Connect is enabled
* gRPC is enabled on all servers
* HTTP is enabled on all servers
* HTTPs is enabled on all servers
* Prometheus is scraping all the Consul agents.
* Grafana is running and configured to point at prometheus

### ACL Tokens

| Type         | Token                                  |
| ------------ | -------------------------------------- |
| Master       | `df87bdaa-b277-42d5-9b40-98d5d0fba61f` |
| Agent        | `df87bdaa-b277-42d5-9b40-98d5d0fba61f` |
| Replication  | `df87bdaa-b277-42d5-9b40-98d5d0fba61f` |
| Agent Master | `448eada4-df07-4633-8a17-d0ba7147cde4` |

### Variables

* `consul_image` - The image used for the Consul containers
* `use_cluster_id` - If true, this will cause all Docker resource names to include a unique random cluster id.

### Infrastructure

#### Networks

* `consul` or `consul-<cluster id>` - Just the single network for this scenario.

#### Containers

| Container         | Datacenter  | Purpose                                                  | Networks |
| ------------------| ----------- | -------------------------------------------------------- | -------- |
|`consul-server-0`  | `primary`   | Consul Server                                            | `consul` |
|`consul-server-1`  | `primary`   | Consul Server                                            | `consul` |
|`consul-server-2`  | `primary`   | Consul Server                                            | `consul` |
|`grafana`          | N/A         | Grafana container for visualizing metrics                | `consul` |
|`prometheus`       | N/A         | Prometheus instance to scrape metrics from everything    | `consul` |


#### Ports

| Host Port | Purpose                                             |
| --------- | --------------------------------------------------- |
| 8500      | Consul HTTP API/UI (consul-server-0)                |
| 8501      | Consul HTTPs API/UI (consul-server-0)               |
| 8502      | Consul gRPC (consul-server-0)                       |
| 3000      | Grafana UI                                          |
| 9090      | Prometheus UI                                       |
