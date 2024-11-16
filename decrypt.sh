#!/bin/bash

EXCLUDE_DIRS=("node_modules" ".idea" ".vagrant")
EXCLUDE_FILES=("Vagrantfile" "Dockerfile" ".gitignore" "decrypt.sh" "encrypt.sh")

should_exclude() {
    local item="$1"
    local basename=$(basename "$item")

    for dir in "${EXCLUDE_DIRS[@]}"; do
        if [[ "$basename" == "$dir" ]]; then
            return 0
        fi
    done

    for file in "${EXCLUDE_FILES[@]}"; do
        if [[ "$basename" == "$file" ]]; then
            return 0
        fi
    done

    return 1
}

decrypt_file() {
    local file="$1"
    local first_char="${file:0:1}"
    local ascii=$(printf "%d" "'$first_char")

    echo "解密文件: $file"
    temp_file="${file}.tmp"

    xxd -p "$file" | tr -d '\n' | sed 's/\(..\)/\1 /g' | while read -n 3 hex; do
        if [ ! -z "$hex" ]; then
            printf "%02x" "$((0x$hex ^ ascii))"
        fi
    done | xxd -r -p > "$temp_file"

    mv "$temp_file" "$file"
}

process_directory() {
    local dir="$1"

    for item in "$dir"/*; do
        if should_exclude "$item"; then
            echo "跳过: $item"
            continue
        fi

        if [[ -d "$item" ]]; then
            process_directory "$item"
        elif [[ -f "$item" ]]; then
            decrypt_file "$item"
        fi
    done
}

echo "开始解密..."
process_directory "."
echo "解密完成"
