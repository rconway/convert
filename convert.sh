#!/usr/bin/env bash
# Ref. https://docs.ogc.org/bp/20-089r1.html#toc27

ORIG_DIR="$(pwd)"
cd "$(dirname "$0")"
BIN_DIR="$(pwd)"
cd "${ORIG_DIR}"

onExit() {
  cd "${ORIG_DIR}"
}
trap onExit EXIT

OUTPUT_DIR="${ORIG_DIR}"

main() {
  echo "Invocation args: $0 $@"
  fn="$1" && shift
  case "${fn}" in
    "resize" )
      resize "$@"
      ;;
    * )
      echo "ERROR: Unknown function = ${fn}"
      return 1
      ;;
  esac
}

resize() {
  echo "resize with args: $@"
  srcType="$1" && shift
  case "${srcType}" in
    "--dir" )
      srcDir="$1" && shift
      resizeDirectory "${srcDir}" "$@"
      ;;
    "--url" )
      srcUrl="$1" && shift
      resizeUrl "${srcUrl}" "$@"
      ;;
    * )
      echo "ERROR: Unknown source type = ${srcType}"
      return 1
      ;;
  esac
}

resizeDirectory() {
  echo "resizeDirectory: $@"
  dir="$1"
  size="$2"

  stacItemFile="$(cat "${dir}/catalog.json" | jq -r '.links[] | select(.rel == "item") | .href')"
  inputFile="$(cat "${dir}/${stacItemFile}" | jq -r 'first(.assets[]).href')"

  echo "Input dir: ${dir}" >>"${OUTPUT_DIR}/output.txt"
  ls -lR "${dir}" >>"${OUTPUT_DIR}/output.txt"

  resizeUrl2 "${dir}/${inputFile}" "${size}"
}

resizeUrl2() {
  echo "resizeUrl: $@"
  url="$1"
  size="$2"
  filename="$(basename "${url}")"
  filestem="${filename%.*}"
  ext="${filename##*.}"
  outputFileTmp="${filestem}-resize.${ext}"

  outputFile="output.txt"
  echo "Output dir: ${OUTPUT_DIR}" >>"${OUTPUT_DIR}/${outputFile}"

  convert "${url}" -resize "${size}" "${OUTPUT_DIR}/${outputFileTmp}" >>"${OUTPUT_DIR}/${outputFile}" 2>&1

  ls -lR >>"${OUTPUT_DIR}/${outputFile}"

  now="$(date +%s.%N)"
  mimetype="$(file -b --mime-type "${OUTPUT_DIR}/${outputFile}")"

  createStacItem "${now}" "${outputFile}" "${mimetype}"
  createStacCatalogRoot "${outputFile}"
}

resizeUrl() {
  echo "resizeUrl: $@"
  url="$1"
  size="$2"
  filename="$(basename "${url}")"
  filestem="${filename%.*}"
  ext="${filename##*.}"
  outputFile="${filestem}-resize.${ext}"

  convert "${url}" -resize "${size}" "${OUTPUT_DIR}/${outputFile}"

  now="$(date +%s.%N)"
  mimetype="$(file -b --mime-type "${OUTPUT_DIR}/${outputFile}")"

  createStacItem "${now}" "${outputFile}" "${mimetype}"
  createStacCatalogRoot "${outputFile}"
}

createStacItem() {
  now="${1}"
  filename="${2}"
  mimetype="${3}"
  dateNow="$(date -u --date=@${now} +%Y-%m-%dT%T.%03NZ)"
  filestem="${filename%.*}"
  itemfile="${filestem}.json"
  cat - <<EOF > "${OUTPUT_DIR}/${itemfile}"
{
  "stac_version": "1.0.0",
  "id": "${filestem}-${now}",
  "type": "Feature",
  "geometry": {
    "type": "Polygon",
    "coordinates": [
      [
        [30.155974613579858, 28.80949327971016],
        [30.407037927198104, 29.805008695373978],
        [31.031551610920825, 29.815791988006527],
        [31.050481437029678, 28.825387639743422],
        [30.155974613579858, 28.80949327971016]
      ]
    ]
  },
  "properties": {
    "created": "${dateNow}",
    "datetime": "${dateNow}",
    "updated": "${dateNow}"
  },
  "bbox": [30.155974613579858, 28.80949327971016, 31.050481437029678, 29.815791988006527],
  "assets": {
    "output": {
      "type": "${mimetype}",
      "roles": ["data"],
      "href": "${filename}",
      "file:size": $(stat --printf="%s" "${OUTPUT_DIR}/${filename}")
    }
  },
  "links": [{
    "type": "application/json",
    "rel": "parent",
    "href": "catalog.json"
  }, {
    "type": "application/geo+json",
    "rel": "self",
    "href": "${itemfile}"
  }, {
    "type": "application/json",
    "rel": "root",
    "href": "catalog.json"
  }]
}
EOF
}

createStacCatalogRoot() {
  filename="${1}"
  filestem="${filename%.*}"
  itemfile="${filestem}.json"
  cat - <<EOF > "${OUTPUT_DIR}/catalog.json"
{
  "stac_version": "1.0.0",
  "id": "catalog",
  "type": "Catalog",
  "description": "Root catalog",
  "links": [{
    "type": "application/geo+json",
    "rel": "item",
    "href": "${itemfile}"
  }, {
    "type": "application/json",
    "rel": "self",
    "href": "catalog.json"
  }]
}
EOF
}

main "$@"
