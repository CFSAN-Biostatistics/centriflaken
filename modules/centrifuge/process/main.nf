process CENTRIFUGE_PROCESS {
    tag "$meta.id"
    label 'process_low'

    module (params.enable_module ? "${params.swmodulepath}${params.fs}python${params.fs}3.8.1" : null)
    conda (params.enable_conda ? "conda-forge::python=3.9 conda-forge::pandas conda-forge::biopython" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-d91be2208450c41a5198d8660b6d9a5b60613b3a:d9847b41af5ef58746c86d7114cd010650f3d9a2-0' :
        'quay.io/biocontainers/mulled-v2-d91be2208450c41a5198d8660b6d9a5b60613b3a:d9847b41af5ef58746c86d7114cd010650f3d9a2-0' }"

    input:
    tuple val(meta), path(centrifuge_report), path(centrifuge_output)

    output:
    tuple val(meta), path('*.process-centrifuge-bug-ids.txt'), emit: extracted
    path "versions.yml"                                      , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    process_centrifuge_output.py \\
        -r $centrifuge_report \\
        -o $centrifuge_output \\
        -b '${params.centrifuge_extract_bug}' \\
        -t ${prefix}.process-centrifuge-bug-ids.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$( python --version | sed 's/Python //g' )
        biopython: \$( python -c 'import Bio as bio; print(bio.__version__)' )
        numpy: \$( python -c 'import numpy as np; print(np.__version__)' )
        pandas: \$( python -c 'import pandas as pd; print(pd.__version__)' )
    END_VERSIONS
    """
}