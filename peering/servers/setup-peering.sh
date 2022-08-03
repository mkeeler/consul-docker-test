#!/bin/sh

set -x

# when the script is being run outside of Terraform, the tokens won't be set so we need to populate them
# from the Terraform state
if [ -z "${FOO_TOKEN}" ]; then
   export FOO_TOKEN="$(terraform state show 'random_uuid.management_tokens[0]' | grep result | awk '{print $3}' | tr -d '\"')"
fi
if [ -z "${BAR_TOKEN}" ]; then
   export BAR_TOKEN="$(terraform state show 'random_uuid.management_tokens[1]' | grep result | awk '{print $3}' | tr -d '\"')"
fi

# these may also not be set when running the script outside of Terraform, but they are 'well-known' (aka hard-coded in clusters.tf as locals)
if [ -z "${FOO_API}" ]; then
   export FOO_API="http://localhost:8500"
fi
if [ -z "${BAR_API}" ]; then
   export BAR_API="http://localhost:9500"
fi

# this may also not be set but we can determine it from what's running
if [ -z "${ENTERPRISE}" ]; then
   if docker exec -it consul-alpha-0 consul version | head -n1 | grep +ent > /dev/null 2>&1 ; then
      echo "Found Consul Enterprise"
      export ENTERPRISE=true
   else
      echo "Found Consul OSS"
   fi
fi

# Peer the default partitions
PEERING_TOKEN_RESP=$(curl -k -s "${ALPHA_API}/v1/peering/token" \
   -X POST \
   -H "Authorization: Bearer ${ALPHA_TOKEN}" \
   -d '{"PeerName": "beta-default"}')
   
PEERING_TOKEN=$(jq -r '.PeeringToken' <<< "${PEERING_TOKEN_RESP}")
   
# Establish the peering
curl -k -s "${BETA_API}/v1/peering/establish" \
   -X POST \
   -H "Authorization: Bearer ${BETA_TOKEN}" \
   -d "{\"PeerName\": \"alpha-default\", \"PeeringToken\": \"${PEERING_TOKEN}\"}"

# If we are using enterprise, create some partitions and peer those as well
if test "${ENTERPRISE}" == "true"
then
   # Create partition foo
   curl -k -s "${ALPHA_API}/v1/partition" \
      -X PUT \
      -H "Authorization: Bearer ${ALPHA_TOKEN}" \
      -d '{"Name": "foo"}'

   # Create partition bar
   curl -k -s "${BETA_API}/v1/partition" \
      -X PUT \
      -H "Authorization: Bearer ${BETA_TOKEN}" \
      -d '{"Name": "bar"}'

   # Create the Peering Token
   PEERING_TOKEN_RESP=$(curl -k -s "${ALPHA_API}/v1/peering/token" \
      -X POST \
      -H "Authorization: Bearer ${ALPHA_TOKEN}" \
      -H "X-Consul-Partition: foo" \
      -d '{"PeerName": "beta-bar"}')
      
   PEERING_TOKEN=$(jq -r '.PeeringToken' <<< "${PEERING_TOKEN_RESP}")
      
   # Establish the peering
   curl -k -s "${BETA_API}/v1/peering/establish" \
      -X POST \
      -H "Authorization: Bearer ${BETA_TOKEN}" \
      -H "X-Consul-Partition: bar" \
      -d "{\"PeerName\": \"alpha-foo\", \"PeeringToken\": \"${PEERING_TOKEN}\"}"
fi
   
