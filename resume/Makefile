# npm install -g resume-cli
# cd theme && npm install
# npm install -g jsonresume-theme-short
# make short
default:
	resume serve --theme modern

json_resume:
	json_resume convert --out=tex_pdf zackbartel.json

pdf:
	resume export resume --format pdf --theme modern

html:
	resume export resume --format html --theme modern

short:
	resume export resume --format pdf --theme short
