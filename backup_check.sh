#!/bin/bash

# Verificación de argumentos
if [[ "$#" -lt 2 ]]; then
  printf "Uso: %s <dir_trabalho> <dir_backup>\n" "$0"
  exit 1
fi

# Función para comparar hashes de archivos
verifica_diferenca() {
  local arquivo_trabalho="$1"
  local arquivo_backup="$2"

  # Calcular los hashes MD5
  local md5_trabalho
  local md5_backup
  md5_trabalho=$(md5sum "$arquivo_trabalho" | awk '{print $1}')
  md5_backup=$(md5sum "$arquivo_backup" | awk '{print $1}')

  # Comparar hashes
  if [[ "$md5_trabalho" != "$md5_backup" ]]; then
    printf "DIFERENTE: %s y %s\n" "$arquivo_trabalho" "$arquivo_backup"
  else
    printf "%s %s iguais\n" "$arquivo_trabalho" "$arquivo_backup"
  fi
}

# Recorrer los archivos del directorio de trabajo
find "$1" -type f | while read -r arquivo_trabalho; do
  # Construir la ruta correspondiente en el directorio de backup
  arquivo_backup="${2}${arquivo_trabalho#$1}"

  # Comparar solo si el archivo en el backup existe
  if [[ -f "$arquivo_backup" ]]; then
    verifica_diferenca "$arquivo_trabalho" "$arquivo_backup"
  fi
done

