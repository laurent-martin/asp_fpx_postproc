-include local/Makefile.local
FILESZIP=faspex_postprocessing.rb faspex_postprocessing.ba_ faspex_postprocessing.yaml README.md README.pdf

all::

clean:
	rm -f FaspexMoveTool*.zip faspex_postprocessing.ba_ README.pdf README.html faspex_postprocessing.log 
	rm -fr test/tmp

pack: doc
	cp faspex_postprocessing.bat faspex_postprocessing.ba_
	zip FaspexMoveTool_$$(date +%Y%m%d).zip $(FILESZIP)

doc: README.pdf

README.pdf: README.md
	pandoc -T XXX --number-sections --resource-path=. --toc -V margin-left=.2in -V margin-right=.2in -V margin-top=.2in -V margin-bottom=.2in -V fontsize=12pt -V papersize=A4 --pdf-engine=wkhtmltopdf --metadata pagetitle=README -o README.pdf README.md
# --css=file:style.css 
test: test/tmp/.done

test/tmp/.done:
	./test/dotest.sh
	touch test/tmp/.done

gitpush: doc
	git push
