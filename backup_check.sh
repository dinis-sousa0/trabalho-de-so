#!/bin/bash

check_integridade() {
  for fonte in "$DIR_TRABALHO"/*; do
    local destino="$DIR_BACKUP/$(basename "$fonte")"
    if [[ -f "$fonte" && -f "$destino" ]]; then
      if ! diff <(md5sum "$fonte" | cut -d' ' -f1) <(md5sum "$destino" | cut -d' ' -f1) > /dev/null; then
        echo "$fonte $destino differ."
      fi
    fi
  done
}

DIR_TRABALHO=$1
DIR_BACKUP=$2

check_integridade
