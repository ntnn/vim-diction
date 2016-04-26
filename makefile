FILES=autoload/diction.vim doc/diction.txt plugin/diction.vim README.md LICENSE CHANGES.md $(wildcard database/*)
GZIPPED=vim-diction.tar.gz

default: gzip

gzip:
	tar afvc $(GZIPPED) $(FILES)
