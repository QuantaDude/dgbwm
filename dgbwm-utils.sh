#!/bin/sh

detect_programs() {
    found=""
    for prog in $1; do
        if command -v "$prog" >/dev/null 2>&1; then
            found="$found $prog"
        fi
    done
    echo "$found"
}

validate_exec() {
    if command -v "$1" >/dev/null 2>&1; then
        return 0
    else
        echo "[!] '$1' not found in PATH" >&2
        return 1
    fi
}

choose_program() {
    category="$1"
    default="$2"
    shift 2

    options="$@"

    if [ -z "$options" ]; then
    echo "[!] No known programs found for $category" >&2
    while :; do
        printf "Enter executable manually: " >&2
        read manual
        if validate_exec "$manual"; then
            echo "$manual"
            return
        fi
    done
fi

    # Add previous choice if not in list
    found_prev=0
    for p in $options; do
        [ "$p" = "$default" ] && found_prev=1
    done

    if [ -n "$default" ] && [ "$found_prev" -eq 0 ]; then
        options="$default $options"
    fi

    echo "" >&2
    echo "[*] Select $category:" >&2

    i=1
    default_index=1

    for prog in $options; do
        echo "  $i) $prog" >&2
        eval "opt_$i=\"$prog\""

        [ "$prog" = "$default" ] && default_index=$i

        i=$((i+1))
    done

    echo "  $i) <other>" >&2
    other_index=$i

    printf "Choice [default %d]: " "$default_index" >&2
    read choice

    # default on empty
    [ -z "$choice" ] && choice=$default_index
    case "$choice" in
        ''|*[!0-9]*)
            echo "$default"
            return
            ;;
    esac

    if [ "$choice" -lt 1 ] || [ "$choice" -gt "$other_index" ]; then
        echo "$default"
        return
    fi
    
    if [ "$choice" -eq "$other_index" ]; then
        while :; do
            printf "Enter executable name: " >&2
            read manual

            if validate_exec "$manual"; then
                echo "$manual"
                return
            fi
        done
    fi

    eval "echo \"\$opt_$choice\""
}

get_desktop_file() {
    app="$1"

    best=""
    fallback=""

    for dir in "$HOME/.local/share/applications" /usr/share/applications; do
        [ -d "$dir" ] || continue

        for file in "$dir"/*.desktop; do
            [ -e "$file" ] || continue

            exec_line=$(grep -i '^Exec=' "$file" | head -n1)
            [ -z "$exec_line" ] && continue

            exec_line=${exec_line#Exec=}

            clean_exec=$(printf "%s\n" "$exec_line" | tr -d '"')

            echo "$clean_exec" | grep -qw "$app" || continue

            name=$(basename "$file")

            if [ "$name" = "$app.desktop" ]; then
                echo "$name"
                return 0
            fi

            case "$name" in
                *-mail.desktop|*-client.desktop|*-server.desktop)
                    fallback="$name"
                    ;;
                *)
                    best="$name"
                    ;;
            esac
        done
    done

    # prefer best, fallback otherwise
    if [ -n "$best" ]; then
        echo "$best"
    elif [ -n "$fallback" ]; then
        echo "$fallback"
    else
        echo ""
    fi

    return 0
}

get_terminal_requirement() {
    desktop="$1"

    for dir in "$HOME/.local/share/applications" /usr/share/applications; do
        file="$dir/$desktop"
        [ -f "$file" ] || continue

        val=$(grep -i '^Terminal=' "$file" | head -n1 | cut -d= -f2)

        case "$val" in
            true|True|TRUE) echo 1 ;;
            *) echo 0 ;;
        esac
        return
    done

    # if somehow not found
    echo ""
}

set_mime_from_desktop() {
    desktop="$1"
    prefix="$2"   # e.g. text/, audio/, video/

    for dir in "$HOME/.local/share/applications" /usr/share/applications; do
        file="$dir/$desktop"
        [ -f "$file" ] || continue

        mime_list=$(grep '^MimeType=' "$file" | cut -d= -f2 | tr ';' ' ')

        for m in $mime_list; do
            case "$m" in
                "$prefix"*)
                    xdg-mime default "$desktop" "$m"
                    ;;
            esac
        done
        return
    done
}
