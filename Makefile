#!/usr/bin/make

saxon = saxonb-xslt -ext:on

test:

FORCE::

test: FORCE
	mkdir -p out
	$(saxon) -xsl:htmlsplit.xslt -s:manual.html output-directory=out config-filename=settings-local.xml
