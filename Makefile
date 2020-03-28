HUGO='bin/hugo'

build:
	@git submodule init
	@git submodule update

	@scripts/install_hugo.sh
	@${HUGO} --minify

serve:
	@${HUGO} server

clean:
	@rm -rfv bin temp

update-theme:
	@git submodule init
	@git submodule update --remote

publish: build
	@scripts/publish.sh
