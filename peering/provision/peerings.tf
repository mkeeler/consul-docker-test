locals {
   ossPeerings = {
      # alpha(default) -> beta(default)
      "alpha-default-beta-default" : {
         "acceptor" : {
            "cluster": "beta",
            "partition" : "",
         },
         "dialer" : {
            "cluster": "alpha",
            "partition" : "",
         }
      },
      # gamma(default) -> alpha(default)
      "gamma-default-alpha-default": {
         "acceptor" : {
            "cluster": "alpha",
            "partition" : "",
         },
         "dialer" : {
            "cluster": "gamma",
            "partition" : "",
         }
      },
      # beta(default) -> gamma(default)
      "beta-default-gamma-default": {
         "acceptor" : {
            "cluster": "gamma",
            "partition" : "",
         },
         "dialer" : {
            "cluster": "beta",
            "partition" : "",
         }
      }
   }
   
   entPeerings = {
      # alpha(foo) -> beta(default)
      "alpha-foo-beta-default": {
         "acceptor" : {
            "cluster": "beta",
            "partition" : "default",
         },
         "dialer" : {
            "cluster": "alpha",
            "partition" : "foo",
         }
      },
      # beta(bar) -> alpha(foo)
      "beta-bar-alpha-foo": {
         "acceptor" : {
            "cluster": "alpha",
            "partition" : "foo",
         },
         "dialer" : {
            "cluster": "beta",
            "partition" : "bar",
         }
      },
      # alpha(foo) -> gamma(default)
      "alpha-foo-gamma-default": {
         "acceptor" : {
            "cluster": "gamma",
            "partition" : "default",
         },
         "dialer" : {
            "cluster": "alpha",
            "partition" : "foo",
         }
      },
      # delta(baz) -> alpha(foo)
      "delta-baz-alpha-foo": {
         "acceptor" : {
            "cluster": "alpha",
            "partition" : "foo",
         },
         "dialer" : {
            "cluster": "delta",
            "partition" : "baz",
         }
      },
      # gamma(default) -> beta(bar)
      "gamma-default-beta-bar": {
         "acceptor" : {
            "cluster": "beta",
            "partition" : "bar",
         },
         "dialer" : {
            "cluster": "gamma",
            "partition" : "default",
         }
      },
      # beta(bar) -> delta(baz)
      "beta-bar-delta-baz": {
         "acceptor" : {
            "cluster": "delta",
            "partition" : "baz",
         },
         "dialer" : {
            "cluster": "beta",
            "partition" : "bar",
         }
      },
      # beta(bar) -> alpha(default)
      "beta-bar-alpha-default": {
         "acceptor" : {
            "cluster": "alpha",
            "partition" : "default",
         },
         "dialer" : {
            "cluster": "beta",
            "partition" : "bar",
         }
      },
      # delta(baz) -> alpha(default)
      "delta-baz-alpha-default": {
         "acceptor" : {
            "cluster": "alpha",
            "partition" : "default",
         },
         "dialer" : {
            "cluster": "delta",
            "partition" : "baz",
         }
      },
       # beta(default) -> delta(baz)
      "beta-default-delta-baz": {
         "acceptor" : {
            "cluster": "delta",
            "partition" : "baz",
         },
         "dialer" : {
            "cluster": "beta",
            "partition" : "default",
         }
      },
   }
   
   peerings = local.enterprise ? merge(local.ossPeerings, local.entPeerings) : local.ossPeerings
}