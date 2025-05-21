#!/bin/bash
#SBATCH --partition=bch-compute
#SBATCH --output=logs/%x.log
#SBATCH --nodes=1
#SBATCH --mem=1G
#SBATCH --time=1-00

set -e
. ~/.bashrc
shopt -s expand_aliases

[ -d fhir-crawler ] || git clone https://github.com/smart-on-fhir/fhir-crawler.git
cd fhir-crawler
npm ci

echo "Crawler setup done!"
