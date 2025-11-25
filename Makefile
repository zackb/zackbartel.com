.PHONY: build

default:
	@echo "Hello"

deploy: build
	rsync -av --exclude='.git/' build/ zackbart@zackbartel.com:~/web

serve:
	gozer serve

build:
	rm -Rf build
	gozer build
