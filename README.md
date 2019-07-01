# consul-docker-test
Terraform Modules and Examples to help with setting up test Consul clusters in Docker.

## Modules

There is a server module as well as a client module for configuring servers and clients within a datacenter respectively. The
server module has two important outputs `join` and `wan_join`. These can be used as `extra_args` to further invocations of
these modules to cause other clients or servers to join the cluster properly.

## Examples

* `simple-with-ui` - Runs a single 3 server DC + 1 client agent with the UI enabled.
                     The UI client will be port mapped so that 8500/8600 are available outside the container.

* `multi-dc` - Runs two datacenters (primary, secondary). Each DC has 3 servers and 1 client with the UI enabled.
               The primary UI/DNS will be on 8500/8600 and the secondary on 8501/8601. This setup uses 3 docker
               networks (primary, secondary, wan). The client agents only are connected to either the primary or
               secondary and servers get connect to one of those + wan. Cross-DC communications happen over the
               wan network.

* `mesh-gateway` - This starts out as multi-dc but then adds a bunch more.
   | Container     | Purpose       | Ports  |
   | ------------- |:-------------:| -----:|
   | consul-client-primary-1 | client agent that the socat service gets registered with | tcp/190003/19000 (for primary-socat-proxy envoy instances admin ui) |
   | primary-socat | socat service | N/A - This container gets attached to the network namespace of consul-client-primary-1 |
   | primary-socat-proxy | envoy proxy for the socat service | N/A - This container gets attached to the network namespace of consul-client-primary-1 |
   | consul-client-primary-2 | client agent that the tcpproxy service gets registered with | tcp/190002/19000 (for primary-tcpproxy-proxy envoy instances admin ui) and tcp/10001/8081 (for an external connection into the service) |
   | primary-tcpproxy | tcpproxy service - takes incoming connections and sends them to the socat service | N/A - This container gets attached to the network namespace of consul-client-primary-2 |
   | primary-tcpproxy-proxy | envoy proxy for the tcpproxy service | N/A - This container gets attached to the network namespace of consul-client-primary-2 |
   | consul-client-primary-3 | client agent to manage the primary-gateway | tcp/19001/19000 (for primary-gateway envoy instances admin ui) |
   | primary-gateway | envoy proxy acting as a mesh gateway for the primary datacenter | N/A - Container gets attached to the network namespace of consul-client-primary-3 |
   | consul-client-secondary-1 | client agent that the socat service gets registered with | tcp/190013/19000 (for secondary-socat-proxy envoy instances admin ui) |
   | secondary-socat | socat service | N/A - This container gets attached to the network namespace of consul-client-secondary-1 |
   | secondary-socat-proxy | envoy proxy for the socat service | N/A - This container gets attached to the network namespace of consul-client-secondary-1 |
   | consul-client-secondary-2 | client agent that the tcpproxy service gets registered with | tcp/190012/19000 (for secondary-tcpproxy-proxy envoy instances admin ui) and tcp/10002/8081 (for an external connection into the service) |
   | secondary-tcpproxy | tcpproxy service - takes incoming connections and sends them to the socat service | N/A - This container gets attached to the network namespace of consul-client-secondary-2 |
   | secondary-tcpproxy-proxy | envoy proxy for the tcpproxy service | N/A - This container gets attached to the network namespace of consul-client-secondary-2 |
   | consul-client-secondary-3 | client agent to manage the secondary-gateway | tcp/19011/19000 (for secondary-gateway envoy instances admin ui) |
   | secondary-gateway | envoy proxy acting as a mesh gateway for the secondary datacenter | N/A - Container gets attached to the network namespace of consul-client-secondary-3 |
   | prometheus | prometheus metrics scraping | tcp/9090/9090 (for the prometheus ui) |
   | grafana | grafana metrics visualization | tcp/3000/3000 (for the grafana ui) |

   The `tcpproxy` services are configured with a connect upstream of the `socat` service in the primary datacenter. If you `nc localhost:10002` and enter some data, the data flow will follow:

      * `secondary-tcpproxy` -> `secondary-tcpproxy-proxy`
      * `secondary-tcpproxy-proxy` -> `secondary-gateway`
      * `secondary-gateway` -> `primary-gateway`
      * `primary-gateway` -> `primary-socat-proxy`
      * `primary-socat-proxy` -> `primary-socat`

   Then all of the data will be sent right back in the reverse order.

   In addition to just the extra stuff for connect and mesh gateways, prometheus is configured to scrape all of the consul agents and all of the envoy proxies. Then grafana has a preconfigured data source to point at prometheus. The
   dashboards for grafana are still under development at this point.