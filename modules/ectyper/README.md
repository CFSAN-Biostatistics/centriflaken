# NextFlow DSL2 Module

```bash
ECTYPER
```

## Description

Run `ectyper` tool on a list of assembled contigs in FASTA format. Produces a single output table in ASCII text format.

\
&nbsp;

### `input:`

___

Type: `tuple`

Takes in the following tuple of metadata (`meta`) and a list of assemled contig FASTA files of input type `path` (`fasta`).

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
[ id: 'FAL00870', strandedness: 'unstranded', single_end: true ]
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
withName: 'ECTYPER' {
    ext.args = '--detailed'
}
```

\
&nbsp;

### `output:`

___

Type: `tuple`

Outputs a tuple of metadata (`meta` from `input:`) and list of `ectyper` result files (`ectyped`).

\
&nbsp;

#### `ectyped`

Type: `path`

NextFlow output type of `path` pointing to the `ectyper` results table file per sample (`id:`).

\
&nbsp;

#### `versions`

Type: `path`

NextFlow output type of `path` pointing to the `.yml` file storing software versions for this process.
