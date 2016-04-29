VERSION=2
FILES=doc/diction.txt README.md LICENSE CHANGES.md $(wildcard database/*) $(wildcard **/*.vim)
GZIPPED=vim-diction-$(VERSION).tar.gz

default: gzip

gzip:
	tar afvc $(GZIPPED) $(FILES)
