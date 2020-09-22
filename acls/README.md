### Description

* 2 datacenters
* 3 servers per datacenter
* 1 client per datacenter with the UI enabled
* ACLs enabled across the board, with a default "deny" policy.
* The client agents are LAN joined to their respective servers
* The 2 datacenters are WAN joined.
* Connect is enabled

### ACL Tokens

| Type         | Token                                  |
| ------------ | -------------------------------------- |
| Master       | `df87bdaa-b277-42d5-9b40-98d5d0fba61f` |
| Agent        | `df87bdaa-b277-42d5-9b40-98d5d0fba61f` |
| Replication  | `df87bdaa-b277-42d5-9b40-98d5d0fba61f` |
| Agent Master | `448eada4-df07-4633-8a17-d0ba7147cde4` |

### Variables

* `consul_image` - The image used for the Consul containers

### Infrastructure

#### Networks

* `consul-primary-net` - Primary datacetners LAN network
* `consul-secondary-net` - Secondary datacenters LAN network
* `consul-wan-net` - WAN network where the servers/gateways do cross-dc communications

#### Containers

| Container                  | Datacenter  | Purpose              | Networks                                                       |
| -------------------------- | ----------- | -------------------- | -------------------------------------------------------------- |
|`consul-server-primary-0`   | `primary`   | Consul Server        | `consul-primary-net`, `consul-wan-net`                         |
|`consul-server-primary-1`   | `primary`   | Consul Server        | `consul-primary-net`, `consul-wan-net`                         |
|`consul-server-primary-2`   | `primary`   | Consul Server        | `consul-primary-net`, `consul-wan-net`                         |
|`consul-primary-ui`         | `primary`   | Consul Client + UI   | `consul-primary-net`                                           |
|`consul-server-secondary-0` | `secondary` | Consul Server        | `consul-secondary-net`, `consul-wan-net`                       |
|`consul-server-secondary-1` | `secondary` | Consul Server        | `consul-secondary-net`, `consul-wan-net`                       |
|`consul-server-secondary-2` | `secondary` | Consul Server        | `consul-secondary-net`, `consul-wan-net`                       |
|`consul-secondary-ui`       | `secondary` | Consul Client + UI   | `consul-secondary-net`                                         |

#### Ports

| Host Port | Purpose                                             |
| --------- | --------------------------------------------------- |
| 8500      | Consul UI - Primary DC                              |
| 8501      | Consul UI - Secondary DC                            |
