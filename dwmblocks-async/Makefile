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

BAT_SH := dgbwm_get_battery
MEM_SH := dgbwm_get_memory
NET_SH := dgbwm_get_internet
VOL_SH := dgbwm_get_audio_sink
MIC_SH := dgbwm_get_audio_source
WETH_SH := dgbwm_get_weather
TIME_SH := dgbwm_get_time
DATE_SH := dgbwm_get_date

CFLAGS += -DMEM_SH=\"$(MEM_SH)\" -DNET_SH=\"$(NET_SH)\" -DVOL_SH=\"$(VOL_SH)\" -DMIC_SH=\"$(MIC_SH)\" -DWETH_SH=\"$(WETH_SH)\" -DTIME_SH=\"$(TIME_SH)\" -DDATE_SH=\"$(DATE_SH)\" -DBAT_SH=\"$(BAT_SH)\"

ifeq ($(WEATHER_BLOCK),1)
	CFLAGS += -DWEATHER_BLOCK=1
else
	CFLAGS += -DWEATHER_BLOCK=0
endif

ifeq ($(IS_LAPTOP),1)
	CFLAGS += -DIS_LAPTOP=1
else
  CFLAGS += -DIS_LAPTOP=0
endif

ifeq ($(DYNAMIC),1)
    CFLAGS += -DDYNAMIC=1
else
    # Static binary strings
    CFLAGS += -DTERMINAL=\"$(TERMINAL)\"
   # CFLAGS += -DFM=\"$(FM)\"
    CFLAGS += -DRES_MONITOR=\"$(RES_MONITOR)\"
endif

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

	# battery
	cp -f scripts/battery.sh $(INSTALL_DIR)/$(BAT_SH)
	chmod 755 $(INSTALL_DIR)/$(BAT_SH)

	# memory
	cp -f scripts/memory.sh $(INSTALL_DIR)/$(MEM_SH)
	chmod 755 $(INSTALL_DIR)/$(MEM_SH)

	# volume
	cp -f scripts/volume.sh $(INSTALL_DIR)/$(VOL_SH)
	chmod 755 $(INSTALL_DIR)/$(VOL_SH)

	# mic
	cp -f scripts/mic.sh $(INSTALL_DIR)/$(MIC_SH)
	chmod 755 $(INSTALL_DIR)/$(MIC_SH)

	# internet
	cp -f scripts/internet.sh $(INSTALL_DIR)/$(NET_SH)
	chmod 755 $(INSTALL_DIR)/$(NET_SH)

	# weather
	cp -f scripts/weather.sh $(INSTALL_DIR)/$(WETH_SH)
	chmod 755 $(INSTALL_DIR)/$(WETH_SH)

	# date
	cp -f scripts/date.sh $(INSTALL_DIR)/$(DATE_SH)
	chmod 755 $(INSTALL_DIR)/$(DATE_SH)

	# time
	cp -f scripts/time.sh $(INSTALL_DIR)/$(TIME_SH)
	chmod 755 $(INSTALL_DIR)/$(TIME_SH)

	# ansi to pango parser 
	cp -f scripts/conv_ansi_to_pango.sh $(INSTALL_DIR)/dwm_conv_ansi_to_pango.sh
	chmod 755 $(INSTALL_DIR)/dwm_conv_ansi_to_pango.sh


uninstall:
	$(PRINTF) "RM" $(INSTALL_DIR)/$(BIN)
	$Q$(RM) $(INSTALL_DIR)/$(BIN)

	rm -f $(INSTALL_DIR)/$(BAT_SH)
	rm -f $(INSTALL_DIR)/$(MEM_SH)
	rm -f $(INSTALL_DIR)/$(VOL_SH)
	rm -f $(INSTALL_DIR)/$(MIC_SH)
	rm -f $(INSTALL_DIR)/$(NET_SH)
	rm -f $(INSTALL_DIR)/$(WETH_SH)
	rm -f $(INSTALL_DIR)/$(DATE_SH)
	rm -f $(INSTALL_DIR)/$(TIME_SH)
	rm -f $(INSTALL_DIR)/dwm_conv_ansi_to_pango.sh

.PHONY: all clean install uninstall
