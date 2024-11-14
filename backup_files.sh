#!/bin/bash

#verificaoes
if [[ "$#" -lt 2 ]]; then #numero argumentos
  printf "Por favor escreva: %s [-c] dir_trabalho dir_backup\n" "$0"
  exit 1
fi

: '
MODO_VERIFICAR=false
if [[ "$1" == "-c" ]]; then
  MODO_VERIFICAR=true
  shift #desloca o resto dos argumentos para a esquerda, logo o $1 passa a $n
  #echo $1
fi'

MODO_VERIFICAR="false"
while getopts ":c" opt; do
  case $opt in
    c) MODO_VERIFICAR=true ;;
    \?) printf "Opção inválida: -%s\n" "$OPTARG" >&2; uso ;;
    :) printf "Opção -%s requer um argumento\n" "$OPTARG" >&2; uso ;;
  esac
done
shift $((OPTIND - 1))

if [[ ! -d "$1" ]]; then # existencia da diretoria especificada
  printf "Erro: diretoria '%s' não existe.\n" "$1"
  exit 1
fi

#copiar os arquivos
copia() {
  fonte="$1"
  destino="$2"
  #echo $destino
  #echo $fonte
  if [[ -d "$destino" || "$fonte" -nt "$destino" ]]; then
    if [[ "$MODO_VERIFICAR" == true ]]; then
      printf "cp -a '%s''%s'\n" "$fonte" "$destino"
    elif [[ "$MODO_VERIFICAR" == false ]]; then
      #caso backup nao exista ainda
      if [[ ! -d "$2" ]]; then
        mkdir -p "$(dirname "$destino")"
      fi
      cp -a "$fonte" "$destino" || printf "Erro ao copiar '%s' para '%s'\n" "$fonte" "$destino"
    fi
  fi
}

#vai fazendo a cada ficheiro na diretoria
for arquivo in "$1"/*; do
  if [[ -f "$arquivo" ]]; then
    copia "$arquivo" "$2/$(basename "$arquivo")"
  fi
done

#remover lixo
for backup_arquivo in "$2"/*; do
  #echo $destino
  if [[ -f "$backup_arquivo" && ! -f "$1/$(basename "$backup_arquivo")" ]]; then
    if [[ "$MODO_VERIFICAR" == false ]]; then
      rm "$backup_arquivo"
    elif [ "$MODO_VERIFICAR" == true ]; then
      printf "rm '%s'\n" "$backup_arquivo"
    fi
  fi
done
