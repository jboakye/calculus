#
#
# See comments at the top of gen_graph.rb for notes about
# figures, fonts, lulu, etc.
#
#
#

BOOK = calc
MODE = nonstopmode
TERMINAL_OUTPUT = err

MAKEINDEX = makeindex $(BOOK).idx

DO_PDFLATEX_RAW = pdflatex -interaction=$(MODE) $(BOOK) >$(TERMINAL_OUTPUT)
SHOW_ERRORS = \
        print "========error========\n"; \
        open(F,"$(TERMINAL_OUTPUT)"); \
        while ($$line = <F>) { \
          if ($$line=~m/^\! / || $$line=~m/^l.\d+ /) { \
            print $$line \
          } \
        } \
        close F; \
        exit(1)
DO_PDFLATEX = echo "$(DO_PDFLATEX_RAW)" ; perl -e 'if (system("$(DO_PDFLATEX_RAW)")) {$(SHOW_ERRORS)}'

# Since book1 comes first, it's the default target --- you can just do ``make'' to make it.

book1:
	@make preflight
	@$(DO_PDFLATEX)
	@scripts/harvest_aux_files.rb
	@rm -f $(TERMINAL_OUTPUT) # If pdflatex has a nonzero exit code, we don't get here, so the output file is available for inspection.

index:
	$(MAKEINDEX)

book:
	@make preflight
	make clean
	@$(DO_PDFLATEX)
	@scripts/harvest_aux_files.rb
	@$(DO_PDFLATEX)
	@scripts/harvest_aux_files.rb
	$(MAKEINDEX)
	@$(DO_PDFLATEX)
	@scripts/harvest_aux_files.rb
	@rm -f $(TERMINAL_OUTPUT) # If pdflatex has a nonzero exit code, we don't get here, so the output file is available for inspection.

test:
	perl -e 'if (system("pdflatex -interaction=$(MODE) $(BOOK) >$(TERMINAL_OUTPUT)")) {print "error\n"} else {print "no error\n"}'

web:
	@[ `which footex` ] || echo "******** footex is not installed, so html cannot be generated; get footex from http://www.lightandmatter.com/footex/footex.html"
	@[ `which footex` ] || exit 1
	scripts/prep_web.pl
	WOPT='--modern' scripts/make_web.pl # xhtml
	WOPT='--html5' scripts/make_web.pl # html 5
	scripts/make_web.pl # html 4

handheld:
	# see meki/zzz_misc/publishing for notes on how far I've progressed with this
	@rm -Rf calc_handheld
	mkdir calc_handheld
	scripts/prep_web.pl
	HANDHELD=1 HTML_DIR='calc_handheld' WOPT='--modern --override_config_with="handheld.config"' scripts/make_web.pl
	cp standalone.css calc_handheld

very_clean: clean
	rm -f calc.pdf calc_lulu.pdf
	rm -Rf calc_handheld

clean:
	# Sometimes we get into a state where LaTeX is unhappy, and erasing these cures it:
	rm -f *aux *idx *ilg *ind *log *toc
	rm -f ch*/*aux
	# Shouldn't exist in subdirectories:
	rm -f */*.log
	# Emacs backup files:
	rm -f *~
	rm -f */*~
	# Misc:
	rm -f ch*/figs/*.eps
	rm -Rf ch*/figs/.xvpics
	rm -f a.a
	rm -f */a.a
	rm -f */*/a.a
	rm -f junk
	rm -f err
	# ... done.
	rm -f calc_lulu.pdf
	rm -f calc.pdf
	rm -f temp.pdf
	rm -f ch*/ch*temp.temp

post:
	cp calc.pdf /home/bcrowell/Lightandmatter/calc

prepress:
	# The following makes Lulu not complain about missing fonts:
	pdftk calc.pdf cat 3-end output temp.pdf
	gs -q -dCompatibilityLevel=1.4 -dSubsetFonts=false -dPDFSETTINGS=/printer -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile=calc_lulu.pdf temp.pdf -c '.setpdfwrite'


post_source:
	# don't forget to commit first, git commit -a -m "comment"
	# repo is hosted on github, see book's web page
	git push

preflight:
	@perl -e 'foreach $$f(<scripts/custom/*>) {system($$f)}'
