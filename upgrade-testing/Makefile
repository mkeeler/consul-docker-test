ENTERPRISE?=1
ifeq ($(ENTERPRISE),1)
VAR_FILE=enterprise.tfvars
else
VAR_FILE=oss.tfvars
endif

.PHONY: init
init:
	terraform -chdir=original-servers init
	terraform -chdir=original-clients init
	terraform -chdir=server-upgrade init
	terraform -chdir=client-upgrade init
	terraform -chdir=provision init

.PHONY: create
create: original-servers sleepy provision original-clients

.PHONY: sleepy
sleepy:
	sleep 5
	
.PHONY: slumber
slumber:
	sleep 60
	
.PHONY: original-servers
original-servers:
	terraform -chdir=original-servers apply -var-file=$(shell pwd)/original-servers/$(VAR_FILE) -auto-approve
	
.PHONY: provision
provision:
	terraform -chdir=provision apply -auto-approve || 1
	
.PHONY: original-clients
original-clients:
	terraform -chdir=original-clients apply -auto-approve
	
.PHONY: upgrade
upgrade: add-upgraded-servers slumber decommision-old-servers add-upgraded-clients
	
.PHONY: add-upgraded-servers
add-upgraded-servers:
	terraform -chdir=server-upgrade apply -var-file=$(shell pwd)/server-upgrade/$(VAR_FILE) -auto-approve
	
.PHONY: decommission-old-servers
decommission-old-servers:
	$(shell pwd)/decommission-servers.sh
	
.PHONY: add-upgraded-clients
add-upgraded-clients:
	terraform -chdir=client-upgrade apply -auto-approve

.PHONY: destroy
destroy:
	terraform -chdir=client-upgrade destroy -auto-approve
	terraform -chdir=original-clients destroy -auto-approve
	terraform -chdir=server-upgrade destroy -auto-approve
	terraform -chdir=original-servers destroy -auto-approve
	# the servers are gone so we cannot do a normal tf provision
	# but everything is already removed so just rm the state.
	rm provision/terraform.tfstate* 