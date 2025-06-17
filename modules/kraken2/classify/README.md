# NextFlow DSL2 Module

```bash
KRAKEN2_CLASSIFY
```

## Description

Run `kraken2` tool on reads in FASTQ format. Produces 4 output files per sample (`id:`) in ASCII text format.

\
&nbsp;

### `input:`

___

Type: `tuple`

Takes in the following tuple of metadata (`meta`) and a list of reads or FASTA assembly of type `path` (`reads`) per sample (`id:`).

Ex:

```groovy
[ 
    [ id: 'FAL00870',
       strandedness: 'unstranded',
       single_end: true,
       is_assembly: false,
       centrifuge_x: '/hpc/db/centrifuge/2022-04-12/ab'
       kraken2_db: '/hpc/db/kraken2/standard-210914',
    ],
    '/hpc/scratch/test/FAL000870/f1.merged.fq.gz'
]
```

\
&nbsp;

#### `meta`

Type: Groovy Map

A Groovy Map containing the metadata about the FASTQ / FASTA file.

Ex:

```groovy
[ 
    id: 'FAL00870',
    strandedness: 'unstranded',
    single_end: true,
    is_assembly: false,
    kraken2_db: '/hpc/db/kraken2/standard-210914'
]
```

\
&nbsp;

#### `reads`

Type: `path`

NextFlow input type of `path` pointing to FASTQ files on which `kraken2` classification should be run.

\
&nbsp;

### `output:`

___

Type: `tuple`

Outputs a tuple of metadata (`meta` from `input:`) and list of `kraken2` result files.

\
&nbsp;

#### `kraken_report`

Type: `path`

NextFlow output type of `path` pointing to the `kraken2` report table file (`.report.txt`) per sample (`id:`).

\
&nbsp;

#### `kraken_output`

Type: `path`

NextFlow output type of `path` pointing to the `kraken2` output table file (`.output.txt`) per sample (`id:`).

\
&nbsp;

#### `classified`

Type: `path`

NextFlow output type of `path` pointing to the `kraken2` processed gzipped FASTQ files containing only reads that have been classified (`*classified.fastq`) per sample (`id:`).

\
&nbsp;

#### `unclassified`

Type: `path`

NextFlow output type of `path` pointing to the `kraken2` processed gzipped FASTQ files containing only reads that are unclassified (`*unclassified.fastq`) per sample (`id:`).

\
&nbsp;

#### `versions`

Type: `path`

NextFlow output type of `path` pointing to the `.yml` file storing software versions for this process.
