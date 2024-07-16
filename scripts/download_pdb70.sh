#!/bin/bash
#
# Copyright 2021 DeepMind Technologies Limited
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Downloads and unzips the PDB70 database for AlphaFold.
#
# Usage: bash download_pdb70.sh /path/to/download/directory

#OBS. Não fornece last-modified no cabeçalho HTTP

set -e

if [[ $# -eq 0 ]]; then
    echo "Error: download directory must be provided as an input argument."
    exit 1
fi

if ! command -v aria2c &> /dev/null ; then
    echo "Error: aria2c could not be found. Please install aria2c (sudo apt install aria2)."
    exit 1
fi

DOWNLOAD_DIR="$1"
ROOT_DIR="${DOWNLOAD_DIR}/pdb70"
SOURCE_URL="http://wwwuser.gwdg.de/~compbiol/data/hhsuite/databases/hhsuite_dbs/old-releases/pdb70_from_mmcif_200401.tar.gz"
BASENAME=$(basename "${SOURCE_URL}")

mkdir --parents "${ROOT_DIR}"
date_modified=$(curl -I $SOURCE_URL | grep -i last-modified | cut -d " " -f3-5)
date_file=$(date -r "$ROOT_DIR/pdb70_hhm.ffdata" "+%d %b %Y" | cut -d " " -f1-4)
echo "DATE_MODIFIED: $date_modified"
echo "DATE_FILE: $date_file"

if [ "$date_modified" == "$date_file" ]; then
  echo "O database local já está atualizado"
  exit 1
else
  set +e #continua mesmo com erro no aria2c
  aria2c  --allow-overwrite "${SOURCE_URL}" --dir="${ROOT_DIR}" 2> /dev/null

  if [[ $? -ne 0 ]]; then
    set -e
      echo "Erro do download com o aria2, tentando com wget"
      wget -N -P "${ROOT_DIR}" "${SOURCE_URL}"
  fi
tar --extract --verbose --file="${ROOT_DIR}/${BASENAME}" \
  --directory="${ROOT_DIR}"
rm "${ROOT_DIR}/${BASENAME}"
touch -d "$date_modified" "${ROOT_DIR}/pdb70_hhm.ffdata"
fi
