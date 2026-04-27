#ifndef CONFIG_H
#define CONFIG_H

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
    X("" , "dwm_get_memory.sh", 10, 1) \
    X("", "dwm_get_volume.sh", 0, 2) \
    X("", "dwm_get_mic.sh", 0, 3) \
    X("", "dwm_get_internet.sh", 5, 5) \
    X("" , "dwm_get_weather.sh", 300, 6) \
    X(" ", "dwm_get_date.sh", 60, 7) \
    X("", "dwm_get_time.sh", 30, 8) \

#endif  // CONFIG_H
   /* X("", "sb-swap", 10, 0)   \
    X(" ┇ ", "xset -q|grep LED| awk '{ if (substr ($10,5,1) == 1) print \"[RU]\"; else print \"[EN]\"; }'", 0, 1) \	
      X("", "sb-loadavg", 5, 5) \
    X("", "sb-mic", 0, 6)     \
    X("", "sb-record", 0, 7)  \
    X("", "sb-volume", 0, 8)  \
    X("", "sb-battery", 5, 9) \
    */
