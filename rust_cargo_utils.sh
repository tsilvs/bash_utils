#!/usr/bin/env bash

cargo.allow.exec() {
	sudo chmod 755 /root
	sudo chmod 755 /root/.cargo
	sudo chmod 755 /root/.cargo/bin
	# + add `/root/.cargo/bin` to PATH in: /etc/sudoers /etc/bashrc
	# or use `sudo visudo` to edit `secure_path`
}

export -f cargo.allow.exec
