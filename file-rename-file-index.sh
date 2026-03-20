#!/bin/zsh

dir="$1"
start="${2:-1}"   # if $2 not provided, default to 1
i=$start

for file in ${(on)$(ls -t "$dir")}; do
  ext="${file:e}"
  printf -v newname "%d.%s" $i "$ext"
  mv "$dir/$file" "$dir/$newname"
  ((i++))
done