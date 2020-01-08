SRC = org-linkotron.el

.PHONY: test update-test-results

test:
	cask exec test/run

update-test-results:
	cask exec test/run --update

# Replace the source header documentation with the documentation of the
# README.org.
update-docs: README.org
	TMPF=$$(mktemp) && \
        sed -i '/ Commentary:/,/ Code:/ c;;; Code:' $(SRC) && \
	sed -e '/^#\+.*:.*$$/d' \
            -e '/^* COMMENT Export Setup.*:noexport:/,$$ d' \
	    -e '/pragma:exclude-from-export/d' \
	    -e 's|^| |' \
            -e 's|^ \*|;|g' \
            -e 's|^[ ]*:||g' \
            -e 's|^|;;|g' \
            -e 's|;[ ]*$$|;|g' < README.org > $$TMPF && \
	sed -e "/;;; Code:/r $$TMPF" -e 'x;$$G' -e '1d' $(SRC) > $$TMPF.2 && \
	mv $$TMPF.2 $(SRC) && \
	rm -f $$TMPF $$TMPF.2
