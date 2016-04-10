UNAME := $(shell uname)

ifeq ($(UNAME), Linux)
build:
	swift build -Xcc -I/usr/include/cairo \
							-Xcc -I/usr/include/gtk-3.0 \
							-Xcc -I/usr/include/glib-2.0 \
							-Xcc -I/usr/include/pango-1.0 \
							-Xcc -I/usr/include/gdk-pixbuf-2.0 \
							-Xcc -I/usr/include/atk-1.0 \
							-Xcc -I/usr/lib/x86_64-linux-gnu/glib-2.0/include \
							-Xcc -I/usr/include/webkitgtk-3.0

endif

ifeq ($(UNAME), Darwin)
build:
	swift build -Xcc -I/usr/local/include/cairo \
	-Xcc -I/usr/local/include/glib-2.0/gobject \
	-Xcc -I/usr/local/include/gtk-3.0 \
	-Xcc -I/usr/local/include/glib-2.0/ \
	-Xcc -I/usr/local/include/pango-1.0 \
	-Xcc -I/usr/local/include/gdk-pixbuf-2.0 \
	-Xcc -I/usr/local/include/atk-1.0 \
	-Xcc -I/usr/local/lib/glib-2.0/include

# build:
# 		swift build -Xcc $(pkg-config --cflags gtk+-3.0) -Xlinker $(pkg-config --libs gtk+-3.0)
endif

xcode:
	swift build -X -Xcc -I/usr/local/include/cairo \
	-Xcc -I/usr/local/include/glib-2.0/gobject \
	-Xcc -I/usr/local/include/gtk-3.0 \
	-Xcc -I/usr/local/include/glib-2.0/ \
	-Xcc -I/usr/local/include/pango-1.0 \
	-Xcc -I/usr/local/include/gdk-pixbuf-2.0 \
	-Xcc -I/usr/local/include/atk-1.0 \
	-Xcc -I/usr/local/lib/glib-2.0/include

clean:
	rm -rf .build

fullclean:
	rm -rf .build Packages

rebuild:
	make clean && make build

run:
	.build/debug/UIExplorerGtk
