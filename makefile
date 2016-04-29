VERSION=2
FILES=doc/diction.txt README.md LICENSE CHANGES.md $(wildcard database/*) $(wildcard **/*.vim)
GZIPPED=vim-diction-$(VERSION).tar.gz

default: echo

gzip:
	tar afvc $(GZIPPED) $(FILES)

echo:
	@echo Version: $(VERSION)
	@echo Files: $(FILES)
	@echo Gzip: $(GZIPPED)
