HUGO='bin/hugo'

build:
	@git submodule init
	@git submodule update

	@scripts/install_hugo.sh
	@${HUGO} --minify

serve: build
	@${HUGO} server

clean:
	@rm -rfv bin temp

update-theme:
	@git submodule init
	@git submodule update --remote

publish:
	@scripts/publish_ci.sh
