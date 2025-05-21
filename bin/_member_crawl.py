#!/usr/bin/env python3

import argparse
import asyncio
import os
import pathlib
import subprocess
import sys
from functools import partial

import cumulus_fhir_support as cfs
from cumulus_etl import common, errors, fhir, store
from cumulus_etl.inliner.reader import peek_ahead_processor


total_written = 0


async def download_one(client, output, index, ref):
  global total_written

  try:
    response = await client.request("GET", ref)
  except errors.NetworkError as exc:
    print(f"Could not get {ref}: {exc}")
    return

  try:
    output.write(response.json())
    total_written += 1
  except Exception as exc:
    print(f"Could not decode/write {ref}: {exc}")
    return


async def one_iter(client, folder):
  global total_written

  found_ids = set()
  found_members = set()
  for row in cfs.read_multiline_json_from_dir(folder, "Observation"):
    found_ids.add(f'Observation/{row["id"]}')
    found_members |= {x["reference"] for x in row.get("hasMember", [])}

  target_members = found_members - found_ids
  if not target_members:
    return False

  total_written = 0
  target = os.path.join(folder, "Observation.members.ndjson.gz")
  with common.NdjsonWriter(target, append=True, compressed=True) as output:
    await peek_ahead_processor(
      target_members,
      partial(download_one, client, output),
      peek_at=fhir.FhirClient.MAX_CONNECTIONS * 2,
    )

  print(f"Downloaded {len(target_members)} Observations.")
  return total_written > 0


async def iterate(folder):
  fhir_url = os.environ["FHIR_URL"]
  client = fhir.FhirClient(
    fhir_url, {"Observation"},
    smart_client_id=os.environ["CLIENT_ID"],
    smart_jwks=common.read_json(os.environ["JWKS_PATH"]),
  )

  async with client:
    while await one_iter(client, folder):
      print("One iteration down. Going again.")


parser = argparse.ArgumentParser()
parser.add_argument("folder", metavar="DIR")
args = parser.parse_args()

asyncio.run(iterate(args.folder))
