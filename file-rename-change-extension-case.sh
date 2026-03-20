#!/bin/zsh

dir="$1"

for file in "$dir"/*.MOV(.); do
  mv "$file" "${file:r}.mov"
done