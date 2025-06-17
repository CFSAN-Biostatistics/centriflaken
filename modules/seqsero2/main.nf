process SEQSERO2 {
    tag "$meta.id"
    label 'process_low'

    module (params.enable_module ? "${params.swmodulepath}${params.fs}seqsero2${params.fs}1.2.1" : null)
    conda (params.enable_conda ? "bioconda::seqsero2=1.2.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqsero2:1.2.1--py_0' :
        'quay.io/biocontainers/seqsero2:1.2.1--py_0' }"

    input:
    tuple val(meta), path(reads_or_asm)

    output:
    path("${meta.id}${params.fs}*")
    tuple val(meta), path("${meta.id}${params.fs}*_result.tsv"), emit: serotyped
    path "versions.yml"                                        , emit: versions

    when:
    (task.ext.when == null || task.ext.when) && reads_or_asm.size() > 0

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    SeqSero2_package.py \\
        $args \\
        -d $prefix \\
        -n $prefix \\
        -p $task.cpus \\
        -i $reads_or_asm

    mv ${prefix}${params.fs}SeqSero_log.txt ${prefix}${params.fs}${prefix}.SeqSero_log.txt
    mv ${prefix}${params.fs}SeqSero_result.txt ${prefix}${params.fs}${prefix}.SeqSero_result.txt
    mv ${prefix}${params.fs}SeqSero_result.tsv ${prefix}${params.fs}${prefix}.SeqSero_result.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqsero2: \$( echo \$( SeqSero2_package.py --version 2>&1) | sed 's/^.*SeqSero2_package.py //' )
    END_VERSIONS
    """
}