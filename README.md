# Crawler Scripts

Is your EHR's bulk export process too slow or is it too difficult to get
proper registries defined in order to even start a bulk export?

That's where `crawler-scripts` comes in.

It simulates a bulk export via FHIR searches and goes one step further
by augmenting the data with inlined clinical notes and Observations that
you might not normally get with a search (like DiagnosticReport results
or Observation group members).

## Prerequisites

- npm, python3, bash, git, jq

## Install

- Clone this repo and `cd` into it
- `cp .config.defaults config`
- Edit `config` to match your environment
- `./crawl-setup` (sets up a venv and download fhir-crawler, all in-folder)

## Running

- Get a list of MRNs that define your Patient group, in a file with
  one MRN per line
- Put that list in `./ids/GROUP-NAME` (where `GROUP-NAME` can be
  whatever makes sense to you - like `asthma-patients` or `BCH-001`)
- `./crawl GROUP-NAME` for all resources in a group
- `./crawl GROUP-NAME ResourceName` for a single resource
- Your data will end up in `./data/GROUP-NAME/ResourceNames`

## Notes

- There's no hard group size limit enforced, but around 10k MRNs
  is the recommended cap per group. This keeps the amount of data
  in each group manageable and the time to export reasonable.
  (for BCH using Epic, one group of 10k patients takes about 9 hours
  for all resources)
- This will write a fake `log.ndjson` file like other bulk export
  tools do. This is just to note some metadata about the "export" so
  that Cumulus ETL can grab it later. If you're not using Cumulus,
  you don't need to care about that file.
- This repo folder was designed such that you could add it to PATH.
- There are slurm/sbatch headers on the scripts (but with BCH-specific
  partition names). With some light editing, you should be able to use
  them with your own slurm setup.

## Acknowledgements

- Thanks to Vlad for the useful fhir-crawler tool used under the hood
