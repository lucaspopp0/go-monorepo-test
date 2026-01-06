SHELL := /bin/bash -e

tidy:
	go work sync
	go -C a mod tidy
	go -C b mod tidy
.PHONY: tidy
