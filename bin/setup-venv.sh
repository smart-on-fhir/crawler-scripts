#!/bin/bash
#SBATCH --partition=bch-compute
#SBATCH --output=logs/%x.log
#SBATCH --nodes=1
#SBATCH --mem=1G
#SBATCH --time=1-00

set -e
if [ ! -f config ]; then
  cp .config.defaults config
fi
. config
if [ -z "$PYTHON" -o -z "$FHIR_URL" ]; then
  echo "Please edit the 'config' file for your environment and then try again"
  exit 1
fi

[ -d venv ] || $PYTHON -m venv venv
. venv/bin/activate

pip install -U pip
pip install -U cumulus-etl

echo "VENV setup done!"
