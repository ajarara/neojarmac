build:
	rsync -rav --copy-links --delete ./etc/nixos/ ajarara@neojarmac:/etc/nixos

.PHONY: build
