#!/bin/bash
#SBATCH --partition=bch-compute,bch-compute-pe
#SBATCH --output=logs/%x.log
#SBATCH --nodes=1
#SBATCH --mem=2G
#SBATCH --time=7-00

set -e
. config

G=$1
if [ -z "$G" ]; then
  echo "must provide a group"
  exit 1
fi

crawl_all_resources() {
  ./bin/crawl-res.sh $G Patient
  ./bin/crawl-res.sh $G Encounter
  ./bin/crawl-res.sh $G AllergyIntolerance
  ./bin/crawl-res.sh $G Condition
  ./bin/crawl-res.sh $G Device
  ./bin/crawl-res.sh $G DiagnosticReport
  ./bin/crawl-res.sh $G DocumentReference
  ./bin/crawl-res.sh $G Immunization
  ./bin/crawl-res.sh $G MedicationRequest
  ./bin/crawl-res.sh $G Observation
  ./bin/crawl-res.sh $G Procedure
  ./bin/crawl-res.sh $G ServiceRequest
}

time_it()
{
  time crawl_all_resources
}

OUT=$DATA_DIR/$G

if [ -f "$OUT/done" ]; then
  exit 0
fi

{
mkdir -p $OUT

time_it 2>&1 | tee $OUT/wip
[ $PIPESTATUS -eq 0 ] || exit $PIPESTATUS
tail -n100 $OUT/wip > "$OUT/done"
rm -f $OUT/wip

exit
}
