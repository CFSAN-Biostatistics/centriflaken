# NextFlow DSL2 Module

```bash
CENTRIFUGE_PROCESS
```

## Description

Extract FASTQ reads given a FASTQ file originally used with `centrifuge` tool and a taxa of interest. This specific module uses a `python` script to generate the FASTQ read ids and as such requires a `bin` folder with `process_centrifuge_output.py` to be present where the NextFlow script will be executed from. See also `CENTRIFUGE_EXTRACT` module which uses only GNU Coreutils to create a list of FASTQ read ids that need to be extracted.

\
&nbsp;

### `input:`

___

Type: `tuple`

Takes in a tuple in order of metadata (`meta`), a `path` (`centrifuge_report`) type and another `path` (`centrifuge_report`) per sample (`id:`).

Ex:

```groovy
[ 
    [ id: 'FAL00870',
       strandedness: 'unstranded',
       single_end: true,
       centrifuge_x: '/hpc/db/centrifuge/2022-04-12/ab'
    ],
    '/hpc/scratch/test/FAL000870/f1.merged.cent_out.report.txt',
    '/hpc/scratch/test/FAL000870/f1.merged.cent_out.output.txt'
]
```

\
&nbsp;

#### `meta`

Type: Groovy Map

A Groovy Map containing the metadata about the FASTQ file.

Ex:

```groovy
[ 
    id: 'FAL00870',
    strandedness: 'unstranded',
    single_end: true,
    centrifuge_x: '/hpc/db/centrifuge/2022-04-12/ab'
]
```

\
&nbsp;

#### `centrifuge_report`

Type: `path`

NextFlow input type of `path` pointing to `centrifuge` report file generated using `--report-file` option of `centrifuge` tool.

\
&nbsp;

#### `centrifuge_output`

Type: `path`

NextFlow input type of `path` pointing to `centrifuge` output file generated using `-S` option of `centrifuge` tool.

\
&nbsp;

### `output:`

___

Type: `tuple`

Outputs a tuple of metadata (`meta` from `input:`) and list of extracted FASTQ read ids.

\
&nbsp;

#### `extracted`

Type: `path`

NextFlow output type of `path` pointing to the extracted FASTQ read ids belonging to a particular taxa (`*.extract-centrifuge-bug-ids.txt`).

\
&nbsp;

#### `versions`

Type: `path`

NextFlow output type of `path` pointing to the `.yml` file storing software versions for this process.
