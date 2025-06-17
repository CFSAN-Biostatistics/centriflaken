process KRAKEN2_EXTRACT_CONTIGS {
    tag "$meta.id"
    label 'process_nano'

    module (params.enable_module ? "${params.swmodulepath}${params.fs}python${params.fs}3.8.1" : null)
    conda (params.enable_conda ? "conda-forge::python=3.9 conda-forge::pandas conda-forge::biopython" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-d91be2208450c41a5198d8660b6d9a5b60613b3a:d9847b41af5ef58746c86d7114cd010650f3d9a2-0' :
        'quay.io/biocontainers/mulled-v2-d91be2208450c41a5198d8660b6d9a5b60613b3a:d9847b41af5ef58746c86d7114cd010650f3d9a2-0' }"

    input:
    tuple val(meta), path(assembly), path(kraken2_output)
    val kraken2_extract_bug

    output:
    tuple val(meta), path('*assembly_filtered_contigs.fasta'), emit: asm_filtered_contigs
    path "versions.yml"                                      , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    extract_assembled_filtered_contigs.py \\
        -i $assembly \\
        -o ${prefix}.assembly_filtered_contigs.fasta \\
        -k $kraken2_output \\
        -b '$kraken2_extract_bug'

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$( python --version | sed 's/Python //g' )
        biopython: \$( python -c 'import Bio as bio; print(bio.__version__)' )
        numpy: \$( python -c 'import numpy as np; print(np.__version__)' )
        pandas: \$( python -c 'import pandas as pd; print(pd.__version__)' )
    END_VERSIONS
    """
}