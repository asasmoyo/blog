HUGO='bin/hugo'

build:
	@scripts/install_hugo.sh
	@${HUGO}

serve:
	@${HUGO} server

clean:
	@rm -rfv bin temp

update-theme:
	@git submodule init
	@git submodule update --remote
