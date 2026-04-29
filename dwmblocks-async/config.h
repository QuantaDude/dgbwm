#ifndef CONFIG_H
#define CONFIG_H

#ifndef DYNAMIC
#define DYNAMIC 0
#endif

#ifndef IS_LAPTOP
#define IS_LAPTOP 0
#endif

#if DYNAMIC
#define MEM_CMD MEM_SH "auto auto"
#define NET_CMD NET_SH "auto auto"
#else
#ifndef RES_MONITOR
#define RES_MONITOR "top"
#endif

#ifndef TERMINAL
#define TERMINAL "st"
#endif


#define MEM_CMD MEM_SH " " RES_MONITOR " " TERMINAL
#define NET_CMD NET_SH " auto " TERMINAL//the network backend is decided at runtime in script 

#endif

#if WEATHER_BLOCK
#define WEATHER_BLOCK_ENTRY(X) X("" , WETH_SH, 300, 6)
#else
#define WEATHER_BLOCK_ENTRY(X)
#endif

#if IS_LAPTOP
#define BAT_BLOCK_ENTRY(X) X("", BAT_SH, 5, 1)
#else
#define BAT_BLOCK_ENTRY(X)
#endif
// String used to delimit block outputs in the status.
#define DELIMITER " | "

// Maximum number of Unicode characters that a block can output.
#define MAX_BLOCK_OUTPUT_LENGTH 40

// Control whether blocks are clickable.
#define CLICKABLE_BLOCKS 1

// Control whether a leading delimiter should be prepended to the status.
#define LEADING_DELIMITER 0

// Control whether a trailing delimiter should be appended to the status.
 #define TRAILING_DELIMITER 1

// Define blocks for the status feed as X(icon, cmd, interval, signal).
#define BLOCKS(X) \
    BAT_BLOCK_ENTRY(X) \
    X("" , MEM_CMD, 10, 2) \
    X("", VOL_SH , 0, 3) \
    X("", MIC_SH, 0, 4) \
    X("", NET_CMD, 5, 5) \
    WEATHER_BLOCK_ENTRY(X) \
    X(" ", DATE_SH, 60, 7) \
    X("", TIME_SH, 30, 8) \

#endif 

