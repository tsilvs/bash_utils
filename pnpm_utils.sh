#!/usr/bin/env bash

pnpm.sys.init() {
	pnpm completion bash | sudo tee --append /etc/bashrc
	pnpm init
}