PREFIX ?= /usr

all:
		@echo Run \'make install\' to install yadshot.

install:
		@echo 'Making directories...'
		@mkdir -p $(DESTDIR)$(PREFIX)/bin
		@mkdir -p $(DESTDIR)$(PREFIX)/share/applications
		@mkdir -p $(DESTDIR)$(PREFIX)/share/icons/hicolor/64x64/apps

		@echo 'Installing yadshot...'
		@chmod +x yadshot.sh
		@cp -p yadshot.sh $(DESTDIR)$(PREFIX)/bin/yadshot
		@cp -p yadshot.desktop $(DESTDIR)$(PREFIX)/share/applications/yadshot.desktop
		@cp -p yadshot.png $(DESTDIR)$(PREFIX)/share/icons/hicolor/64x64/apps/yadshot.png
		@echo 'yadshot installed!'

uninstall:
		@echo 'Removing files...'
		@rm -f $(DESTDIR)$(PREFIX)/bin/yadshot
		@rm -f $(DESTDIR)$(PREFIX)/share/applications/yadshot.desktop
		@rm -f $(DESTDIR)$(PREFIX)/share/icons/hicolor/64x64/apps/yadshot.png
		@echo 'yadshot uninstalled!'
