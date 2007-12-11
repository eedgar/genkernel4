all: build

clean:
	rm -f genkernel.8 genkernel.8.html HOWTO-genkernel-SFI-and-root-over-nfs.html HOWTO-genkernel-SFI-and-root-over-nfs.xml

build:
	@echo "Generating HTML..."
	asciidoc -b xhtml11 genkernel.8.txt

	@echo "Generating manpage..."
	a2x -f manpage genkernel.8.txt --xsltproc-opts='--param man.justify true'
	rm -f genkernel.8.xml

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
webdoc:
	@echo "Generating HTML version for website..."

	a2x --stylesheet=stylesheet-asciidoc.css genkernel.8.txt
	a2x --stylesheet=stylesheet-asciidoc.css HOWTO-genkernel-SFI-and-root-over-nfs.txt

	scp HOWTO-genkernel-SFI-and-root-over-nfs.html genkernel.8.html shell.berlios.de:/home/groups/genkernel/htdocs
	ssh shell.berlios.de chmod g+w /home/groups/genkernel/htdocs/genkernel.8.html /home/groups/genkernel/htdocs/HOWTO-genkernel-SFI-and-root-over-nfs.html

	rm genkernel.8.xml HOWTO-genkernel-SFI-and-root-over-nfs.xml
