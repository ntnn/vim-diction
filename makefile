VERSION=3
FILES=doc/diction.txt README.md LICENSE CHANGES.md $(wildcard database/*) $(wildcard **/*.vim)
GZIPPED=vim-diction-$(VERSION).tar.gz

default: echo

gzip:
	tar afvc $(GZIPPED) $(FILES)

version:
	sed -i 's/\(Version:\t\)[[:digit:]]\+/\1$(VERSION)/' **/*.vim
	sed -i 's/Version: working/Version: $(VERSION)/' CHANGES.md

echo:
	@echo Version: $(VERSION)
	@echo Files: $(FILES)
	@echo Gzip: $(GZIPPED)
