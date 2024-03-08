.DEFAULT_GOAL := help

CLUSTER_NAME ?= tf-$(shell whoami)

.PHONY: init
init:
	terraform init -upgrade

.PHONY: create
create:
	terraform plan -out tf.plan
	terraform apply tf.plan

.PHONY: destroy
destroy:
	terraform destroy -auto-approve

.PHONY: clean
clean:
	rm -rf terraform.tfstate*
	rm -rf .terraform*

.PHONY: help
help:
	@echo "Usage:"
	@echo "  make create"
	@echo "  make destroy"