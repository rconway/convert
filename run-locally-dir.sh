#!/usr/bin/env bash

ORIG_DIR="$(pwd)"
cd "$(dirname "$0")"
BIN_DIR="$(pwd)"
cd "${ORIG_DIR}"

onExit() {
  cd "${ORIG_DIR}"
}
trap onExit EXIT

main() {
  cwltool --outdir out convert-dir-app.cwl#convert --fn resize --dir ./stac --size "50%"
}

main "$@"
