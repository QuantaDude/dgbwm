#!/bin/sh

FILE="$1"

if [ -d "$FILE" ]; then
    eza --tree --level=2 --icons --color=always "$FILE"
    exit 0
fi

case "$FILE" in
    *.pdf)
        pdftotext "$FILE" - | head -200
        ;;

    *.zip)
        unzip -l "$FILE"
        ;;

    *.tar)
        tar -tvf "$FILE"
        ;;

    *.tar.gz|*.tgz)
        tar -tzvf "$FILE"
        ;;

    *.tar.xz)
        tar -tJvf "$FILE"
        ;;

    *.rar)
        unrar l "$FILE"
        ;;

    *.7z)
        7z l "$FILE"
        ;;

    *)
        bat --style=numbers --color=always "$FILE"
        ;;
esac
