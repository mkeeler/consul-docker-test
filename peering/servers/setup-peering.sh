#!/bin/sh

set -x

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
   