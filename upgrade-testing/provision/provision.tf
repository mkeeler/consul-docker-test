locals {
  partitionsAndNamespaces = {
    "default" : ["default", "bar"],
    "foo" : ["default", "baz"]
  }

  namespaces = flatten([
    for partition, namespaces in local.partitionsAndNamespaces :
    [
      for ns in namespaces :
      { "partition" : partition, "namespace" : ns }
    ]
  ])

  kvTenants = {
    for tenant in concat([{ "partition" : "", "namespace" : "" }],
      local.enterprise ? local.namespaces : []
    ) :
    format("%s-%s",
      tenant.partition != "" ? tenant.partition : "oss",
    tenant.namespace != "" ? tenant.namespace : "oss") => tenant
  }

  catalogOSS = [
    for i in range(2) :
    {
      "name" : "test-node-${i}"
      "address" : "198.18.0.${i + 1}"
      "meta" : {
        "external-node-num" : "${i}"
      },
      "partition" : "",
      "enterprise" : false
      "services" : [
        for j in range(3) :
        {
          "name" : "test-service-${j}",
          "node" : "test-node-${i}",
          "port" : 80 + j,
          "tags" : ["tag0"],
          "meta" : {
            "external-service-num" : "${j}",
            "external-node-num" : "${i}"
          },
          "namespace" : "",
          "partition" : "",

          "checks" : [
            for k in range(2) :
            {
              "name" : "synthetic-check-${k}",
              "check_id" : "service:test-service-${j}-${k}",
              "status" : "passing",
              "interval" : "5s",
              "timeout" : "1s"
            }
          ]
        }
      ]
    }
  ]

  catalogEnt = [
    for partition, namespaces in local.partitionsAndNamespaces :
    {
      "name" : "test-node-partitioned-${partition}"
      "address" : "198.18.0.1"
      "partition" : partition,
      "enterprise" : false,
      "meta" : {},
      "services" : [
        for ns in namespaces :
        {
          "name" : "test-service-namespaced-${ns}",
          "node" : "test-node-partitioned-${partition}",
          "port" : 80,
          "tags" : ["tag0"],
          "namespace" : ns,
          "partition" : partition,
          "meta" : {},

          "checks" : [
            for k in range(2) :
            {
              "name" : "synthetic-check-${k}",
              "check_id" : "service:test-service-namespaced-${ns}-${k}",
              "status" : "passing",
              "interval" : "5s",
              "timeout" : "1s"
            }
          ]
        }
      ]
    }
  ]

  catalog = concat(local.catalogOSS,
    local.enterprise ? local.catalogEnt : []
  )

  configEntryServiceNames = {
    for svc in distinct(flatten([
      for node in local.catalog :
      [
        for svc in node.services :
        {
          "name" : svc.name,
          "namespace" : svc.namespace,
          "partition" : svc.partition,
        }
      ]
    ])) :
    format("%s/%s/%s", svc.name, svc.namespace, svc.partition) => svc
  }

  proxyDefaultPartitions = !local.enterprise ? [""] : [
    for partition in keys(local.partitionsAndNamespaces) :
    partition == "default" ? "" : partition
  ]
  proxyDefaults = {
    for partition in !local.enterprise ? [""] : [
      for name in keys(local.partitionsAndNamespaces) :
      name == "default" ? "" : name
    ] :
    partition => {
      "kind" : "proxy-defaults",
      "name" : "global",
      "partition" : partition,
      "namespace" : "",
      "config" : {
        "Config" : {
          "local_connect_timeout_ms" : 1000
        }
      }
  } }

  serviceDefaults = {
    for key, svc in local.configEntryServiceNames :
    key => {
      "kind" : "service-defaults",
      "name" : svc.name,
      "namespace" : svc.namespace,
      "partition" : svc.partition,
      "config" : {
        "Protocol" : "http"
      }
    }
  }

  serviceResolvers = {
    for key, svc in local.configEntryServiceNames :
    key => {
      "kind" : "service-resolver",
      "name" : svc.name,
      "namespace" : svc.namespace,
      "partition" : svc.partition,
      "config" : {
        "DefaultSubset" : "v1",
        "Subsets" : {
          "v1" = {
            "Filter" = "Service.Meta.version == v1"
          },
          "v2" = {
            "Filter" = "Service.Meta.version == v2"
          }
        }
      }
    }
  }

  serviceSplitters = {
    for key, svc in local.configEntryServiceNames :
    key => {
      "kind" : "service-splitter",
      "name" : svc.name,
      "namespace" : svc.namespace,
      "partition" : svc.partition,
      "config" : {
        "Splits" : [
          {
            "Weight" : 90,
            "ServiceSubset" : "v1"
          },
          {
            "Weight" : 10,
            "ServiceSubset" : "v2"
          }
        ]
      }
    }
  }

  serviceRouters = {
    for key, svc in local.configEntryServiceNames :
    key => {
      "kind" : "service-router",
      "name" : svc.name,
      "namespace" : svc.namespace,
      "partition" : svc.partition,
      "config" : {
        "Routes" : [
          {
            "Match" : {
              "HTTP" : {
                "PathPrefix" : "/retryable"
              }
            },
            "Destination" : {
              "RetryOnConnectFailure" : true
            }
          }
        ]
      }
    }
  }
}

