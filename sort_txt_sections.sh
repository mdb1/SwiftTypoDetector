#!/bin/bash

input_file="$1"

# Validate input
if [[ ! -f "$input_file" ]]; then
  echo "File not found!"
  exit 1
fi

temp_file="temp.txt"
> "$temp_file"

section=""
was_empty_line=false

sort_and_write() {
  prev_char=""
  sorted_content=""
  was_empty_line=false
  while read -r line; do
    first_char=$(echo "${line:0:1}" | tr '[:upper:]' '[:lower:]') # Make first character lowercase for comparison
    if [[ "$first_char" != "$prev_char" ]]; then
      if [ "$was_empty_line" = false ]; then
        sorted_content+=$'\n'
      fi
      was_empty_line=true
    else
      was_empty_line=false
    fi
    sorted_content+="$line"$'\n'
    prev_char="$first_char"
  done < <(sort -f "$temp_file")
  echo -n "$sorted_content"
  > "$temp_file"
}

final_content=""
skip_next_empty_line=false

while IFS= read -r line; do
  if [[ "$line" == "## "* ]]; then
    final_content+=$(sort_and_write)$'\n'
    final_content+="$line"$'\n'
    skip_next_empty_line=true
  else
    echo "$line" >> "$temp_file"
  fi
done < "$input_file"

final_content+=$(sort_and_write)

# Remove double whitespace lines
final_content=$(echo -e "$final_content" | awk 'NF > 0 {blank = 0} NF == 0 {++blank} blank < 2')

{
  echo -n "$final_content"
  echo ""
  echo ""
} > "$input_file"

rm -f "$temp_file"

echo "File has been sorted and double whitespace lines removed."
