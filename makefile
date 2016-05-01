VERSION=4
FILES=doc/diction.txt README.md LICENSE CHANGES.md $(wildcard database/*) $(wildcard **/*.vim)
GZIPPED=vim-diction-$(VERSION).tar.gz

default: test

test:
	vim -u files/test.vimrc

testversion:
	vim --version
	vim -u files/test.vimrc

time:
	time vim -u files/time.vimrc files/pride_and_prejudice.txt +Diction +qa

gzip:
	tar afvc $(GZIPPED) $(FILES)

version:
	sed -i 's/\(Version:\t\)[[:digit:]]\+/\1$(VERSION)/' **/*.vim
	sed -i 's/Version: working/Version: $(VERSION)/' CHANGES.md

clean:
	rm -f *.log

echo:
	@echo Version: $(VERSION)
	@echo Files: $(FILES)
	@echo Gzip: $(GZIPPED)
