# centriflaken

`centriflaken` is an automated precision metagenomics workflow for assembly and _in silico_ analyses of food-borne pathogens. `centriflaken` primarily fine-tuned for detecting and classifying Shiga toxin-producing **_Escherichia coli_** (**STEC**) can also be used for performing analyses on other food-borne pathogens such as **_Salmonella enterica_**.  `centriflaken` takes as input a UNIX path to FASTQ, generates MAGs, and performs in silico-based analysis for STECs as described in [Maguire et al. 2021](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0245172).

`centriflaken` works on both **Illumina** short reads and **Oxford Nanopore** long reads.

It is written in **Nextflow** and is part of the modular data analysis pipelines at **HFP**.

\
&nbsp;

<!-- TOC -->

- [Minimum Requirements](#minimum-requirements)
- [HFP GalaxyTrakr](#hfp-galaxytrakr)
- [Usage and Examples](#usage-and-examples)
  - [Databases](#databases)
  - [Input](#input)
    - [Illumina short reads](#illumina-short-reads)
  - [Output](#output)
  - [Computational resources](#computational-resources)
  - [Runtime profiles](#runtime-profiles)
  - [your_institution.config](#your_institutionconfig)
  - [Test run](#test-run)
- [centriflaken CLI Help](#centriflaken-cli-help)
- [centriflaken_hy CLI Help](#centriflaken_hy-cli-help)

<!-- /TOC -->

\
&nbsp;

## Minimum Requirements

1. [Nextflow version 24.10.4](https://github.com/nextflow-io/nextflow/releases/download/v24.10.4/nextflow).
    - Make the `nextflow` binary executable (`chmod 755 nextflow`) and also make sure that it is made available in your `$PATH`.
    - If your existing `JAVA` install does not support the newest **Nextflow** version, you can try **Amazon**'s `JAVA` (OpenJDK):  [Corretto](https://docs.aws.amazon.com/corretto/latest/corretto-21-ug/downloads-list.html).
2. Either of `micromamba` (version `1.5.9`) or `docker` or `singularity` installed and made available in your `$PATH`.
    - Running the workflow via `micromamba` software provisioning is **preferred** as it does not require any `sudo` or `admin` privileges or any other configurations with respect to the various container providers.
    - To install `micromamba` for your system type, please follow these [installation steps](https://mamba.readthedocs.io/en/latest/installation/micromamba-installation.html#linux-and-macos) and make sure that the `micromamba` binary is made available in your `$PATH`.
    - Just the `curl` step is sufficient to download the binary as far as running the workflows are concerned.
    - Once you have finished the installation, **it is important that you downgrade `micromamba` to version `1.5.9`**.
    - First check, if your version is other than `1.5.9` and if not, do the downgrade.

        ```bash
        micromamba --version
        micromamba self-update --version 1.5.9 -c conda-forge
        ```

3. Minimum of 10 CPU cores and about 60 GBs for main workflow steps. More memory may be required if your **FASTQ** files are big.

\
&nbsp;

## HFP GalaxyTrakr

The `centriflaken` pipeline is also available for use on the [Galaxy instance supported by HFP, FDA](https://galaxytrakr.org/). If you wish to run the analysis using **Galaxy**, please register for an account, after which [you can run the workflow using this protocol](https://www.protocols.io/view/centriflaken-an-automated-data-analysis-pipeline-f-kxygxzdbwv8j/v5).

Please note that the pipeline on [HFP GalaxyTrakr](https://galaxytrakr.org) in most cases may be a version older than the one on **GitHub** due to testing prioritization.

\
&nbsp;

## Usage and Examples

Clone or download this repository and then call `cpipes`.

```bash
cpipes --pipeline centriflaken [options]
```

Alternatively, you can use `nextflow` to directly pull and run the pipeline.

```bash
nextflow pull CFSAN-Biostatistics/centriflaken
nextflow list
nextflow info CFSAN-Biostatistics/centriflaken
nextflow run CFSAN-Biostatistics/centriflaken --pipeline centriflaken --help
nextflow run CFSAN-Biostatistics/centriflaken --pipeline centriflaken_hy --help
```

\
&nbsp;

### Databases

---

The successful run of the workflow requires all of the following databases:

- `kraken2`, `centrifuge`, `serotypefinder` and `abricate`: [Download](https://cfsan-pub-xfer.s3.amazonaws.com/Kranti.Konganti/centriflaken/centriflaken_dbs.tar.bz2).

Once you have downloaded the databases, uncompress and set the **UNIX** path's in the configuration files as follows:

- [Line no. 4](../workflows/conf/centriflaken.config#L4): `centrifuge_x = /path/to/centriflaken_dbs/centrifuge/ab`. The `ab` prefix is necessary.
- [Line no. 12](../workflows/conf/centriflaken_hy.config#L12): `centrifuge_x = /path/to/centriflaken_dbs/centrifuge/ab`. The `ab` prefix is necessary.
- [Line no. 10](../workflows/conf/centriflaken.config#L10): `kraken2_db = /path/to/centriflaken_dbs/kraken2`.
- [Line no. 12](../workflows/conf/centriflaken_hy.config#L18): `kraken2_db = /path/to/centriflaken_dbs/kraken2`.
- [Line no. 12](../workflows/conf/centriflaken.config#L36): `serotypefinder_db = /path/to/centriflaken_dbs/serotypefinder`.
- [Line no. 12](../workflows/conf/centriflaken_hy.config#L64): `serotypefinder_db = /path/to/centriflaken_dbs/serotypefinder`.
- [Line no. 12](../workflows/conf/centriflaken.config#L53): `abricate_datadir = /path/to/centriflaken_dbs/abricate`.
- [Line no. 12](../workflows/conf/centriflaken_hy.config#L81): `centrifuge_x = /path/to/centriflaken_dbs/abricate`.

\
&nbsp;

### Input

---

The input to the workflow is a folder containing compressed (`.gz`) FASTQ files of long reads or short reads. Please note that the sample grouping happens automatically by the file name of the FASTQ file. If for example, a single sample is sequenced across multiple sequencing lanes, you can choose to group those FASTQ files into one sample by using the `--fq_filename_delim` and `--fq_filename_delim_idx` options. By default, `--fq_filename_delim` is set to `_` (underscore) and `--fq_filename_delim_idx` is set to 1.

For example, if the directory contains FASTQ files as shown below:

- KB-01_apple_L001_R1.fastq.gz
- KB-01_apple_L001_R2.fastq.gz
- KB-01_apple_L002_R1.fastq.gz
- KB-01_apple_L002_R2.fastq.gz
- KB-02_mango_L001_R1.fastq.gz
- KB-02_mango_L001_R2.fastq.gz
- KB-02_mango_L002_R1.fastq.gz
- KB-02_mango_L002_R2.fastq.gz

Then, to create 2 sample groups, `apple` and `mango`, we split the file name by the delimitor (underscore in the case, which is default) and group by the first 2 words (`--fq_filename_delim_idx 2`).

This goes without saying that all the FASTQ files should have uniform naming patterns so that `--fq_filename_delim` and `--fq_filename_delim_idx` options do not have any adverse effect in collecting and creating a sample metadata sheet.

\
&nbsp;

### Illumina short reads

---

`centriflaken` was primarily developed for **ONT** long reads but also supports **Illumina** short reads. Use the `--pipeline centriflaken_hy` instead of `--pipeline centriflaken` to activate this feature. The `centriflaken_hy` variant of the pipeline uses `megahit` instead of `flye` to perform short read assembly. There is no other change needed from the user other than using the `--pipeline centriflaken_hy` parameter for Illumina short reads.

\
&nbsp;

### Output

---

All the outputs for each step are stored inside the folder mentioned with the `--output` option. A `multiqc_report.html` file inside the `centriflaken-multiqc` folder can be opened in any browser on your local workstation which contains a consolidated brief report.

\
&nbsp;

### Computational resources

---

The workflows `centriflaken` and `centriflaken_hy` require at least a minimum of 60 GBs of memory to successfully finish the workflow.

\
&nbsp;

### Runtime profiles

---

You can use different run time profiles that suit your specific compute environments i.e., you can run the workflow locally on your machine or in a grid computing infrastructure.

\
&nbsp;

Example:

```bash
cd /data/scratch/$USER
mkdir nf-cpipes
cd nf-cpipes
cpipes \
    --pipeline centriflaken \
    --input /path/to/fastq_pass_dir \
    --output /path/to/where/output/should/go \
    -profile your_institution
```

The above command would run the pipeline and store the output at the location per the `--output` flag and the **NEXTFLOW** reports are always stored in the current working directory from where `cpipes` is run. For example, for the above command, a directory called `CPIPES-centriflaken` would hold all the **NEXTFLOW** related logs, reports and trace files.

\
&nbsp;

### `your_institution.config`

---

In the above example, we can see that we have mentioned the run time profile as `your_institution`. For this to work, add the following lines at the end of [`computeinfra.config`](../conf/computeinfra.config) file which should be located inside the `conf` folder. For example, if your institution uses **SGE** or **UNIVA** for grid computing instead of **SLURM** and has a job queue named `normal.q`, then add these lines:

\
&nbsp;

```groovy
your_institution {
    process.executor = 'sge'
    process.queue = 'normal.q'
    singularity.enabled = false
    singularity.autoMounts = true
    docker.enabled = false
    params.enable_conda = true
    conda.enabled = true
    conda.useMicromamba = true
    params.enable_module = false
}
```

In the above example, by default, all the software provisioning choices are disabled except `conda`. You can also choose to remove the `process.queue` line altogether and the `centriflaken` workflow will request the appropriate memory and number of CPU cores automatically, which ranges from 1 CPU, 1 GB and 1 hour for job completion up to 10 CPU cores, 1 TB and 120 hours for job completion.

\
&nbsp;

### Cloud computing

---

You can run the workflow in the cloud (works only with proper set up of AWS resources). Add new run time profiles with required parameters per [Nextflow docs](https://www.nextflow.io/docs/latest/executor.html):

\
&nbsp;

Example:

```groovy
my_aws_batch {
    executor = 'awsbatch'
    queue = 'my-batch-queue'
    aws.batch.cliPath = '/home/ec2-user/miniconda/bin/aws'
    aws.batch.region = 'us-east-1'
    singularity.enabled = false
    singularity.autoMounts = true
    docker.enabled = true
    params.conda_enabled = false
    params.enable_module = false
}
```

\
&nbsp;

### Test run

---

After you make sure that you have all the [minimum requirements](#minimum-requirements) to run the workflow, you can try the `centriflaken` pipeline on some subsampled reads belonging to the NCBI BioProject `PRJNA639799` as discussed in [Maguire _et al_](https://pmc.ncbi.nlm.nih.gov/articles/PMC10500926/).

- Please note that the input reads are subsampled to validate the software install.
- Download them [from S3](https://cfsan-pub-xfer.s3.amazonaws.com/Kranti.Konganti/centriflaken/macguire_et_al_subsampled_reads.tar.bz2) (~ 20 GB).

  | Samples                                                        | Biosample    | SRA accession | Flowcell |
  |:---------------------------------------------------------------|:-------------|:--------------|:---------|
  | FAL00958                                                       | SAMN46790801 | SRR32346290   | FAL00958 |
  | FAL01198                                                       | SAMN46793213 | SRR32346289   | FAL01198 |
  | FAL01556                                                       | SAMN46793220 | SRR32346278   | FAL01556 |
  | ZymoBIOMICS Microbial Community DNA Standard R1                | SAMN46793392 | SRR32381322   | FAL11413 |
  | ZymoBIOMICS Microbial Community DNA Standard R2                | SAMN46793393 | SRR32381321   | FAL01565 |
  | ZymoBIOMICS Microbial Community Standard II - log distribution | SAMN46793397 | SRR32381320   | FAL01514 |

- Download pre-formatted  databases (**MANDATORY**) [from S3](https://cfsan-pub-xfer.s3.amazonaws.com/Kranti.Konganti/centriflaken/centriflaken_dbs.tar.bz2) (~ 47 GB).
- One of the assembly jobs should fail to assemble the reads and the pipeline will ignore the failed assembly and finish to completion.
- After successful download, untar and change the paths to the databases in **BOTH** the [long reads conf file](../workflows/conf/centriflaken.config) and [short reads conf file](../workflows/conf/centriflaken_hy.config) as described in the [Databases](#databases) section.
- The following values should point to the UNIX paths of the downloaded databases.

    ```bash
    centrifuge_x = '/path/to/centrifuge/ab' # /ab suffix SHOULD NOT change. Only the /path/to/centrifuge changes to your specific UNIX path.
    kraken2_db = '/path/to/kraken2'
    serotypefinder_db = '/path/to/serotypefinder'
    abricate_datadir = '/path/to/abricate'
    amrfinderplus_db = '/hpc/db/amrfinderplus/3.10.24/latest' # IGNORE THIS PATH SINCE AMRFINDERPLUS SHOULD NOT BE RUN.
    ```

- It is always a best practice to use absolute UNIX paths and real destinations of symbolic links during pipeline execution. For example, find out the real path(s) of your absolute UNIX path(s) and use that for the `--input` and `--output` options of the pipeline.

  ```bash
  realpath /hpc/scratch/user/input/srr
  ```

- Now run the workflow by ignoring quality values since these are simulated base qualities:

    ```bash
    cpipes \
        --pipeline centriflaken \
        --input /path/to/macguire_et_al_subsampled_reads \
        --output /path/to/centriflaken_test_output \
        -profile stdkondagac \
        -resume
    ```

- After succesful run of the workflow, your **MultiQC** report should look something like [this](https://cfsan-pub-xfer.s3.us-east-1.amazonaws.com/Kranti.Konganti/centriflaken/macquire_et_al_test_report.html).

Please note that the run time profile `stdkondagac` will run jobs locally using `micromamba` for software provisioning. The first time you run the command, a new folder called `kondagac_cache` will be created and subsequent runs should use this `conda` cache.

\
&nbsp;

## `centriflaken` CLI Help

```text
cpipes --pipeline centriflaken --help

 N E X T F L O W   ~  version 24.10.4

Launching `/home/user/centriflaken/cpipes` [sleepy_pauling] DSL2 - revision: 55d6f63710

================================================================================
             (o)                  
  ___  _ __   _  _ __    ___  ___ 
 / __|| '_ \ | || '_ \  / _ \/ __|
| (__ | |_) || || |_) ||  __/\__ \
 \___|| .__/ |_|| .__/  \___||___/
      | |       | |               
      |_|       |_|
--------------------------------------------------------------------------------
A collection of modular pipelines at CFSAN, FDA.
--------------------------------------------------------------------------------
Name                            : CPIPES
Author                          : Kranti.Konganti@fda.hhs.gov
Version                         : 0.4.1
Center                          : CFSAN, FDA.
================================================================================

Workflow                        : centriflaken

Author                          : Kranti.Konganti@fda.hhs.gov

Version                         : 0.4.2


Usage                           : cpipes --pipeline centriflaken [options]


Required                        : 

--input                         : Absolute path to directory containing FASTQ 
                                  files. The directory should contain only 
                                  FASTQ files as all the files within the 
                                  mentioned directory will be read. Ex: --
                                  input /path/to/fastq_pass

--output                        : Absolute path to directory where all the 
                                  pipeline outputs should be stored. Ex: --
                                  output /path/to/output

Other options                   : 

--metadata                      : Absolute path to metadata CSV file 
                                  containing five mandatory columns: sample,
                                  fq1,fq2,strandedness,single_end. The fq1 
                                  and fq2 columns contain absolute paths to 
                                  the FASTQ files. This option can be used in 
                                  place of --input option. This is rare. Ex: --
                                  metadata samplesheet.csv

--fq_suffix                     : The suffix of FASTQ files (Unpaired reads 
                                  or R1 reads or Long reads) if an input 
                                  directory is mentioned via --input option. 
                                  Default: .fastq.gz

--fq2_suffix                    : The suffix of FASTQ files (Paired-end reads 
                                  or R2 reads) if an input directory is 
                                  mentioned via --input option. Default: 
                                  false

--fq_filter_by_len              : Remove FASTQ reads that are less than this 
                                  many bases. Default: 4000

--fq_strandedness               : The strandedness of the sequencing run. 
                                  This is mostly needed if your sequencing 
                                  run is RNA-SEQ. For most of the other runs, 
                                  it is probably safe to use unstranded for 
                                  the option. Default: unstranded

--fq_single_end                 : SINGLE-END information will be auto-
                                  detected but this option forces PAIRED-END 
                                  FASTQ files to be treated as SINGLE-END so 
                                  only read 1 information is included in auto-
                                  generated samplesheet. Default: false

--fq_filename_delim             : Delimiter by which the file name is split 
                                  to obtain sample name. Default: _

--fq_filename_delim_idx         : After splitting FASTQ file name by using 
                                  the --fq_filename_delim option, all 
                                  elements before this index (1-based) will 
                                  be joined to create final sample name. 
                                  Default: 1

--kraken2_db                    : Absolute path to kraken database. Default: /
                                  hpc/db/kraken2/standard-210914

--kraken2_confidence            : Confidence score threshold which must be 
                                  between 0 and 1. Default: 0.0

--kraken2_quick                 : Quick operation (use first hit or hits). 
                                  Default: false

--kraken2_use_mpa_style         : Report output like Kraken 1's kraken-mpa-
                                  report. Default: false

--kraken2_minimum_base_quality  : Minimum base quality used in classification  
                                  which is only effective with FASTQ input. 
                                  Default: 0

--kraken2_report_zero_counts    : Report counts for ALL taxa, even if counts 
                                  are zero. Default: false

--kraken2_report_minmizer_data  : Report minimizer and distinct minimizer 
                                  count information in addition to normal 
                                  Kraken report. Default: false

--kraken2_use_names             : Print scientific names instead of just 
                                  taxids. Default: true

--kraken2_extract_bug           : Extract the reads or contigs beloging to 
                                  this bug. Default: Escherichia coli

--centrifuge_x                  : Absolute path to centrifuge database. 
                                  Default: /hpc/db/centrifuge/2022-04-12/ab

--centrifuge_save_unaligned     : Save SINGLE-END reads that did not align. 
                                  For PAIRED-END reads, save read pairs that 
                                  did not align concordantly. Default: false

--centrifuge_save_aligned       : Save SINGLE-END reads that aligned. For 
                                  PAIRED-END reads, save read pairs that 
                                  aligned concordantly. Default: false

--centrifuge_out_fmt_sam        : Centrifuge output should be in SAM. Default: 
                                  false

--centrifuge_extract_bug        : Extract this bug from centrifuge results. 
                                  Default: Escherichia coli

--centrifuge_ignore_quals       : Treat all quality values as 30 on Phred 
                                  scale. Default: false

--flye_pacbio_raw               : Input FASTQ reads are PacBio regular CLR 
                                  reads (<20% error) Defaut: false

--flye_pacbio_corr              : Input FASTQ reads are PacBio reads that 
                                  were corrected with other methods (<3% 
                                  error). Default: false

--flye_pacbio_hifi              : Input FASTQ reads are PacBio HiFi reads (<1% 
                                  error). Default: false

--flye_nano_raw                 : Input FASTQ reads are ONT regular reads, 
                                  pre-Guppy5 (<20% error). Default: true

--flye_nano_corr                : Input FASTQ reads are ONT reads that were 
                                  corrected with other methods (<3% error). 
                                  Default: false

--flye_nano_hq                  : Input FASTQ reads are ONT high-quality 
                                  reads: Guppy5+ SUP or Q20 (<5% error). 
                                  Default: false

--flye_genome_size              : Estimated genome size (for example, 5m or 2.
                                  6g). Default: 5.5m

--flye_polish_iter              : Number of genome polishing iterations. 
                                  Default: false

--flye_meta                     : Do a metagenome assembly (unenven coverage 
                                  mode). Default: true

--flye_min_overlap              : Minimum overlap between reads. Default: 
                                  false

--flye_scaffold                 : Enable scaffolding using assembly graph. 
                                  Default: false

--serotypefinder_run            : Run SerotypeFinder tool. Default: true

--serotypefinder_x              : Generate extended output files. Default: 
                                  true

--serotypefinder_db             : Path to SerotypeFinder databases. Default: /
                                  hpc/db/serotypefinder/2.0.2

--serotypefinder_min_threshold  : Minimum percent identity (in float) 
                                  required for calling a hit. Default: 0.85

--serotypefinder_min_cov        : Minumum percent coverage (in float) 
                                  required for calling a hit. Default: 0.80

--seqsero2_run                  : Run SeqSero2 tool. Default: false

--seqsero2_t                    : '1' for interleaved paired-end reads, '2' 
                                  for separated paired-end reads, '3' for 
                                  single reads, '4' for genome assembly, '5' 
                                  for nanopore reads (fasta/fastq). Default: 
                                  4

--seqsero2_m                    : Which workflow to apply, 'a'(raw reads 
                                  allele micro-assembly), 'k'(raw reads and 
                                  genome assembly k-mer). Default: k

--seqsero2_c                    : SeqSero2 will only output serotype 
                                  prediction without the directory containing 
                                  log files. Default: false

--seqsero2_s                    : SeqSero2 will not output header in 
                                  SeqSero_result.tsv. Default: false

--mlst_run                      : Run MLST tool. Default: true

--mlst_minid                    : DNA %identity of full allelle to consider '
                                  similar' [~]. Default: 95

--mlst_mincov                   : DNA %cov to report partial allele at all [?].
                                  Default: 10

--mlst_minscore                 : Minumum score out of 100 to match a scheme.
                                  Default: 50

--abricate_run                  : Run ABRicate tool. Default: true

--abricate_minid                : Minimum DNA %identity. Defaut: 90

--abricate_mincov               : Minimum DNA %coverage. Defaut: 80

--abricate_datadir              : ABRicate databases folder. Defaut: /hpc/db/
                                  abricate/1.0.1/db

Help options                    : 

--help                          : Display this message.
```

\
&nbsp;

## `centriflaken_hy` CLI Help

```text
cpipes --pipeline centriflaken_hy --help

 N E X T F L O W   ~  version 24.10.4

Launching `/home/user/centriflaken/cpipes` [big_ramanujan] DSL2 - revision: 55d6f63710

================================================================================
             (o)                  
  ___  _ __   _  _ __    ___  ___ 
 / __|| '_ \ | || '_ \  / _ \/ __|
| (__ | |_) || || |_) ||  __/\__ \
 \___|| .__/ |_|| .__/  \___||___/
      | |       | |               
      |_|       |_|
--------------------------------------------------------------------------------
A collection of modular pipelines at CFSAN, FDA.
--------------------------------------------------------------------------------
Name                            : CPIPES
Author                          : Kranti.Konganti@fda.hhs.gov
Version                         : 0.4.1
Center                          : CFSAN, FDA.
================================================================================

Workflow                        : centriflaken_hy

Author                          : Kranti.Konganti@fda.hhs.gov

Version                         : 0.4.1


Usage                           : cpipes --pipeline centriflaken_hy [options]


Required                        : 

--input                         : Absolute path to directory containing FASTQ 
                                  files. The directory should contain only 
                                  FASTQ files as all the files within the 
                                  mentioned directory will be read. Ex: --
                                  input /path/to/fastq_pass

--output                        : Absolute path to directory where all the 
                                  pipeline outputs should be stored. Ex: --
                                  output /path/to/output

Other options                   : 

--metadata                      : Absolute path to metadata CSV file 
                                  containing five mandatory columns: sample,
                                  fq1,fq2,strandedness,single_end. The fq1 
                                  and fq2 columns contain absolute paths to 
                                  the FASTQ files. This option can be used in 
                                  place of --input option. This is rare. Ex: --
                                  metadata samplesheet.csv

--fq_suffix                     : The suffix of FASTQ files (Unpaired reads 
                                  or R1 reads or Long reads) if an input 
                                  directory is mentioned via --input option. 
                                  Default: _R1_001.fastq.gz

--fq2_suffix                    : The suffix of FASTQ files (Paired-end reads 
                                  or R2 reads) if an input directory is 
                                  mentioned via --input option. Default: 
                                  _R2_001.fastq.gz

--fq_filter_by_len              : Remove FASTQ reads that are less than this 
                                  many bases. Default: 75

--fq_strandedness               : The strandedness of the sequencing run. 
                                  This is mostly needed if your sequencing 
                                  run is RNA-SEQ. For most of the other runs, 
                                  it is probably safe to use unstranded for 
                                  the option. Default: unstranded

--fq_single_end                 : SINGLE-END information will be auto-
                                  detected but this option forces PAIRED-END 
                                  FASTQ files to be treated as SINGLE-END so 
                                  only read 1 information is included in auto-
                                  generated samplesheet. Default: false

--fq_filename_delim             : Delimiter by which the file name is split 
                                  to obtain sample name. Default: _

--fq_filename_delim_idx         : After splitting FASTQ file name by using 
                                  the --fq_filename_delim option, all 
                                  elements before this index (1-based) will 
                                  be joined to create final sample name. 
                                  Default: 1

--seqkit_rmdup_run              : Remove duplicate sequences using seqkit 
                                  rmdup. Default: false

--seqkit_rmdup_n                : Match and remove duplicate sequences by 
                                  full name instead of just ID. Defaut: false

--seqkit_rmdup_s                : Match and remove duplicate sequences by 
                                  sequence content. Defaut: true

--seqkit_rmdup_d                : Save the duplicated sequences to a file. 
                                  Defaut: false

--seqkit_rmdup_D                : Save the number and list of duplicated 
                                  sequences to a file. Defaut: false

--seqkit_rmdup_i                : Ignore case while using seqkit rmdup. 
                                  Defaut: false

--seqkit_rmdup_P                : Only consider positive strand (i.e. 5') 
                                  when comparing by sequence content. Defaut: 
                                  false

--kraken2_db                    : Absolute path to kraken database. Default: /
                                  hpc/db/kraken2/standard-210914

--kraken2_confidence            : Confidence score threshold which must be 
                                  between 0 and 1. Default: 0.0

--kraken2_quick                 : Quick operation (use first hit or hits). 
                                  Default: false

--kraken2_use_mpa_style         : Report output like Kraken 1's kraken-mpa-
                                  report. Default: false

--kraken2_minimum_base_quality  : Minimum base quality used in classification  
                                  which is only effective with FASTQ input. 
                                  Default: 0

--kraken2_report_zero_counts    : Report counts for ALL taxa, even if counts 
                                  are zero. Default: false

--kraken2_report_minmizer_data  : Report minimizer and distinct minimizer 
                                  count information in addition to normal 
                                  Kraken report. Default: false

--kraken2_use_names             : Print scientific names instead of just 
                                  taxids. Default: true

--kraken2_extract_bug           : Extract the reads or contigs beloging to 
                                  this bug. Default: Escherichia coli

--centrifuge_x                  : Absolute path to centrifuge database. 
                                  Default: /hpc/db/centrifuge/2022-04-12/ab

--centrifuge_save_unaligned     : Save SINGLE-END reads that did not align. 
                                  For PAIRED-END reads, save read pairs that 
                                  did not align concordantly. Default: false

--centrifuge_save_aligned       : Save SINGLE-END reads that aligned. For 
                                  PAIRED-END reads, save read pairs that 
                                  aligned concordantly. Default: false

--centrifuge_out_fmt_sam        : Centrifuge output should be in SAM. Default: 
                                  false

--centrifuge_extract_bug        : Extract this bug from centrifuge results. 
                                  Default: Escherichia coli

--centrifuge_ignore_quals       : Treat all quality values as 30 on Phred 
                                  scale. Default: false

--megahit_run                   : Run MEGAHIT assembler. Default: true

--megahit_min_count             : <int>. Minimum multiplicity for filtering (
                                  k_min+1)-mers. Defaut: false

--megahit_k_list                : Comma-separated list of kmer size. All 
                                  values must be odd, in the range 15-255, 
                                  increment should be <= 28. Ex: '21,29,39,59,
                                  79,99,119,141'. Default: false

--megahit_no_mercy              : Do not add mercy k-mers. Default: false

--megahit_bubble_level          : <int>. Intensity of bubble merging (0-2), 0 
                                  to disable. Default: false

--megahit_merge_level           : <l,s>. Merge complex bubbles of length <= l*
                                  kmer_size and similarity >= s. Default: 
                                  false

--megahit_prune_level           : <int>. Strength of low depth pruning (0-3). 
                                  Default: false

--megahit_prune_depth           : <int>. Remove unitigs with avg k-mer depth 
                                  less than this value. Default: false

--megahit_low_local_ratio       : <float>. Ratio threshold to define low 
                                  local coverage contigs. Default: false

--megahit_max_tip_len           : <int>. remove tips less than this value [<
                                  int> * k]. Default: false

--megahit_no_local              : Disable local assembly. Default: false

--megahit_kmin_1pass            : Use 1pass mode to build SdBG of k_min. 
                                  Default: false

--megahit_preset                : <str>. Override a group of parameters. 
                                  Valid values are meta-sensitive which 
                                  enforces '--min-count 1 --k-list 21,29,39,
                                  49,...,129,141', meta-large (large & 
                                  complex metagenomes, like soil) which 
                                  enforces '--k-min 27 --k-max 127 --k-step 
                                  10'. Default: meta-sensitive

--megahit_mem_flag              : <int>. SdBG builder memory mode. 0: minimum; 
                                  1: moderate; 2: use all memory specified. 
                                  Default: 2

--megahit_min_contig_len        : <int>.  Minimum length of contigs to output. 
                                  Default: false

--spades_run                    : Run SPAdes assembler. Default: false

--spades_isolate                : This flag is highly recommended for high-
                                  coverage isolate and multi-cell data. 
                                  Defaut: false

--spades_sc                     : This flag is required for MDA (single-cell) 
                                  data. Default: false

--spades_meta                   : This flag is required for metagenomic data. 
                                  Default: true

--spades_bio                    : This flag is required for biosytheticSPAdes 
                                  mode. Default: false

--spades_corona                 : This flag is required for coronaSPAdes mode. 
                                  Default: false

--spades_rna                    : This flag is required for RNA-Seq data. 
                                  Default: false

--spades_plasmid                : Runs plasmidSPAdes pipeline for plasmid 
                                  detection. Default: false

--spades_metaviral              : Runs metaviralSPAdes pipeline for virus 
                                  detection. Default: false

--spades_metaplasmid            : Runs metaplasmidSPAdes pipeline for plasmid 
                                  detection in metagenomics datasets. Default: 
                                  false

--spades_rnaviral               : This flag enables virus assembly module 
                                  from RNA-Seq data. Default: false

--spades_iontorrent             : This flag is required for IonTorrent data. 
                                  Default: false

--spades_only_assembler         : Runs only the SPAdes assembler module (
                                  without read error correction). Default: 
                                  false

--spades_careful                : Tries to reduce the number of mismatches 
                                  and short indels in the assembly. Default: 
                                  false

--spades_cov_cutoff             : Coverage cutoff value (a positive float 
                                  number). Default: false

--spades_k                      : List of k-mer sizes (must be odd and less 
                                  than 128). Default: false

--spades_hmm                    : Directory with custom hmms that replace the 
                                  default ones (very rare). Default: false

--serotypefinder_run            : Run SerotypeFinder tool. Default: true

--serotypefinder_x              : Generate extended output files. Default: 
                                  true

--serotypefinder_db             : Path to SerotypeFinder databases. Default: /
                                  hpc/db/serotypefinder/2.0.2

--serotypefinder_min_threshold  : Minimum percent identity (in float) 
                                  required for calling a hit. Default: 0.85

--serotypefinder_min_cov        : Minumum percent coverage (in float) 
                                  required for calling a hit. Default: 0.80

--seqsero2_run                  : Run SeqSero2 tool. Default: false

--seqsero2_t                    : '1' for interleaved paired-end reads, '2' 
                                  for separated paired-end reads, '3' for 
                                  single reads, '4' for genome assembly, '5' 
                                  for nanopore reads (fasta/fastq). Default: 
                                  4

--seqsero2_m                    : Which workflow to apply, 'a'(raw reads 
                                  allele micro-assembly), 'k'(raw reads and 
                                  genome assembly k-mer). Default: k

--seqsero2_c                    : SeqSero2 will only output serotype 
                                  prediction without the directory containing 
                                  log files. Default: false

--seqsero2_s                    : SeqSero2 will not output header in 
                                  SeqSero_result.tsv. Default: false

--mlst_run                      : Run MLST tool. Default: true

--mlst_minid                    : DNA %identity of full allelle to consider '
                                  similar' [~]. Default: 95

--mlst_mincov                   : DNA %cov to report partial allele at all [?].
                                  Default: 10

--mlst_minscore                 : Minumum score out of 100 to match a scheme.
                                  Default: 50

--abricate_run                  : Run ABRicate tool. Default: true

--abricate_minid                : Minimum DNA %identity. Defaut: 90

--abricate_mincov               : Minimum DNA %coverage. Defaut: 80

--abricate_datadir              : ABRicate databases folder. Defaut: /hpc/db/
                                  abricate/1.0.1/db

Help options                    : 

--help                          : Display this message.
```
