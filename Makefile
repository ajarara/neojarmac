build:
	rsync -rav --copy-links --delete ./etc/nixos/ ajarara@45.32.38.19:/etc/nixos

.PHONY: build
