#!/bin/bash
#SBATCH --partition=bch-compute
#SBATCH --output=logs/%x.log
#SBATCH --nodes=1
#SBATCH --mem=16G
#SBATCH --time=7-00

set -e

. venv/bin/activate
. config

DIR=$1
if [ -z "$DIR" ]; then
  echo "must provide a folder"
  exit 1
fi

echo "Inlining..."
cumulus-etl inline \
  "$DIR" \
  "$FHIR_URL" \
  --smart-key "$JWKS_PATH" \
  --smart-client-id "$CLIENT_ID"

echo "All done!"
