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

while getopts ":cr:b" opt; do
  case $opt in
    c) MODO_VERIFICAR=true ;;
    r) REGEX="$OPTARG" ;;
    b) BLACKLIST="$OPTARG" ;;
    \?) printf "Opção inválida: -%s\n" "$OPTARG" >&2; uso ;;
    :) printf "Opção -%s requer um argumento\n" "$OPTARG" >&2; uso ;;
  esac
done
shift $((OPTIND - 1))

#variaveis dos erros
ERROR=0
WARNINGS=0
ATUALIZADOS=0
COPIADOS=0
APAGADOS=0
TAM_COP=0
TAM_ATU=0
TAM_APA=0

if [[ ! -d "$1" ]]; then #existencia da diretoria especificada
  printf "Erro: diretoria '%s' não existe.\n" "$1"
  exit 1
fi

#carregar a excluisonsson UQERO DORMIR
if [[ -n "$BLACKLIST" && -f "$BLACKLIST" ]]; then
  #echo $BLACKLIST
  mapfile -t EXCLUSOES < "$BLACKLIST"
else
  EXCLUSOES=()
fi

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
  local fuente="$1"
  local destino="$2"

  # Crear el directorio de destino si no existe
  mkdir -p "$destino"

  for item in "$fuente"/*; do
    local nombre_base
    nombre_base="$(basename "$item")"
    local actualizacion=0

    # Saltar si está en la blacklist
    if esta_na_lista "$nombre_base"; then
      continue
    fi

    # Verificar si el nombre cumple con el regex (si se especifica)
    if [[ -n "$REGEX" && ! "$nombre_base" =~ $REGEX ]]; then
      continue
    fi

    if [[ -f "$item" ]]; then
      # Copiar archivos
      if [[ ! -f "$destino/$nombre_base" || "$item" -nt "$destino/$nombre_base" ]]; then
        # Verificar si es una actualización
        if [[ -f "$destino/$nombre_base" && "$item" -nt "$destino/$nombre_base" ]]; then
          actualizacion=1
        fi

        if [[ "$MODO_VERIFICAR" == true ]]; then
          printf "cp -a '%s' '%s'\n" "$item" "$destino/$nombre_base"
        else
          cp -a "$item" "$destino/$nombre_base"
        fi

        # Actualizar estadísticas
        local tam
        tam=$(stat -c%s "$item")
        if [[ "$actualizacion" == 0 ]]; then
          ((COPIADOS++))
          TAM_COP=$((TAM_COP + tam))
        else
          ((ATUALIZADOS++))
          TAM_ATU=$((TAM_ATU + tam))
        fi
      elif [[ "$item" -ot "$destino/$nombre_base" ]]; then
        # Generar un warning si el archivo de destino es más reciente
        printf "WARNING: backup entry '%s/%s' is newer than '%s/%s'; should not happen\n" \
          "$destino" "$nombre_base" "$fuente" "$nombre_base"
        ((WARNINGS++))
      fi
    elif [[ -d "$item" ]]; then
      # Manejar subdirectorios recursivamente
      copia_recursiva "$item" "$destino/$nombre_base"
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
        local tam_item #nao e redundante, e necessario guardar antes de apagar
        tam_item=$(stat -c%s "$item")
        #remover ficheiro
        if [[ "$MODO_VERIFICAR" == false ]]; then
          rm "$item"
        else
          printf "rm '%s'\n" "$item"
        fi
        ((APAGADOS++))
        TAM_APA=$((TAM_APA + tam_item))
      fi
    #elif [[ -d "$item" && ! -d "$trabalho_dir/$nome_base" ]] || esta_na_lista "$nome_base"; then
    elif [[ -d "$item" ]]; then
      if [[ ! -d "$trabalho_dir/$nome_base" ]] || esta_na_lista "$nome_base"; then
        #remover pasta
        if [[ "$MODO_VERIFICAR" == false ]]; then
          rm -rf "$item"
        else
          printf "rm -rf '%s'\n" "$item"
        fi
        ((APAGADOS++))
        TAM_APA=$((TAM_APA + tam_item))
      else
        #subd
        remover_extras "$item" "$trabalho_dir/$nome_base"
      fi
    fi
  done
}

remover_extras "$2" "$1"

printf "While backuping %s: %d Errors; %d Warnings; %d Updated (%dB); %d Copied (%dB); %d Deleted (%dB)\n" "$1" "$ERROR" "$WARNINGS" "$ATUALIZADOS" "$TAM_ATU" "$COPIADOS" "$TAM_COP" "$APAGADOS" "$TAM_APA"
