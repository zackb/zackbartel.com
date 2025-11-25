.PHONY: blog

default:
	@echo "Hello"

deploy:
	rsync -av --exclude='.git/' build/ zackbart@zackbartel.com:~/web

serve:
	gozer serve

blog:
	gozer build
