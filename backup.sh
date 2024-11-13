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
PRESERVAR_DATAS=false

while getopts ":cr:b:a" opt; do
  case $opt in
    c) MODO_VERIFICAR=true ;;
    r) REGEX="$OPTARG" ;;
    b) BLACKLIST="$OPTARG" ;;
    a) PRESERVAR_DATAS=true ;;
    \?) printf "Opção inválida: -%s\n" "$OPTARG" >&2; uso ;;
    #:) printf "Opção -%s requer um argumento\n" "$OPTARG" >&2; uso ;;
  esac
done
shift $((OPTIND - 1))



if [[ ! -d "$1" ]]; then # existencia da diretoria especificada
  printf "Erro: diretoria '%s' não existe.\n" "$1"
  exit 1
fi

# Carregar lista de exclusão, se fornecida
if [[ -n "$BLACKLIST" && -f "$BLACKLIST" ]]; then
  mapfile -t EXCLUSOES < "$BLACKLIST"
else
  EXCLUSOES=()
fi

# Função para verificar se um arquivo ou diretório está na lista de exclusão
esta_na_lista() {
  local arquivo="$1"
  for excluido in "${EXCLUSOES[@]}"; do
    if [[ "$arquivo" == "$excluido" ]]; then
      return 0
    fi
  done
  return 1
}

# Função de cópia recursiva
copia_recursiva() {
  local fonte="$1"
  local destino="$2"

  # Loop pelos itens na fonte
  for item in "$fonte"/*; do
    local nome_base
    nome_base="$(basename "$item")"
    
    # Ignorar itens na lista de exclusão
    if esta_na_lista "$nome_base"; then
      continue
    fi

    # Verificar se o item corresponde à expressão regular, se fornecida
    if [[ -n "$REGEX" && ! "$nome_base" =~ $REGEX ]]; then
      continue
    fi

    # Cópia de arquivos e recursão para diretórios
    if [[ -f "$item" ]]; then
      if [[ "$PRESERVAR_DATAS" == true ]]; then
        printf "cp -p '%s' '%s'\n" "$item" "$destino/$nome_base"
      else
        printf "cp '%s' '%s'\n" "$item" "$destino/$nome_base"
      fi
      if [[ "$MODO_VERIFICAR" == false ]]; then
      #caso backup nao exista ainda
      if [[ ! -d "$2" ]]; then
        mkdir -p "$destino" #nao fazer igual ao outro, nao criaa subdiretorio
      fi
        if [[ "$PRESERVAR_DATAS" == true ]]; then
          cp -p "$item" "$destino/$nome_base" || printf "Erro ao copiar '%s'\n" "$item"
        else
          cp "$item" "$destino/$nome_base" || printf "Erro ao copiar '%s'\n" "$item"
        fi
      fi
    elif [[ -d "$item" ]]; then
      copia_recursiva "$item" "$destino/$nome_base"
    fi
  done
}

copia_recursiva "$1" "$2"