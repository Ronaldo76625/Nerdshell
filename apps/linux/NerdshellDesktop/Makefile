CC ?= cc
PKG_CONFIG ?= pkg-config
PREFIX ?= /usr
BUILD_DIR ?= build
CFLAGS += -O2 -Wall -Wextra -Wpedantic -std=c11
GTK_CFLAGS := $(shell $(PKG_CONFIG) --cflags gtk+-3.0 vte-2.91)
GTK_LIBS := $(shell $(PKG_CONFIG) --libs gtk+-3.0 vte-2.91)

.PHONY: all clean install

all: $(BUILD_DIR)/nerdshell

$(BUILD_DIR)/nerdshell: src/main.c
	mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) $(GTK_CFLAGS) $< -o $@ $(GTK_LIBS)

install: $(BUILD_DIR)/nerdshell
	install -Dm755 $(BUILD_DIR)/nerdshell $(DESTDIR)$(PREFIX)/bin/nerdshell
	install -Dm644 resources/io.github.nerdshell.desktop $(DESTDIR)$(PREFIX)/share/applications/io.github.nerdshell.desktop
	install -Dm644 resources/io.github.nerdshell.metainfo.xml $(DESTDIR)$(PREFIX)/share/metainfo/io.github.nerdshell.metainfo.xml

clean:
	rm -rf $(BUILD_DIR)
