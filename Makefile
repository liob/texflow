CP = cp
PDFLATEX = pdflatex
LATEXOPTS = --file-line-error --shell-escape
PDFINFO = pdfinfo
BIBER = biber
MAKEINDEX = makeindex
HTLATEX = htlatex
texes := $(wildcard *.tex parts/*.tex)
bibs := $(wildcard *[^-blx].bib)
### set default values ###
MAKEDIRS = 
ZOTUSER = 
ZOTEROKEY = 
ZOTFILENAME = 
WEBDAVUSER = 
WEBDAVTARGET = 

include Makefile.conf

.PHONY: all final bib zotero clean clean-all pre install oo

all: $(main).pdf

$(main).pdf: pre $(texes) $(main).bbl $(main).gls  #exclude bibliography and glossary
	$(PDFLATEX) $(LATEXOPTS) $(main)

final: $(main).pdf
	gs -o final_$(main).pdf -sDEVICE=pdfwrite -dPDFSETTINGS=/printer -f $(main).pdf

draft: $(main).pdf
	gs -o draft_$(main).pdf -sDEVICE=pdfwrite -dPDFSETTINGS=/screen -g$(PAPERSIZE) -dPDFFitPage -f $(main).pdf

pre:
	for i in $(MAKEDIRS); do make -C $$i; done

$(main).bbl: $(bibs)
	$(PDFLATEX) $(LATEXOPTS) $(main)
	$(BIBER) $(main)

bib: zotero

# rebuild the *.bib file from zotero
zotero: dlbibinfo
	$(shell \
	run=true; \
	offset=0; \
	IFS=$$'\n'; \
	echo "" > $(ZOTFILENAME); \
	while [ $$run ]; do \
	  response=$$(curl --silent "https://api.zotero.org/users/$(ZOTUSER)/items?format=bibtex&limit=100&key=$(ZOTEROKEY)&start=$$offset"); \
	  for item in $$response; do \
	  	echo $$item >> $(ZOTFILENAME); \
	  done; \
	  offset=`expr $$offset + 100`; \
	  if [ -z "$$response" ]; \
	  then \
	  	run=; \
	  fi \
	done )
	
dlbibinfo:
	@echo "downloading bibliography information"
	

# generating index for glossary:
$(main).gls: $(main).acn
	makeglossaries $(main)
	$(RM) $(main).glg $(main).alg
	$(PDFLATEX) $(LATEXOPTS) $(main)


clean:
	$(RM) *.aux *.bbl *.blg *.bcf *-blx.bib *.dvi *.ilg *.ind *.lof *.lol *.log *.out *.run.xml *.toc *.acn *.glo *.ist *.acr *.alg *.lot *.gls *.upb *.upa *.synctex.gz
	$(RM) parts/*.aux
	# htlatex:
	$(RM) $(main).4ct $(main).4tc $(main).idv $(main).lg $(main).tmp $(main).xref $(main)-*.svg
	for i in $(MAKEDIRS); do make -C $$i clean; done

clean-all: clean
	$(RM) $(main).pdf $(main).odt $(main).html $(main).css final_$(main).pdf draft_$(main).pdf

install:
	curl -k -u $(WEBDAVUSER) -T $(main).pdf $(WEBDAVTARGET)
