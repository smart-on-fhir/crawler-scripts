#!/bin/bash
#SBATCH --partition=bch-compute,bch-compute-pe
#SBATCH --output=logs/%x.log
#SBATCH --nodes=1
#SBATCH --mem=2G
#SBATCH --time=7-00

set -e
. config
. ~/.bashrc # get npm alias
shopt -s expand_aliases

G=$1
if [ -z "$G" ]; then
  echo "must provide a group"
  exit 1
fi

RES=$2
if [ -z "$RES" ]; then
  echo "must provide a resource"
  exit 1
fi

do_crawl() {
  # Make fake log with timestamp from start of run
  TIMESTAMP=$(date -Iseconds)
  sed "s/%GROUP%/$G/;s/%TIME%/$TIMESTAMP/" bin/log.ndjson > $OUT/log.ndjson

  # Set up config
  if [ -n "$MRN_SYSTEM" ]; then
    MRN_SYSTEM="$MRN_SYSTEM|"  # add bar
  fi
  JWK=$(jq -c .keys[0] < "$JWKS_PATH")
  sed "s|//$RES|$RES|;s!@MRN_SYSTEM@!$MRN_SYSTEM!;s|@CLIENT_ID@|$CLIENT_ID|;s|@FHIR_URL@|$FHIR_URL|;s|@TOKEN_URL@|$TOKEN_URL|;s|@JWK@|$JWK|;s!@OBSERVATION_QUERY!$OBSERVATION_QUERY!" bin/config.js > $OUT/config.js

  if [ "$RES" = "Patient" ]; then
    cp -u ids/$G $OUT/..
    PATIENT_FILE=$OUT/../$G
  else
    zcat $DATA_DIR/$G/Patient/Patient.ndjson.gz > $OUT/patients.ndjson
    PATIENT_FILE=patients.ndjson
  fi

  npm start --prefix fhir-crawler -- --path ../$OUT --patients $PATIENT_FILE

  mv $OUT/output/* $OUT/
  rmdir $OUT/output
  rm -f $OUT/request_log.tsv
  rm -f $OUT/patients.ndjson
  rm -f $OUT/config.js
  if [ -f $OUT/1.$RES.ndjson ]; then
    sed -i -e '$a\' $OUT/*.$RES.ndjson
    cat $OUT/*.$RES.ndjson > $OUT/$RES.ndjson
    rm -f $OUT/*.$RES.ndjson
    gzip $OUT/$RES.ndjson
  fi
  if [ -f $OUT/error_log.txt ]; then
    gzip $OUT/error_log.txt
  fi

  if [ "$RES" = "DiagnosticReport" ]; then
    ./bin/inline.sh $OUT
  elif [ "$RES" = "DocumentReference" ]; then
    ./bin/inline.sh $OUT
  elif [ "$RES" = "Observation" ]; then
    ./bin/dxresult-crawl.sh $FINAL/../DiagnosticReport $OUT
    ./bin/member-crawl.sh $OUT
  fi

  ./bin/calc-deleted.sh $FINAL $OUT $RES
}

OUT=wip/$G/$RES
FINAL=$DATA_DIR/$G/$RES

if [ -f "$FINAL/done" ]; then
  exit 0
fi

{
set -e
rm -rf $OUT
mkdir -p $OUT

do_crawl 2>&1 | tee $OUT/wip
[ $PIPESTATUS -eq 0 ] || exit $PIPESTATUS

# Move the wip files over into the finished data/ dir
mkdir -p $FINAL
rm -f $FINAL/*.ndjson.gz
mv -f $OUT/*.ndjson.gz $FINAL
mv -f $OUT/log.ndjson $FINAL
mv -f $OUT/error_log.txt.gz $FINAL
if [ -d $OUT/deleted ]; then
  mkdir -p $FINAL/deleted
  mv -f $OUT/deleted/* $FINAL/deleted
fi
tail -n100 $OUT/wip > "$FINAL/done"
rm -rf $OUT
rmdir --ignore-fail-on-non-empty wip/$G

exit
}
