# NextFlow DSL2 Module

```bash
KRAKEN2_EXTRACT
```

## Description

Extract FASTA reads or contigs given a FASTA file originally used with `kraken2` tool and a taxa of interest. This specific module uses a `python` script to generate the FASTA reads or contigs and as such requires a `bin` folder with `extract_assembled_filtered_contigs.py` script to be present where the NextFlow script will be executed from.

\
&nbsp;

### `input:`

___

Type: `tuple`

Takes in a tuple in order of metadata (`meta`), a `path` (`kraken2_output`) type and another `path` (`assembly`) per sample (`id:`).

Ex:

```groovy
[ 
    [ id: 'FAL00870',
       strandedness: 'unstranded',
       single_end: true,
       kraken2_db: '/hpc/db/kraken2/standard-210914'
    ],
    '/hpc/scratch/test/FAL000870/f1.merged.kraken2.output.txt',
    '/hpc/scratch/test/FAL000870/f1.assembly.fasta'
]
```

\
&nbsp;

#### `meta`

Type: Groovy Map

A Groovy Map containing the metadata about the FASTA file.

Ex:

```groovy
[ 
    id: 'FAL00870',
    strandedness: 'unstranded',
    single_end: true,
    kraken2_db: '/hpc/db/kraken2/standard-210914'
]
```

\
&nbsp;

#### `kraken2_output`

Type: `path`

NextFlow input type of `path` pointing to `kraken2` output file generated using `--output` option of `kraken2` tool.

\
&nbsp;

#### `assembly`

Type: `path`

NextFlow input type of `path` pointing to a FASTA format file, in this case an assembled contig file in FASTA format.

\
&nbsp;

### `output:`

___

Type: `tuple`

Outputs a tuple of metadata (`meta` from `input:`) and list of extracted FASTQ read ids.

\
&nbsp;

#### `asm_filtered_contigs`

Type: `path`

NextFlow output type of `path` pointing to the extracted FASTA reads or contigs belonging to a particular taxa.

\
&nbsp;

#### `versions`

Type: `path`

NextFlow output type of `path` pointing to the `.yml` file storing software versions for this process.
