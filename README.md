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

* `mesh-gateway` - This starts out as multi-dc but then adds a bunch more. See the [README](mesh-gateways/README.md)
