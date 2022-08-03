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