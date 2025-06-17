# NextFlow DSL2 Module

```bash
AMRFINDERPLUS_RUN
```

## Description

Run `amrfinder` tool on a list of assembled contigs in FASTA format. Produces a single output table in ASCII text format per database.

\
&nbsp;

### `input:`

___

Type: `tuple`

Takes in the following tuple of metadata (`meta`) and a list of assemled contig FASTA file of input type `path` (`fasta`).

Ex:

```groovy
[ [id: 'sample1', single_end: true], '/data/sample1/f_assembly.fa' ]
```

\
&nbsp;

#### `meta`

Type: Groovy Map

A Groovy Map containing the metadata about the FASTQ file.

Ex:

```groovy
[ id: 'FAL00870', strandedness: 'unstranded', single_end: true, organism: 'Escherichia' ]
```

\
&nbsp;

#### `fasta`

Type: `path`

NextFlow input type of `path` pointing to assembled contig file in FASTA format.

\
&nbsp;

#### `args`

Type: Groovy String

String of optional command-line arguments to be passed to the tool. This can be mentioned in `process` scope within `withName:process_name` block using `ext.args` option within your `nextflow.config` file.

Ex:

```groovy
withName: 'AMRFINDERPLUS_RUN' {
    ext.args = '--gpipe_org'
}
```

### `output:`

___

Type: `tuple`

Outputs a tuple of metadata (`meta` from `input:`) and list of `amrfinder` result files (`report`).

\
&nbsp;

#### `report`

Type: `path`

NextFlow output type of `path` pointing to the `amrfinder` results table file (`.tsv`) per sample (`id:`).

\
&nbsp;

#### `mutional_report`

Type: `path`
\
Optional: `true`

NextFlow output type of `path` pointing to the `amrfinder` mutation results table file (`.tsv`) per sample (`id:`). Obtaining this output will depend on the presence of the `organism` key in the metadata (`meta`). See example above.

\
&nbsp;

#### `versions`

Type: `path`

NextFlow output type of `path` pointing to the `.yml` file storing software versions for this process.
