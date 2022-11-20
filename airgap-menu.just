help:
	airgap -l

# Play a game to feed the entropy pool.
game:
	ninvaders

# Mount a thumbdrive to store the gnupg configuration.
mount:
	if mount | grep pendrive; then \
	  echo "Already mounted"; \
	else \
	  mkdir -p /mnt && cryptsetup open /dev/sda pendrive && mount /dev/mapper/pendrive /mnt; \
	fi

# Eject thumbdrive
umount:
	umount /mnt
	cryptsetup close pendrive

# Backup GPG configuration to a versioned secure thumbdrive
backup: mount
	rsync -av /root/.gnupg /mnt/
	cd /mnt && git add /mnt/.gnupg
	cd /mnt && git commit
