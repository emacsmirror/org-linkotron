SRC = org-linkotron.el

.PHONY: test

bin/makem.sh:
	mkdir -p bin
	curl -o bin/makem.sh https://raw.githubusercontent.com/alphapapa/makem.sh/master/makem.sh
	chmod a+rx bin/makem.sh

test: bin/makem.sh
	bin/makem.sh --sandbox --auto-install --debug -vv all

# Replace the source header documentation with the documentation of the
# README.org. FIXME: org-links outside of code blocks could be formatted too.
update-docs: README.org
	TMPF=$$(mktemp) && \
        sed -i '/ Commentary:/,/ Code:/ c;;; Code:' $(SRC) && # Remove old docs from source. \
	cat README.org |                                      # Extract new docs from README.\
	sed '/^#\+.*:.*$$/d' |                                # Filter out org header args.  \
        sed '/^* COMMENT Export Setup.*:noexport:/,$$ d' |    # Remove export setup part.    \
	sed '/pragma:exclude-from-export/d' |                 # Remove lines marked for del. \
	sed 's|^| |' |                                        # Prefix text lines with space.\
        sed 's|^ \*|;|g' |                                    # Format headers.              \
        sed 's|^[ ]*:||g' |                                   # Handle code blocks.          \
        sed 's|^|;;|g' |                                      # Insert lisp comment chars.   \
        sed 's|;[ ]*$$|;|g' > $$TMPF &&                       # Remove whitespace.           \
	sed -e "/;;; Code:/r $$TMPF" -e 'x;$$G' -e '1d' $(SRC) > $$TMPF.2 && # Insert text.  \
	mv $$TMPF.2 $(SRC) && \
	rm -f $$TMPF $$TMPF.2
