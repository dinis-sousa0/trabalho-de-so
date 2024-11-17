#!/bin/bash

#verificaoes
if [[ "$#" -lt 2 ]]; then #numero argumentos
  printf "Por favor escreva: %s 1 2\n" "$0"
  exit 1
fi

#verificar para os 2 ficheiros se a hash e igual
verifica_diferenca() {
  local arquivo_trabalho="$1"
  local arquivo_backup="$2"`

  #calcula
  md5_trabalho=$(md5sum "$arquivo_trabalho" | awk '{print $1}')
  md5_backup=$(md5sum "$arquivo_backup" | awk '{print $1}')

  #compara
  if [[ "$md5_trabalho" != "$md5_backup" ]]; then
    printf "%s %s differ.\n" "$arquivo_trabalho" "$arquivo_backup"
  else
    printf "%s %s iguais\n" "$arquivo_trabalho" "$arquivo_backup"
  fi
}

#perceorre na pasta source
find "$1" -type f | while read -r arquivo_trabalho; do
  #faz o caminho pa do backup
  arquivo_backup="${2}${arquivo_trabalho#$1}"

  #compara so se existir
  if [[ -f "$arquivo_backup" ]]; then
    verifica_diferenca "$arquivo_trabalho" "$arquivo_backup"
  fi
done
