#!/bin/bash

#verificaoes
if [[ "$#" -lt 2 ]]; then #numero argumentos
  printf "Por favor escreva: %s [-c] [-r regex] [-b blacklist.txt] [-a] dir_trabalho dir_backup\n" "$0"
  exit 1
fi

#variaveis das flags
MODO_VERIFICAR=false
REGEX=""
BLACKLIST=""

while getopts ":cr:b:" opt; do
  case $opt in
    c) MODO_VERIFICAR=true ;;
    r) REGEX="$OPTARG" ;;
    b) BLACKLIST="$OPTARG" ;;
    \?) printf "Opção inválida: -%s\n" "$OPTARG" >&2; uso ;;
    :) printf "Opção -%s requer um argumento\n" "$OPTARG" >&2; uso ;;
  esac
done
shift $((OPTIND - 1))



if [[ ! -d "$1" ]]; then #existencia da diretoria especificada
  printf "Erro: diretoria '%s' não existe.\n" "$1"
  exit 1
fi

#carregar a excluisonsson
if [[ -n "$BLACKLIST" && -f "$BLACKLIST" ]]; then
  #echo $BLACKLIST
  mapfile -t EXCLUSOES < "$BLACKLIST"
else
  EXCLUSOES=()
fi

#verificar se esta nas exclusins
esta_na_lista() {
  local arquivo="$1"
  for excluido in "${EXCLUSOES[@]}"; do
  #echo a $arquivo
  #echo o $excluido
    if [[ "$arquivo" == "$excluido" || "$arquivo" == "$excluido/"* ]]; then
      return 0
    fi
  done
  return 1
}


copia_recursiva() {
  local fonte="$1"
  local destino="$2"

  #fonte
  for item in "$fonte"/*; do
    local nome_base
    nome_base="$(basename "$item")"
    
    #exlusoes
    if esta_na_lista "$nome_base"; then
      continue
    fi

    #verificar se o item corresponde regex
    if [[ -n "$REGEX" && ! "$nome_base" =~ $REGEX ]]; then
      continue
    fi

    #copia
    if [[ -f "$item" ]]; then
      if [[ ! -f "$destino/$nome_base" || "$item" -nt "$destino/$nome_base" ]]; then
        if [[ "$MODO_VERIFICAR" == true ]]; then
          printf "cp -a %s %s\n" "$item" "$destino/$nome_base"
        else
          mkdir -p "$destino"
          cp -p "$item" "$destino/$nome_base" || printf "Erro ao copiar %s\n" "$item"
        fi
      fi
    elif [[ -d "$item" ]]; then
      #subd
      copia_recursiva "$item" "$destino/$nome_base"
    fi
  done
}

copia_recursiva "$1" "$2"

#remover lixo
remover_extras() {
  local backup_dir="$1"
  local trabalho_dir="$2"

  for item in "$backup_dir"/*; do
    local nome_base
    nome_base="$(basename "$item")"

    #if [[ -f "$item" &&  ! -f "$trabalho_dir/$nome_base" ]] || esta_na_lista "$nome_base"; then
    if [[ -f "$item" ]]; then
      if [[ ! -f "$trabalho_dir/$nome_base" ]] ||  esta_na_lista "$nome_base"; then
        #remover ficheiro
        if [[ "$MODO_VERIFICAR" == false ]]; then
          rm "$item"
        else
          printf "rm %s\n" "$item"
        fi
      fi
    #elif [[ -d "$item" && ! -d "$trabalho_dir/$nome_base" ]] || esta_na_lista "$nome_base"; then
    elif [[ -d "$item" ]]; then
      if [[ ! -d "$trabalho_dir/$nome_base" ]] || esta_na_lista "$nome_base"; then
        #remover pasta
        if [[ "$MODO_VERIFICAR" == false ]]; then
          rm -rf "$item"
        else
          printf "rm -rf %s\n" "$item"
        fi
      else
        #subd
        remover_extras "$item" "$trabalho_dir/$nome_base"
      fi
    fi
  done
}

remover_extras "$2" "$1"
