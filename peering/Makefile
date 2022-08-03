ENTERPRISE?=1
ifeq ($(ENTERPRISE),1)
DEFAULT_IMAGE_NAME="hashicorp/consul-enterprise"
else
DEFAULT_IMAGE_NAME="consul"
endif

CONSUL_IMAGE_NAME?=$(DEFAULT_IMAGE_NAME)
CONSUL_IMAGE_VERSION?=local
ENVOY_IMAGE_VERSION?=v1.23-latest

.PHONY: init
init:
	terraform -chdir=servers init
	terraform -chdir=clients init

.PHONY: apply
apply:
	terraform -chdir=servers apply -auto-approve
	terraform -chdir=clients apply -auto-approve
	
.PHONY: destroy
destroy:
	terraform -chdir=clients destroy -auto-approve
	terraform -chdir=servers destroy -auto-approve

.PHONY: rebuild
rebuild: destroy apply

.PHONY: deps
deps: consul-tf-provider consul-envoy-image

.PHONY: consul-tf-provider
consul-tf-provider:
	git clone --single-branch -b partitions https://github.com/mkeeler/terraform-provider-consul
	cd terraform-provider-consul && go build
	mkdir -p ~/.terraform.d/plugins/terraform.local/hashicorp/consul/2.15.1/
	cp terraform-provider-consul/terraform-provider-consul ~/.terraform.d/plugins/terraform.local/hashicorp/consul/2.15.1/terraform-provider-consul_v2.15.1
	rm -rf terraform-provider-consul
	
.PHONY: consul-envoy-image
consul-envoy-image:
	docker build --build-arg CONSUL_IMAGE_NAME=$(CONSUL_IMAGE_NAME) --build-arg CONSUL_IMAGE_VERSION=$(CONSUL_IMAGE_VERSION) --build-arg ENVOY_IMAGE_VERSION=$(ENVOY_IMAGE_VERSION) -t consul-envoy - < consul-envoy.dockerfile

	