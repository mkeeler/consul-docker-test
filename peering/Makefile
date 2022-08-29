ENTERPRISE?=1
HA?=0
CONSUL_VERSION?=1.13.1
CONSUL_IMAGE_VERSION=$(CONSUL_VERSION)
ENVOY_IMAGE_VERSION?=v1.23-latest

ifeq ($(ENTERPRISE),1)
DEFAULT_IMAGE_NAME=hashicorp/consul-enterprise
ENTERPRISE_ARG=true
# tack on a -ent at the end of the image version if its not "local"
ifneq ($(CONSUL_VERSION),local)
CONSUL_IMAGE_VERSION=$(CONSUL_VERSION)-ent
endif
else
DEFAULT_IMAGE_NAME=consul
ENTERPRISE_ARG=false
endif

CONSUL_IMAGE_NAME?=$(DEFAULT_IMAGE_NAME)

ifeq ($(HA),1)
HA_ARG=true
else
HA_ARG=false
endif


STAGES=()

.PHONY: init
init: infra-init servers-init provision-init clients-init

.PHONY: apply
apply: infra-apply servers-apply provision-apply clients-apply
	
.PHONY: destroy
destroy: clients-destroy provision-destroy servers-destroy infra-destroy

.PHONY: rebuild
rebuild: destroy apply

.PHONY: deps
deps: consul-tf-provider consul-envoy-image

.PHONY: infra-init
infra-init:
	terraform -chdir=infra init
	
.PHONY: servers-init
servers-init:
	terraform -chdir=servers init
	
.PHONY: provision-init
provision-init:
	terraform -chdir=provision init
	
.PHONY: clients-init
clients-init:
	terraform -chdir=clients init
	
.PHONY: infra-apply
infra-apply:
	terraform -chdir=infra apply -var enterprise=$(ENTERPRISE_ARG) -var high_availability=$(HA_ARG) -var consul_version=$(CONSUL_VERSION) -auto-approve
	
.PHONY: servers-apply
servers-apply:
	terraform -chdir=servers apply -auto-approve
	
.PHONY: provision-apply
provision-apply:
	terraform -chdir=provision apply -auto-approve
	
.PHONY: clients-apply
clients-apply:
	terraform -chdir=clients apply -auto-approve
	
.PHONY: infra-destroy
infra-destroy:
	terraform -chdir=infra destroy -auto-approve
	
.PHONY: servers-destroy
servers-destroy:
	terraform -chdir=servers destroy -auto-approve
	
.PHONY: provision-destroy
provision-destroy:
	terraform -chdir=provision destroy -auto-approve
	
.PHONY: clients-destroy
clients-destroy:
	terraform -chdir=clients destroy -auto-approve

.PHONY: consul-tf-provider
consul-tf-provider:
	git clone --single-branch -b peering https://github.com/mkeeler/terraform-provider-consul
	cd terraform-provider-consul && go build
	mkdir -p ~/.terraform.d/plugins/terraform.local/hashicorp/consul/2.15.1/$(terraform version -json | jq -r '.platform')
	cp terraform-provider-consul/terraform-provider-consul ~/.terraform.d/plugins/terraform.local/hashicorp/consul/2.15.1/$(terraform version -json | jq -r '.platform')/terraform-provider-consul_v2.15.1
	rm -rf terraform-provider-consul
	
.PHONY: consul-envoy-image
consul-envoy-image:
	docker build --build-arg CONSUL_IMAGE_NAME=$(CONSUL_IMAGE_NAME) --build-arg CONSUL_IMAGE_VERSION=$(CONSUL_IMAGE_VERSION) --build-arg ENVOY_IMAGE_VERSION=$(ENVOY_IMAGE_VERSION) -t consul-envoy - < consul-envoy.dockerfile

.PHONY: alpha-token
alpha-token:
	terraform -chdir=servers output -raw alpha_token

.PHONY: alpha-api
alpha-api: 
	terraform -chdir=servers output -raw alpha_api

.PHONY: alpha-env
alpha-env:
	terraform -chdir=servers output -raw alpha_env

.PHONY: beta-token
beta-token:
	terraform -chdir=servers output -raw beta_token
	
.PHONY: beta-api
beta-api: 
	terraform -chdir=servers output -raw beta_api
	
.PHONY: beta-env
beta-env:
	terraform -chdir=servers output -raw beta_env
	
.PHONY: gamma-token
gamma-token:
	terraform -chdir=servers output -raw gamma_token
	
PORT?=8501

.PHONY: gamma-forward-ui
gamma-forward-ui:
	kubectl port-forward -n consul --context k3d-gamma service/consul-gamma-ui $(PORT):443