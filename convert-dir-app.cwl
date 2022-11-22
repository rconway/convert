cwlVersion: v1.0
$namespaces:
  s: https://schema.org/
schemas:
  - http://schema.org/version/9.0/schemaorg-current-http.rdf
s:softwareVersion: 0.0.2

$graph:
  # Workflow entrypoint
  - class: Workflow
    doc: Convert Dir
    id: convert-dir
    label: convert dir app
    inputs:
      fn:
        type: string
      dir:
        type: Directory
      size:
        type: string
    outputs:
      - id: wf_outputs
        type: Directory
        outputSource:
          - convert/results
    steps:
      convert:
        run: "#convert"
        in:
          fn: fn
          dir: dir
          size: size
        out:
          - results

  # convert.sh - takes input args `--dir`
  - class: CommandLineTool
    id: convert
    baseCommand: convert.sh
    inputs:
      fn:
        type: string
        inputBinding:
          position: 1
      dir:
        type: Directory
        inputBinding:
          position: 2
          prefix: --dir
      size:
        type: string
        inputBinding:
          position: 3
    outputs:
      results:
        type: Directory
        outputBinding:
          glob: .
    requirements:
      DockerRequirement:
        dockerPull: rconway/convert:main
