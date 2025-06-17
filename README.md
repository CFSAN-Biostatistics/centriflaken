# `centriflaken`

`centriflaken` is an automated precision metagenomics workflow for assembly and _in silico_ analyses of food-borne pathogens. `centriflaken` primarily fine-tuned for detecting and classifying Shiga toxin-producing **_Escherichia coli_** (**STEC**) can also be used for performing analyses on other food-borne pathogens such as **_Salmonella enterica_**.  `centriflaken` takes as input a UNIX path to FASTQ, generates MAGs, and performs in silico-based analysis for STECs as described in [Maguire et al. 2021](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0245172).

`centriflaken` works on both **Illumina** short reads and **Oxford Nanopore** long reads.

It is written in **Nextflow** and is part of the modular data analysis pipelines at **HFP**.

\
&nbsp;

## Workflows

**CPIPES**:

- `centriflaken`       : [README](./readme/centriflaken.md).
- `centriflaken_hy`    : [README](./readme/centriflaken.md#illumina-short-reads).

\
&nbsp;

### Citing `centriflaken`

---
Manuscript in preparation [Frontiers in Microbiology](https://www.frontiersin.org/articles/10.3389/fmicb.2023.1200983/full).

>
>**centriflaken: an automated data analysis pipeline for assembly and in silico analyses of food-borne pathogens from metagenomic samples.**
>
>Kranti Konganti, Julie Kase, and Narjol Gonzalez-Escalona.
>

\
&nbsp;

### Future work

---

- Incorporation of ANI methods to speed up the analysis methods.
- Incorporation of Oxford Nanopore models for barcode level assembly.

\
&nbsp;

### Caveats

---

- The main workflow has been used for **research purposes** only.
- Analysis results should be interpreted with caution.

\
&nbsp;

### Disclaimer

---
**HFP, FDA** assumes no responsibility whatsoever for use by other parties of the Software, its source code, documentation or compiled or uncompiled executables, and makes no guarantees, expressed or implied, about its quality, reliability, or any other characteristic. Further, **HFP, FDA** makes no representations that the use of the Software will not infringe any patent or proprietary rights of third parties. The use of this code in no way implies endorsement by the **HFP, FDA** or confers any advantage in regulatory decisions.