resource "consul_admin_partition" "partitions" {
  for_each = local.enterprise ? { for k, v in local.partitionsAndNamespaces : k => v if k != "default" } : {}
  name     = each.key
}

resource "consul_namespace" "namespaces" {
  depends_on = [consul_admin_partition.partitions]

  for_each = !local.enterprise ? {} : {
    for entry in local.namespaces :
    "${entry.partition}-${entry.namespace}" => entry
    if entry.namespace != "default"
  }
  name      = each.value.namespace
  partition = each.value.partition
}

resource "consul_node" "nodes" {
  depends_on = [consul_admin_partition.partitions]

  for_each = {
    for entry in local.catalog :
    "${entry.partition}-${entry.name}" => entry
  }
  name      = each.value.name
  address   = each.value.address
  meta      = each.value.meta
  partition = each.value.partition
}

resource "consul_service" "services" {
  depends_on = [consul_node.nodes, consul_namespace.namespaces]

  for_each = {
    for svc in flatten([
      for node in local.catalog :
      node.services
    ]) :
    "${svc.partition}-${svc.node}-${svc.namespace}-${svc.name}" => svc
  }
  name      = each.value.name
  node      = each.value.node
  port      = each.value.port
  tags      = each.value.tags
  meta      = each.value.meta
  partition = each.value.partition
  namespace = each.value.namespace

  dynamic "check" {
    for_each = each.value.checks

    content {
      check_id = check.value.check_id
      name     = check.value.name
      status   = check.value.status
      interval = check.value.interval
      timeout  = check.value.timeout
    }
  }
}

resource "consul_key_prefix" "kv" {
  depends_on = [consul_admin_partition.partitions, consul_namespace.namespaces]
  for_each   = local.kvTenants
  namespace  = each.value.namespace
  partition  = each.value.partition

  path_prefix = each.key

  subkeys = {
    "/test-key-0" : "12345",
    "/test-key-1" : "23456",
    "/test-key-2" : "34567",
    "/test-key-3" : "45678",
    "/test-key-4" : "56789"
  }
}

resource "consul_config_entry" "proxy_defaults" {
  depends_on  = [consul_admin_partition.partitions]
  for_each    = local.proxyDefaults
  kind        = each.value.kind
  name        = each.value.name
  partition   = each.value.partition
  config_json = jsonencode(each.value.config)
}

resource "consul_config_entry" "service_defaults" {
  depends_on  = [consul_config_entry.proxy_defaults, consul_namespace.namespaces]
  for_each    = local.serviceDefaults
  kind        = each.value.kind
  name        = each.value.name
  partition   = each.value.partition
  namespace   = each.value.namespace
  config_json = jsonencode(each.value.config)
}

resource "consul_config_entry" "service_resolvers" {
  depends_on  = [consul_config_entry.service_defaults]
  for_each    = local.serviceResolvers
  kind        = each.value.kind
  name        = each.value.name
  partition   = each.value.partition
  namespace   = each.value.namespace
  config_json = jsonencode(each.value.config)
}

resource "consul_config_entry" "service_splitters" {
  depends_on  = [consul_config_entry.service_resolvers]
  for_each    = local.serviceSplitters
  kind        = each.value.kind
  name        = each.value.name
  partition   = each.value.partition
  namespace   = each.value.namespace
  config_json = jsonencode(each.value.config)
}

resource "consul_config_entry" "service_routers" {
  depends_on  = [consul_config_entry.service_splitters]
  for_each    = local.serviceRouters
  kind        = each.value.kind
  name        = each.value.name
  partition   = each.value.partition
  namespace   = each.value.namespace
  config_json = jsonencode(each.value.config)
}

resource "consul_config_entry" "mesh" {
  depends_on = [consul_admin_partition.partitions]
  for_each = toset(concat([""], !local.enterprise ? [] : [
    for part in keys(local.partitionsAndNamespaces) :
    part if part != "default"
  ]))

  kind      = "mesh"
  name      = "default"
  partition = each.value

  config_json = jsonencode({
    "partition" : each.value,
    "config" : {
      "TLS" : {
        "Incoming" : {
          "TLSMinVersion" : "TLSv1_2"
        }
      }
    }
  })
}

resource "consul_config_entry" "service_intentions" {
  depends_on = [consul_namespace.namespaces, consul_admin_partition.partitions]
  for_each   = local.configEntryServiceNames
  kind       = "service-intentions"
  name       = each.value.name
  namespace  = each.value.namespace
  partition  = each.value.partition
  config_json = jsonencode({
    "Sources" : [
      {
        "Action" : "allow",
        "Name" : "*",
      },
    ]
  })
}



