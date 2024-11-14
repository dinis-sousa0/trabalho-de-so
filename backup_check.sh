#!/bin/bash

#verificaoes
if [[ "$#" -lt 2 ]]; then #numero argumentos
  printf "Por favor escreva: %s 1 2\n" "$0"
  exit 1
fi

#verificar para os 2 ficheiros se a hash e igual
verifica_diferenca() {
  local arquivo_trabalho="$1"
  local arquivo_backup="$2"

  md5_trabalho=$(md5sum "$arquivo_trabalho" | awk '{print $1}') #calculs
  md5_backup=$(md5sum "$arquivo_backup" | awk '{print $1}')

  #e compara
  if [[ "$md5_trabalho" != "$md5_backup" ]]; then
    printf "%s %s differ." "$arquivo_trabalho" "$arquivo_backup"
  else
    echo ola
  fi
}

#faz para cada arquivo
find "$1" -type f | while read -r arquivo_trabalho; do
  #caminho corresepondente
  arquivo_backup="${2}${arquivo_trabalho#$1}"

  #caso existe compara
  if [[ -f "$arquivo_backup" ]]; then
    verifica_diferenca "$arquivo_trabalho" "$arquivo_backup"
  fi
done
