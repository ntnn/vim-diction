FILES=autoload/diction.vim doc/diction.txt plugin/diction.vim README.md LICENSE CHANGES
GZIPPED=vim-diction.tar.gz

default: gzip

gzip: $(FILES)
	tar afvc $(GZIPPED) $^
