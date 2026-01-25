# Makefile for logbook compilation
#
# Usage: make

# TeX Live path (macOS)
PDFLATEX ?= /usr/local/texlive/2025/bin/universal-darwin/pdflatex

# Extract entry files from \input{entries/...} commands
logbookentries := $(shell grep -o 'input{entries/[^}]*}' logbook.tex | sed 's/input{//' | sed 's/}//')

all: logbook.pdf

logbook.pdf: logbook.tex $(logbookentries)
	$(PDFLATEX) -draftmode logbook.tex
	$(PDFLATEX) logbook.tex
	rm -f logbook.log logbook.out logbook.toc logbook.aux

clean:
	rm -f logbook.pdf logbook.log logbook.out logbook.toc logbook.aux

.PHONY: all clean
