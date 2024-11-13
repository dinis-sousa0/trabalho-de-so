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

# Função de cópia recursiva com contadores de sumário
copia_recursiva() {
  local fonte="$1"
  local destino="$2"

  # Inicializar contadores
  local erros=0
  local avisos=0
  local atualizados=0
  local copiados=0
  local apagados=0
  local tamanho_copiado=0
  local tamanho_apagado=0

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
      if [[ -e "$destino/$nome_base" && "$item" -nt "$destino/$nome_base" ]]; then
        atualizados=$((atualizados + 1))
      else
        copiados=$((copiados + 1))
        tamanho_copiado=$((tamanho_copiado + $(stat -c %s "$item")))
      fi
      if [[ "$MODO_VERIFICAR" == false ]]; then
        if [[ ! -d "$destino" ]]; then
          mkdir -p "$destino"
        fi
        if [[ "$PRESERVAR_DATAS" == true ]]; then
          cp -p "$item" "$destino/$nome_base" || { printf "Erro ao copiar '%s'\n" "$item"; erros=$((erros + 1)); }
        else
          cp "$item" "$destino/$nome_base" || { printf "Erro ao copiar '%s'\n" "$item"; erros=$((erros + 1)); }
        fi
      fi
    elif [[ -d "$item" ]]; then
      copia_recursiva "$item" "$destino/$nome_base"
    fi
  done

  #informacaoes da diretoria
  printf "While backuping %s: %d Errors; %d Warnings; %d Updated; %d Copied (%dB); %d Deleted (%dB)\n" \
         "$fonte" "$erros" "$avisos" "$atualizados" "$copiados" "$tamanho_copiado" "$apagados" "$tamanho_apagado"
}

copia_recursiva "$1" "$2"
