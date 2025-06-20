process SEQTK_SEQ {
    tag "$meta.id"
    label 'process_mem_low'

    module (params.enable_module ? "${params.swmodulepath}${params.fs}seqtk${params.fs}1.3-r106" : null)
    conda (params.enable_conda ? "bioconda::seqtk=1.3 conda-forge::gzip" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqtk:1.3--h5bf99c6_3' :
        'quay.io/biocontainers/seqtk:1.3--h5bf99c6_3' }"

    input:
    tuple val(meta), path(fastx)

    output:
    tuple val(meta), path("*.gz"), emit: fastx
    path "versions.yml"          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    def extension = "fastq"
    if ("$fastx" ==~ /.+\.fasta|.+\.fasta.gz|.+\.fa|.+\.fa.gz|.+\.fas|.+\.fas.gz|.+\.fna|.+\.fna.gz/ || "$args" ==~ /\-[aA]/ ) {
        extension = "fasta"
    }
    """
    seqtk \\
        seq \\
        $args \\
        $fastx | \\
        gzip -c > ${prefix}.seqtk-seq.${task.index}.${extension}.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqtk: \$(echo \$(seqtk 2>&1) | sed 's/^.*Version: //; s/ .*\$//')
        gzip: \$( echo \$(gzip --version 2>&1) | sed 's/^.*(gzip) //; s/gzip //; s/ Copyright.*\$//' )
    END_VERSIONS
    """
}