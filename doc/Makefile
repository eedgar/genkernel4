all: build

clean:
	rm genkernel.8 genkernel.8.html 

build:
	@echo "Generating HTML..."
	asciidoc -b xhtml11 genkernel.8.txt

	@echo "Generating manpage..."
	a2x -f manpage genkernel.8.txt --xsltproc-opts='--param man.justify true'
	rm genkernel.8.xml

#
# For the following to work, you will a password-less key setup to login to
# shell.berlios.de
#
# If your username there is different from the one on your work system,
# you might want to add this at the end of ~/.ssh/config:
#
#     Host shell.berlios.de
#         User trucker
#
webmanpage:
	@echo "Generating HTML version for website..."
	a2x --stylesheet=stylesheet-asciidoc.css genkernel.8.txt
	scp genkernel.8.html shell.berlios.de:/home/groups/genkernel/htdocs
	ssh shell.berlios.de chmod g+w /home/groups/genkernel/htdocs/genkernel.8.html
	rm genkernel.8.xml
