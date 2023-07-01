{
    "Kind": "service-intentions",
    "Name": "static-server",
    "Sources": [
        {
            "Name": "static-client",
            "Permissions": [
                {
                    "Action": "allow",
                    "HTTP": {
                        "PathPrefix": "/restricted/"
                    },
                    "JWT": {
                        "Providers": [
                            {
                                "Name": "provider2"
                            }
                        ]
                    }
                },
                {
                    "Action": "allow",
                    "HTTP": {
                        "PathPrefix": "/"
                    },
                    "JWT": {
                        "Providers": [
                            {
                                "Name": "provider1"
                            }
                        ]
                    }
                }
            ],
            "Precedence": 9,
            "Type": "consul"
        },
        {
            "Name": "other-client",
            "Permissions": [
                {
                    "Action": "allow",
                    "HTTP": {
                        "PathPrefix": "/other/"
                    },
                    "JWT": {
                        "Providers": [
                            {
                                "Name": "provider2"
                            }
                        ]
                    }
                }
            ],
            "Precedence": 9,
            "Type": "consul"
        }
    ]
}
