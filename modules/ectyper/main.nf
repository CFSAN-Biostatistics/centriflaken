process ECTYPER {
    tag "$meta.id"
    label 'process_low'

    module (params.enable_module ? "${params.swmodulepath}${params.fs}ectyper${params.fs}1.0.0" : null)
    conda (params.enable_conda ? "bioconda::ectyper=1.0.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ectyper:1.0.0--pyhdfd78af_1' :
        'quay.io/biocontainers/ectyper:1.0.0--pyhdfd78af_1' }"

    input:
    tuple val(meta), path(fasta)

    output:
    path("${meta.id}${params.fs}*")
    tuple val(meta), path("${meta.id}${params.fs}${meta.id}.tsv"), emit: ectyped
    path "versions.yml"                                          , emit: versions

    when:
    task.ext.when == null || task.ext.when || fasta.size() > 0

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def is_compressed = fasta.getName().endsWith(".gz") ? true : false
    def fasta_name = fasta.getName().replace(".gz", "")
    """
    if [ "$is_compressed" == "true" ]; then
        gzip -c -d $fasta > $fasta_name
    fi

    ectyper \\
        $args \\
        --cores $task.cpus \\
        --output $prefix \\
        --input $fasta_name

    mv ${prefix}${params.fs}output.tsv ${prefix}${params.fs}${prefix}.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ectyper: \$(echo \$(ectyper --version 2>&1)  | sed 's/.*ectyper //; s/ .*\$//')
    END_VERSIONS
    """
}