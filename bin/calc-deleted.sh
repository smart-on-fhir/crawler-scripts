#!/bin/bash
#SBATCH --partition=bch-compute
#SBATCH --output=logs/%x.log
#SBATCH --nodes=1
#SBATCH --mem=1G
#SBATCH --time=1-00

set -e

OLDDIR=$1
NEWDIR=$2
TYPE=$3
if [ -z "$OLDDIR" -o -z "$NEWDIR" -o -z "$TYPE" ]; then
  echo "must provide an old dir and a new dir"
  exit 1
fi

if [ ! -d "$OLDDIR" ]; then
  exit 0  # nothing to do, first time we exported
fi

get_ids_from_dir()
{
  zgrep -o '"resourceType":"'$TYPE'","id":"[^"]*"' "$1"/*.ndjson.gz 2>/dev/null | cut -d'"' -f8 | sort | uniq
}

WORKDIR=$(mktemp -d)

get_ids_from_dir $OLDDIR > $WORKDIR/old.ids
get_ids_from_dir $NEWDIR > $WORKDIR/new.ids
comm -23 $WORKDIR/old.ids $WORKDIR/new.ids > $WORKDIR/deleted.ids

if [ ! -s $WORKDIR/deleted.ids ]; then
  rm -rf $WORKDIR
  echo "No deleted IDs for $TYPE"
  exit 0  # nothing to do
fi


# Make a bundle file, named uniquely so we don't override older existing bundles
# It's nice to keep a running tally
if [ ! -f $NEWDIR/log.ndjson ]; then
  echo "no log.ndjson found"
  exit 1
fi
TIME=$(grep -o '"transactionTime": "[^"]*"' $NEWDIR/log.ndjson | cut -d'"' -f 4)
BUNDLE=$WORKDIR/$TIME.ndjson.gz

echo -e '{\n  "resourceType": "Bundle",' > $BUNDLE
echo -e '  "meta": {"lastUpdated": "'$TIME'"},' >> $BUNDLE
echo -e '  "type": "transaction",' >> $BUNDLE
echo -e '  "entry": [' >> $BUNDLE
ENDING=
for DELID in $(cat $WORKDIR/deleted.ids); do
  echo -ne $ENDING'    {"request": {"method": "DELETE", "url": "'$TYPE'/'$DELID'"}}' >> $BUNDLE
  ENDING=",\n"
done
echo -e '\n  ]\n}' >> $BUNDLE

mkdir -p $NEWDIR/deleted
mv $BUNDLE $NEWDIR/deleted/

rm -rf $WORKDIR

echo "All done!"
