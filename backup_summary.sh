#!/bin/bash
#set -x

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



#imp resumo cada diretorio
imprimir_resumo() {
  local dir="$1"
  printf "While backuping %s: %d Errors; %d Warnings; %d Updated; %d Copied (%dB); %d Deleted (%dB)\n" \
         "$dir" "$ERROR" "$WARNINGS" "$ATUALIZADOS" "$COPIADOS" "$TAM_COP" "$APAGADOS" "$TAM_APA"
}

copia_recursiva() {
  local fuente="$1"
  local destino="$2"

  local local_error=0
  local local_warnings=0
  local local_atualizados=0
  local local_copiados=0
  local local_apagados=0
  local local_tam_cop=0
  local local_tam_atu=0
  local local_tam_apa=0

  #fonte
  for item in "$fonte"/*; do
    local nome_base
    nome_base="$(basename "$item")"
    local atualizacao=0
    
    #exclusoes
    if esta_na_lista "$nome_base"; then
      continue
    fi

    # Verificar si el nombre cumple con el regex (si se especifica)
    if [[ -n "$REGEX" && ! "$nombre_base" =~ $REGEX ]]; then
      continue
    fi

    #copia
    if [[ -f "$item" ]]; then
      # Copiar archivos
      if [[ ! -f "$destino/$nombre_base" || "$item" -nt "$destino/$nombre_base" ]]; then
        # Verificar si es una actualización
        if [[ -f "$destino/$nombre_base" && "$item" -nt "$destino/$nombre_base" ]]; then
          actualizacion=1
        fi

        if [[ "$MODO_VERIFICAR" == true ]]; then
          if [ $atualizacao == 0 ]; then
            printf "cp -a %s %s\n" "$item" "$destino/$nome_base"
            local_tam_cop=$((local_tam_cop + $(stat -c%s "$item"))) 
            ((local_copiados++))
          elif [ $atualizacao == 1 ]; then
            printf "cp -a %s %s\n" "$item" "$destino/$nome_base"
            local_tam_atu=$((local_tam_atu + $(stat -c%s "$item"))) 
            ((local_atualizados++))
          fi
        else
          mkdir -p "$destino"
          if cp -a "$item" "$destino/$nome_base"; then
            printf "cp -a %s %s\n" "$item" "$destino/$nome_base"
            if [ $atualizacao == 0 ]; then
              ((local_copiados++))
              local_tam_cop=$((local_tam_cop + $(stat -c%s "$item"))) 
            elif [ $atualizacao == 1 ]; then
              ((local_atualizados++))
              local_tam_atu=$((local_tam_atu + $(stat -c%s "$item"))) 
            fi
          else
            printf "Erro ao copiar '%s'\n" "$item"
            ((local_error++))
          fi
        fi
      elif [[ "$item" -ot "$destino/$nome_base" ]]; then
        printf "WARNING: backup entry %s is newer than %s; Should not happen\n" "$2" "$1"
        ((local_warnings++))
      fi
    elif [[ -d "$item" ]]; then
      # Manejar subdirectorios recursivamente
      copia_recursiva "$item" "$destino/$nombre_base"
    fi
  done

  #globais a partir dos locais
  ERROR=$((ERROR + local_error))
  WARNINGS=$((WARNINGS + local_warnings))
  ATUALIZADOS=$((ATUALIZADOS + local_atualizados))
  COPIADOS=$((COPIADOS + local_copiados))
  APAGADOS=$((APAGADOS + local_apagados))
  TAM_COP=$((TAM_COP + local_tam_cop))
  TAM_ATU=$((TAM_ATU + local_tam_atu))
  TAM_APA=$((TAM_APA + local_tam_apa))

  #resumo do subd atual
  imprimir_resumo "$fonte"
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
        local tam_item #nao e redundante, necessario guardar antes de apagar
        tam_item=$(stat -c%s "$item")
        #remover arquivo
        if [[ "$MODO_VERIFICAR" == false ]]; then
          rm "$item"
        else
          printf "rm %s\n" "$item"
        fi
        ((APAGADOS++))
        TAM_APA=$((TAM_APA + tam_item))
      fi
    elif [[ -d "$item" ]]; then
      if [[ ! -d "$trabalho_dir/$nome_base" ]] || esta_na_lista "$nome_base"; then
        #remover pasta
        if [[ "$MODO_VERIFICAR" == false ]]; then
          rm -rf "$item"
        else
          printf "rm -rf %s\n" "$item"
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

imprimir_resumo "$1"