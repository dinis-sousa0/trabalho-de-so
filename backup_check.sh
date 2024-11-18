#!/bin/bash

#verificaoes
if [[ "$#" -lt 2 ]]; then #numero argumentos
  printf "Por favor escreva: %s 1 2\n" "$0"
  exit 1
fi

#comparar hash dos arquivos
verifica_diferenca() {
  local arquivo_trabalho="$1"
  local arquivo_backup="$2"

  #calcular hash MD5
  local md5_trabalho
  local md5_backup
  md5_trabalho=$(md5sum "$arquivo_trabalho" | awk '{print $1}')
  md5_backup=$(md5sum "$arquivo_backup" | awk '{print $1}')

  #comparar
  if [[ "$md5_trabalho" != "$md5_backup" ]]; then
    printf "%s %s differ.\n" "$arquivo_trabalho" "$arquivo_backup"
  else
    printf "%s %s iguais\n" "$arquivo_trabalho" "$arquivo_backup"
  fi
}

#recorrer
find "$1" -type f | while read -r arquivo_trabalho; do
  #caminho correspondente
  arquivo_backup="${2}${arquivo_trabalho#$1}"

  #comparar se existe
  if [[ -f "$arquivo_backup" ]]; then
    verifica_diferenca "$arquivo_trabalho" "$arquivo_backup"
  fi
done

