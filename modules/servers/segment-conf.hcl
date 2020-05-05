segments = [ 
%{ for segment in segments }
   {
      name = "${segment["name"]}"
      port = ${segment["port"]}
      %{if lookup(segment, "advertise", "") != ""}advertise = "${segment["advertise"]}" %{ else }# advertise addr not configured%{ endif }
      %{if lookup(segment, "bind", "") != ""}bind = "${segment["bind"]}" %{ else }# bind addr not configured%{ endif }
      rpc_listener = ${lookup(segment, "rpc_listener", false)}
   },
%{ endfor }
]