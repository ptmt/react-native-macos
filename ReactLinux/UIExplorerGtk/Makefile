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
	swift build \
	-Xcc -I/usr/local/include/cairo \
	-Xcc -I/usr/local/include/glib-2.0/gobject \
	-Xcc -I/usr/local/include/gtk-3.0 \
	-Xcc -I/usr/local/include/glib-2.0/ \
	-Xcc -I/usr/local/include/pango-1.0 \
	-Xcc -I/usr/local/include/gdk-pixbuf-2.0 \
	-Xcc -I/usr/local/include/atk-1.0 \
	-Xcc -I/usr/local/lib/glib-2.0/include \
	-Xlinker -L/usr/local/Cellar/gtk+3/3.18.9/lib \
	-Xlinker -L/usr/local/Cellar/pango/1.38.1/lib \
	-Xlinker -L/usr/local/Cellar/atk/2.18.0_1/lib \
	-Xlinker -L/usr/local/Cellar/cairo/1.14.6_1/lib \
	-Xlinker -L/usr/local/Cellar/gdk-pixbuf/2.32.3/lib \
	-Xlinker -L/usr/local/Cellar/glib/2.46.2/lib \
	-Xlinker -L/usr/local/opt/gettext/lib \
	-Xlinker -lgtk-3 \
	-Xlinker -lgdk-3 \
	-Xlinker -lpangocairo-1.0 \
	-Xlinker -lpango-1.0 \
	-Xlinker -latk-1.0 \
	-Xlinker -lcairo-gobject \
	-Xlinker -lcairo \
	-Xlinker -lgdk_pixbuf-2.0 \
	-Xlinker -lgio-2.0 \
	-Xlinker -lgobject-2.0 \
	-Xlinker -lglib-2.0 \
	-Xlinker -lintl

# build:
# 		swift build -Xcc $(pkg-config --cflags gtk+-3.0) -Xlinker $(pkg-config --libs gtk+-3.0)
endif

xcode:
	swift build --generate-xcodeproj \
  -Xcc -I/usr/local/include/cairo \
	-Xcc -I/usr/local/include/glib-2.0/gobject \
	-Xcc -I/usr/local/include/gtk-3.0 \
	-Xcc -I/usr/local/include/glib-2.0/ \
	-Xcc -I/usr/local/include/pango-1.0 \
	-Xcc -I/usr/local/include/gdk-pixbuf-2.0 \
	-Xcc -I/usr/local/include/atk-1.0 \
	-Xcc -I/usr/local/lib/glib-2.0/include \
	-Xlinker -L/usr/local/Cellar/gtk+3/3.18.9/lib \
	-Xlinker -L/usr/local/Cellar/pango/1.38.1/lib \
	-Xlinker -L/usr/local/Cellar/atk/2.18.0_1/lib \
	-Xlinker -L/usr/local/Cellar/cairo/1.14.6_1/lib \
	-Xlinker -L/usr/local/Cellar/gdk-pixbuf/2.32.3/lib \
	-Xlinker -L/usr/local/Cellar/glib/2.46.2/lib \
	-Xlinker -L/usr/local/opt/gettext/lib \
	-Xlinker -lgtk-3 \
	-Xlinker -lgdk-3 \
	-Xlinker -lpangocairo-1.0 \
	-Xlinker -lpango-1.0 \
	-Xlinker -latk-1.0 \
	-Xlinker -lcairo-gobject \
	-Xlinker -lcairo \
	-Xlinker -lgdk_pixbuf-2.0 \
	-Xlinker -lgio-2.0 \
	-Xlinker -lgobject-2.0 \
	-Xlinker -lglib-2.0 \
	-Xlinker -lintl


clean:
	rm -rf .build

fullclean:
	rm -rf .build Packages

rebuild:
	make clean && make build

run:
	.build/debug/UIExplorerGtk

test:
	swift test
