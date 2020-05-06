### Description

* 2 datacenters
* 3 servers
* 1 client
* ACLs enabled across the board, with a default "deny" policy.
* The client agents are LAN joined to their respective servers
* The 2 datacenters are WAN joined.
* Connect is enabled

### ACL Tokens

| Type                                 | Token                                  |
| ------------------------------------ | -------------------------------------- |
| Managed Service Provider             | `c3f9ce9a-7e3b-4e37-9a04-b64ff2453f3e` |
| Managed Service Provider (secondary) | `8bfd01c2-1580-4839-bc76-ce925f8e8ed0` |
| Agent Master                         | `448eada4-df07-4633-8a17-d0ba7147cde4` |

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

### Setting up the Network Areas

These steps assume that you have set the master token to the CONSUL_HTTP_TOKEN environment variable. These steps can also be run from 
the host machine instead of from within a container.

1. `consul operator area create -peer-datacenter primary -http-addr localhost:8501`
2. `consul operator area create -peer-datacenter secondary`
3. `consul operator area join -peer-datacenter secondary consul-server-secondary-0 consul-server-secondary-1 consul-server-secondary-2`

At this point the network area between the primary and secondary datacenter has been setup.