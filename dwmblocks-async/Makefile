.POSIX:

BIN := dwmblocks
BUILD_DIR := build
SRC_DIR := src
INC_DIR := include

DEBUG := 0
VERBOSE := 0
LIBS := xcb-atom

PREFIX := /usr/local
CFLAGS := -Ofast -I. -I$(INC_DIR) -std=c99
CFLAGS += -DBINARY=\"$(BIN)\" -D_POSIX_C_SOURCE=200809L
CFLAGS += -Wall -Wpedantic -Wextra -Wswitch-enum
CFLAGS += $(shell pkg-config --cflags $(LIBS))
LDLIBS := $(shell pkg-config --libs $(LIBS))

SRCS := $(wildcard $(SRC_DIR)/*.c)
OBJS := $(subst $(SRC_DIR)/,$(BUILD_DIR)/,$(SRCS:.c=.o))

INSTALL_DIR := $(DESTDIR)$(PREFIX)/bin

# Prettify output
PRINTF := @printf "%-8s %s\n"
ifeq ($(VERBOSE), 0)
	Q := @
endif

ifeq ($(DEBUG), 1)
	CFLAGS += -g
endif

all: $(BUILD_DIR)/$(BIN)

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c config.h
	$Qmkdir -p $(@D)
	$(PRINTF) "CC" $@
	$Q$(COMPILE.c) -o $@ $<

$(BUILD_DIR)/$(BIN): $(OBJS)
	$(PRINTF) "LD" $@
	$Q$(LINK.o) $^ $(LDLIBS) -o $@

clean:
	$(PRINTF) "CLEAN" $(BUILD_DIR)
	$Q$(RM) $(BUILD_DIR)/*

install: $(BUILD_DIR)/$(BIN)
	$(PRINTF) "INSTALL" $(INSTALL_DIR)/$(BIN)
	$Qinstall -D -m 755 $< $(INSTALL_DIR)/$(BIN)

	# memory
	cp -f scripts/memory.sh $(INSTALL_DIR)/dwm_get_memory.sh
	chmod 755 $(INSTALL_DIR)/dwm_get_memory.sh

	# volume
	cp -f scripts/volume.sh $(INSTALL_DIR)/dwm_get_volume.sh
	chmod 755 $(INSTALL_DIR)/dwm_get_volume.sh

	# mic
	cp -f scripts/mic.sh $(INSTALL_DIR)/dwm_get_mic.sh
	chmod 755 $(INSTALL_DIR)/dwm_get_mic.sh

	# internet
	cp -f scripts/internet.sh $(INSTALL_DIR)/dwm_get_internet.sh
	chmod 755 $(INSTALL_DIR)/dwm_get_internet.sh

	# weather
	cp -f scripts/weather.sh $(INSTALL_DIR)/dwm_get_weather.sh
	chmod 755 $(INSTALL_DIR)/dwm_get_weather.sh

	# date
	cp -f scripts/date.sh $(INSTALL_DIR)/dwm_get_date.sh
	chmod 755 $(INSTALL_DIR)/dwm_get_date.sh

	# time
	cp -f scripts/time.sh $(INSTALL_DIR)/dwm_get_time.sh
	chmod 755 $(INSTALL_DIR)/dwm_get_time.sh

	# ansi to pango parser 
	cp -f scripts/conv_ansi_to_pango.sh $(INSTALL_DIR)/dwm_conv_ansi_to_pango.sh
	chmod 755 $(INSTALL_DIR)/dwm_conv_ansi_to_pango.sh
	

uninstall:
	$(PRINTF) "RM" $(INSTALL_DIR)/$(BIN)
	$Q$(RM) $(INSTALL_DIR)/$(BIN)

	rm -f $(INSTALL_DIR)/dwm_get_memory.sh
	rm -f $(INSTALL_DIR)/dwm_get_volume.sh
	rm -f $(INSTALL_DIR)/dwm_get_mic.sh
	rm -f $(INSTALL_DIR)/dwm_get_internet.sh
	rm -f $(INSTALL_DIR)/dwm_get_weather.sh
	rm -f $(INSTALL_DIR)/dwm_get_date.sh
	rm -f $(INSTALL_DIR)/dwm_get_time.sh
	rm -f $(INSTALL_DIR)/dwm_conv_ansi_to_pango.sh

.PHONY: all clean install uninstall
