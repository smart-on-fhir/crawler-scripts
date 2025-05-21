#!/bin/bash
#SBATCH --partition=bch-compute,bch-compute-pe
#SBATCH --output=logs/%x.log
#SBATCH --nodes=1
#SBATCH --mem=2G
#SBATCH --time=7-00

set -e

. venv/bin/activate

set -a
. config

python3 -u ./bin/_member_crawl.py "$@"
