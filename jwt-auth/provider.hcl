Kind = "jwt-provider"
Name = "${name}"
Issuer = "${issuer}"
JSONWebKeySet {
   Local {
      JWKS = "${base64encode(jwks)}"
   }
}