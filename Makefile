build:
	rsync -rav --copy-links --delete ./etc/nixos/ ajarara@jarmac.org:/etc/nixos

.PHONY: build
