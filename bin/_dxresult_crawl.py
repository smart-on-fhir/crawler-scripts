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


async def download_one(client, output, index, ref):
  try:
    response = await client.request("GET", ref)
  except errors.NetworkError as exc:
    print(f"Could not get {ref}: {exc}")
    return

  try:
    output.write(response.json())
  except Exception as exc:
    print(f"Could not decode/write {ref}: {exc}")
    return


async def one_iter(client, dx_folder, obs_folder):
  found_results = set()
  for row in cfs.read_multiline_json_from_dir(dx_folder, "DiagnosticReport"):
    found_results |= {x["reference"] for x in row.get("result", [])}

  found_ids = set()
  for row in cfs.read_multiline_json_from_dir(obs_folder, "Observation"):
    found_ids.add(f'Observation/{row["id"]}')

  target_results = found_results - found_ids

  target = os.path.join(obs_folder, "Observation.dxresults.ndjson.gz")
  with common.NdjsonWriter(target, append=True, compressed=True) as output:
    await peek_ahead_processor(
      target_results,
      partial(download_one, client, output),
      peek_at=fhir.FhirClient.MAX_CONNECTIONS * 2,
    )

  print(f"Downloaded {len(target_results)} Observations.")


async def iterate(dx_folder, obs_folder):
  fhir_url = os.environ["FHIR_URL"]
  client = fhir.FhirClient(
    fhir_url, {"Observation"},
    smart_client_id=os.environ["CLIENT_ID"],
    smart_jwks=common.read_json(os.environ["JWKS_PATH"]),
  )

  async with client:
    await one_iter(client, dx_folder, obs_folder)


parser = argparse.ArgumentParser()
parser.add_argument("dx_folder", metavar="DIR")
parser.add_argument("obs_folder", metavar="DIR")
args = parser.parse_args()

if not os.path.exists(args.dx_folder):
  sys.exit("No dxreport folder")

asyncio.run(iterate(args.dx_folder, args.obs_folder))
