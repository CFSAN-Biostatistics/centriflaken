# NextFlow DSL2 Module

```bash
CENTRIFUGE_CLASSIFY
```

## Description

Run `centrifuge` tool on reads in FASTQ format. Produces 3 output files in ASCII text format and optional output files.

\
&nbsp;

### `input:`

___

Type: `tuple`

Takes in the following tuple of metadata (`meta`) and a list of reads of type `path` (`reads`) per sample (`id:`).

Ex:

```groovy
[ 
    [ id: 'FAL00870',
       strandedness: 'unstranded',
       single_end: true,
       centrifuge_x: '/hpc/db/centrifuge/2022-04-12/ab'
    ],
    '/hpc/scratch/test/FAL000870/f1.merged.fq.gz'
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

#### `reads`

Type: `path`

NextFlow input type of `path` pointing to FASTQ files on which `centrifuge` classification should be run.

\
&nbsp;

#### `args`

Type: Groovy String

String of optional command-line arguments to be passed to the tool. This can be mentioned in `process` scope within `withName:process_name` block using `ext.args` option within your `nextflow.config` file.

Ex:

```groovy
withName: 'CENTRIFUGE_CLASSIFY' {
    ext.args = '--met 3'
}
```

\
&nbsp;

### `output:`

___

Type: `tuple`

Outputs a tuple of metadata (`meta` from `input:`) and list of `centrifuge` result files.

\
&nbsp;

#### `report`

Type: `path`

NextFlow output type of `path` pointing to the `centrifuge` report table file (`.report.txt`) per sample (`id:`).

\
&nbsp;

#### `output`

Type: `path`

NextFlow output type of `path` pointing to the `centrifuge` output table file (`.output.txt`) per sample (`id:`).

\
&nbsp;

#### `kreport`

Type: `path`

NextFlow output type of `path` pointing to the `centrifuge` **Kraken** style report table file (`.kreport.txt`) per sample (`id:`).

\
&nbsp;

#### `sam`

Type: `path`
\
Optional: `true`

NextFlow output type of `path` pointing to the `centrifuge` alignment results in SAM (`.sam`) format per sample (`id:`). Obtaining this output will depend on the mention of `--centrifuge_out_fmt_sam` command-line option when the NextFlow pipeline is called.

\
&nbsp;

#### `fastq_mapped`

Type: `path`
\
Optional: `true`

NextFlow output type of `path` pointing to the `centrifuge` alignment results in FASTQ (`.fastq.gz`) format per sample (`id:`). Obtaining this output will depend on the mention of `--centrifuge_save_aligned` command-line option when the NextFlow pipeline is called.

\
&nbsp;

#### `fastq_unmapped`

Type: `path`
\
Optional: `true`

NextFlow output type of `path` pointing to the `centrifuge` FASTQ (`.fastq.gz`) files of unaligned reads per sample (`id:`). Obtaining this output will depend on the mention of `--centrifuge_save_unaligned` command-line option when the NextFlow pipeline is called.

\
&nbsp;

#### `versions`

Type: `path`

NextFlow output type of `path` pointing to the `.yml` file storing software versions for this process.
