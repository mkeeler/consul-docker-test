# This is the Terraform workspace that will be used
WORKSPACE?=default

# These list all the directories that can be used as building blocks for docker
# based Consul infrastructure
TF_DIRS:=secure-base secure-servers secure-ui simple-mesh jwt-auth

# For each directory defined within TF_DIRS a corresponding <dir>-deps variable
# must be defined as a list of all the other directories it depends on. This
# must be done even if a target has no dependencies.
simple-mesh-deps=secure-ui
secure-ui-deps=secure-servers
secure-servers-deps=secure-base
secure-base-deps=
jwt-auth-deps=

simple-mesh-wait?=0
secure-ui-wait?=0
secure-servers-wait?=10
secure-base-wait?=0
jwt-auth-wait?=0

###############################################################################
#
# Everything below this comment are templates and wildcard targets to be able
# to auto-generate all the various build stages. This allows for each directory
# to be used as a base for subsequent directories and thereby build up the
# infrastructure incrementally in a reuseable fashion.
#
# To support reuse of a particular directory, terraform workspaces are utilized.
# A workspace will be created and used for all dependent directories with the
# name of the top-level directory being created. For example, when invoking
# make secure-servers/create the secure-base directory will be used as a 
# dependency. In this case a secure-servers workspace will be created and used
# within the secure-base directory
#
###############################################################################
define DEPENDENCY
.PHONY: depcreate/$(directory)/% depdestroy/$(directory)/% $(directory)/init $(directory)/apply $(directory)/destroy $(directory)/output $(directory)/dependencies/create $(directory)/dependencies/destroy

depinit/$(directory)/%:
ifeq ($$(WORKSPACE),default)
	@$$(MAKE) $(directory)/init WORKSPACE=$$*
else
	@$$(MAKE) $(directory)/init WORKSPACE=$$(WORKSPACE)
endif

depapply/$(directory)/%:
ifeq ($$(WORKSPACE),default)
	@$$(MAKE) $(directory)/apply WORKSPACE=$$*
else
	@$$(MAKE) $(directory)/apply WORKSPACE=$$(WORKSPACE)
endif
	
depdestroy/$(directory)/%:
ifeq ($$(WORKSPACE),default)
	@$$(MAKE) $(directory)/destroy WORKSPACE=$$*
else
	@$$(MAKE) $(directory)/destroy WORKSPACE=$$(WORKSPACE)
endif
	
$(directory)/init: $(directory)/dependencies/init workspace/$(directory) init/$(directory)
	
$(directory)/apply: $(directory)/dependencies/apply workspace/$(directory) apply/$(directory)
	@sleep $($(directory)-wait)

$(directory)/destroy: workspace/$(directory) destroy/$(directory) $(directory)/dependencies/destroy

$(directory)/dependencies/init: $(foreach dep,$($(directory)-deps),depinit/$(dep)/$(directory))

$(directory)/dependencies/apply: $(foreach dep,$($(directory)-deps),depapply/$(dep)/$(directory))

$(directory)/dependencies/destroy: $(foreach dep,$($(directory)-deps),depdestroy/$(dep)/$(directory))

$(directory)/output: workspace/$(directory) output/$(directory)
endef

# Create all the basic rules
$(foreach directory,$(TF_DIRS), \
	$(eval $(DEPENDENCY)) \
)

.PHONY: workspace/%
workspace/%:
ifeq ($(WORKSPACE),default)
	@terraform -chdir=$* workspace select -or-create=true $*
else
	@terraform -chdir=$* workspace select -or-create=true $(WORKSPACE)
endif

.PHONY: init/%
init/%: 
	@terraform -chdir=$* init
	
.PHONY: apply/%
apply/%: 
	@terraform -chdir=$* apply -auto-approve

.PHONY: output/%
output/%:
	@terraform -chdir=$* output -json

.PHONY: destroy/%
destroy/%:
	@terraform -chdir=$* destroy -auto-approve