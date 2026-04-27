#!/bin/sh

input=$(cat | tr -d '\r' | sed 's/\\/\\\\/g')

# Escape XML
input=$(printf "%s" "$input" | sed \
  -e 's/&/\&amp;/g' \
  -e 's/</\&lt;/g' \
  -e 's/>/\&gt;/g')

printf "%s" "$input" | awk '
BEGIN {
    ESC = sprintf("%c", 27)
    span_open = 0
}

function close_span() {
    if (span_open) {
        printf("</span>")
        span_open = 0
    }
}

function open_span(style) {
    close_span()
    printf("<span %s>", style)
    span_open = 1
}

function ansi256_to_hex(n) {
    # 0–15 basic colors (rough mapping)
    split("000000 ff0000 00ff00 ffff00 0000ff ff00ff 00ffff ffffff", base, " ")
    if (n < 8) return "#" base[n+1]
    if (n < 16) return "#" base[n-7]

    # 16–231 color cube
    if (n >= 16 && n <= 231) {
        n -= 16
        r = int(n/36)
        g = int((n%36)/6)
        b = n%6
        return sprintf("#%02x%02x%02x", r*51, g*51, b*51)
    }

    # 232–255 grayscale
    if (n >= 232 && n <= 255) {
        c = (n-232)*10 + 8
        return sprintf("#%02x%02x%02x", c, c, c)
    }

    return "#ffffff"
}

{
    line = $0

    while (match(line, ESC "\\[[0-9;]*m")) {
        pre = substr(line, 1, RSTART-1)
        seq = substr(line, RSTART+2, RLENGTH-3)
        line = substr(line, RSTART+RLENGTH)

        printf("%s", pre)

        split(seq, codes, ";")

        for (i=1; i<=length(codes); i++) {
            c = codes[i]

            if (c == 0) {
                close_span()
            }
            else if (c == 1) {
                open_span("weight=\"bold\"")
            }
            else if (c == 38 && codes[i+1] == 5) {
                color = ansi256_to_hex(codes[i+2])
                open_span("foreground=\"" color "\"")
                i += 2
            }
        }
    }

    printf("%s\n", line)
}

END {
    close_span()
}
'
