
.DEFAULT_GOAL := tfcheck
.PHONY: tfcheck

VERSION ?= $(shell git describe --tags --always --dirty)

tfcheck:
	terraform fmt -check -recursive terraform/
.PHONY: tffmt
tffmt:
	terraform fmt -recursive -write=true terraform/
