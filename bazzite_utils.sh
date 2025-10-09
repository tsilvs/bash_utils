#!/usr/bin/env bash

# bazzite.hibernation.setup() {
# 	sudo btrfs subvolume create /var/swap
# 	sudo semanage fcontext -a -t var_t /var/swap
# 	sudo restorecon /var/swap
# 	SWAPSIZE=26G
# 	sudo btrfs filesystem mkswapfile --size $SWAPSIZE /var/swap/swapfile
# 	sudo semanage fcontext -a -t swapfile_t /var/swap/swapfile
# 	sudo restorecon /var/swap/swapfile
# 	echo "/var/swap/swapfile none swap defaults,nofail 0 0" | sudo tee -a /etc/fstab
# 	echo "" | sudo tee /etc/systemd/zram-generator.conf
# }

# bazzite.hibernation.setdown() {
# 	sudo sed -i "s|/var/swap/swapfile none swap defaults,nofail 0 0||" /etc/fstab
# 	sudo cp /usr/etc/systemd/zram-generator.conf /etc/systemd/zram-generator.conf
# }

# bazzite.hibernation.on() {}
# bazzite.hibernation.off() {}

