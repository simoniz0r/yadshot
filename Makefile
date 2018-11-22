PREFIX ?= /usr

all:
		@echo Run \'make install\' to install yadshot.

install:
		@echo 'Making directories...'
		@mkdir -p $(DESTDIR)$(PREFIX)/bin
		@mkdir -p $(DESTDIR)$(PREFIX)/share/applications
		@mkdir -p $(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps

		@echo 'Installing yadshot...'
		@chmod +x yadshot.sh
		@chmod +x filebiner
		@cp -p yadshot.sh $(DESTDIR)$(PREFIX)/bin/yadshot
		@cp -p filebiner $(DESTDIR)$(PREFIX)/bin/filebiner
		@cp -p yadshot.desktop $(DESTDIR)$(PREFIX)/share/applications/yadshot.desktop
		@cp -p yadshot.svg $(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps/yadshot.svg
		@echo 'yadshot installed!'

uninstall:
		@echo 'Removing files...'
		@rm -f $(DESTDIR)$(PREFIX)/bin/yadshot
		@rm -f $(DESTDIR)$(PREFIX)/bin/filebiner
		@rm -f $(DESTDIR)$(PREFIX)/share/applications/yadshot.desktop
		@rm -f $(DESTDIR)$(PREFIX)/share/icons/hicolor/64x64/apps/yadshot.png
		@rm -f $(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps/yadshot.svg
		@echo 'yadshot uninstalled!'
