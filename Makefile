export THEOS_DEVICE_IP = p92
export ARCHS = armv7 armv7s arm64
include ${THEOS}/makefiles/common.mk
export DEBUG = 0
TWEAK_NAME = SimulateTouch
SimulateTouch_FILES = SimulateTouch.mm common.mm
SimulateTouch_PRIVATE_FRAMEWORKS = GraphicsServices IOKit
SimulateTouch_LDFLAGS = -lsubstrate -lrocketbootstrap

LIBRARY_NAME = libsimulatetouch
libsimulatetouch_FILES = STLibrary.mm common.mm
libsimulatetouch_LDFLAGS = -lrocketbootstrap 
libsimulatetouch_INSTALL_PATH = /usr/lib/
libsimulatetouch_FRAMEWORKS = UIKit CoreGraphics

# TOOL_NAME = stouch
# stouch_FILES = main.mm
# stouch_FRAMEWORKS = UIKit
# stouch_INSTALL_PATH = /usr/bin/
# stouch_LDFLAGS = -lsimulatetouch

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/library.mk
include $(THEOS_MAKE_PATH)/tool.mk
before-package::
	chmod 0755 postinst;
	cp postinst $(THEOS_STAGING_DIR)/DEBIAN/
after-package::
	#rm -fr .theos

after-install::
	install.exec "killall -9 backboardd"
