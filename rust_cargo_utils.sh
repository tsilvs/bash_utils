#!/usr/bin/env bash

cargo.exec.allow() {
	chmod 755 /root
	chmod 755 /root/.cargo
	chmod 755 /root/.cargo/bin
	# + add `/root/.cargo/bin` to PATH in: /etc/sudoers /etc/bashrc
	# or use `sudo visudo` to edit `secure_path`
}

export -f cargo.exec.allow
