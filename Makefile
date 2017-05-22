build:
	rsync -rav --exclude="hardware-configuration.nix" --copy-links --delete ./etc/nixos/ ajarara@jarmac.org:/etc/nixos

.PHONY: build
