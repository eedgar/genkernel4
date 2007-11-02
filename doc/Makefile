all: build

clean:
	rm genkernel.8 genkernel.8.html HOWTO-Genkernel-SSI.html

build:
	@echo "Generating HTML..."
	asciidoc -b xhtml11 genkernel.8.txt
	asciidoc -b xhtml11 HOWTO-Genkernel-SSI.txt

	@echo "Generating manpage..."
	a2x -f manpage genkernel.8.txt --xsltproc-opts='--param man.justify true'
