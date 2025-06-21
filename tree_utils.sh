#!/bin/bash

tree.() {
	tree -a --gitignore --prune -I '.git' -F | head -n -1
}

tree.json() {
	tree -a --gitignore --prune -I '.git' -F -J
}

tree.yaml() {
	tree.json | yq --input-format json
}