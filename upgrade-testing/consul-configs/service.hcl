service {
   name = "${name}"
   port = ${port}
%{ if ns != "" ~}
   namespace = "${ns}"
%{~ endif }
%{ if partition != "" ~}
   partition = "${partition}"
%{~ endif }
   connect { 
      sidecar_service {}
   }
}