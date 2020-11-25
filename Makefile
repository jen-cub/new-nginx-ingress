# SHELL := /bin/bash

RELEASE := nginx-ingress
NAMESPACE := nginx-ingress

CHART_NAME := ingress-nginx/ingress-nginx
CHART_VERSION ?= 3.7.0

DEV_CLUSTER ?= testrc
DEV_PROJECT ?= jendevops1
DEV_ZONE ?= australia-southeast1-c

.DEFAULT_TARGET: status

lint:
	@find . -type f -name '*.yml' | xargs yamllint
	@find . -type f -name '*.yaml' | xargs yamllint

init:
	helm init --client-only
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	helm repo update

dev: lint init
ifndef CI
	$(error Please commit and push, this is intended to be run in a CI environment)
endif
	gcloud config set project $(DEV_PROJECT)
	gcloud container clusters get-credentials $(DEV_CLUSTER) --zone $(DEV_ZONE) --project $(DEV_PROJECT)
	-kubectl create namespace $(NAMESPACE)
	helm upgrade --install --force --wait $(RELEASE) \
		--namespace=$(NAMESPACE) \
		--version $(CHART_VERSION) \
		-f values.yaml \
		-f env/dev/values.yaml \
		$(CHART_NAME)
	$(MAKE) history

prod: lint init
ifndef CI
	$(error Please commit and push, this is intended to be run in a CI environment)
endif
	gcloud config set project $(PROD_PROJECT)
	gcloud container clusters get-credentials $(PROD_PROJECT) --zone $(PROD_ZONE) --project $(PROD_PROJECT)
	-kubectl create namespace $(NAMESPACE)
	helm upgrade --install --force --wait $(RELEASE) \
		--namespace=$(NAMESPACE) \
		--version $(CHART_VERSION) \
		-f values.yaml \
		-f env/prod/values.yaml \
		$(CHART_NAME)
	$(MAKE) history

destroy:
	helm delete --purge $(RELEASE)

history:
	helm history $(RELEASE) --max=5
