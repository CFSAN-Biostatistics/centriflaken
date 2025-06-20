process AMRFINDERPLUS_RUN {
    tag "$meta.id"
    label 'process_low'

    module (params.enable_module ? "${params.swmodulepath}${params.fs}amrfinderplus${params.fs}3.10.24" : null)
    conda (params.enable_conda ? "bioconda::ncbi-amrfinderplus=3.10.24 conda-forge::libgcc-ng" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ncbi-amrfinderplus%3A3.10.23--h17dc2d4_0':
        'quay.io/biocontainers/ncbi-amrfinderplus:3.10.23--h17dc2d4_0' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("${prefix}.tsv")          , emit: report
    tuple val(meta), path("${prefix}-mutations.tsv"), emit: mutation_report, optional: true
    path "versions.yml"                             , emit: versions

    when:
    (task.ext.when == null || task.ext.when) && fasta.size() > 0

    script:
    def args = task.ext.args ?: ''
    def is_compressed = fasta.getName().endsWith(".gz") ? true : false
    prefix = task.ext.prefix ?: "${meta.id}"
    organism_param = meta.containsKey("organism") ? "--organism ${meta.organism} --mutation_all ${prefix}-mutations.tsv" : ""
    fasta_name = fasta.getName().replace(".gz", "")
    fasta_param = "-n"
    if (meta.containsKey("is_proteins")) {
        if (meta.is_proteins) {
            fasta_param = "-p"
        }
    }
    """
    if [ "$is_compressed" == "true" ]; then
        gzip -c -d $fasta > $fasta_name
    fi

    amrfinder \\
        $fasta_param $fasta_name \\
        $organism_param \\
        $args \\
        --threads $task.cpus > ${prefix}.tsv


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        amrfinderplus: \$(amrfinder --version)
        gzip: \$( echo \$(gzip --version 2>&1) | sed 's/^.*(gzip) //; s/gzip //; s/ Copyright.*\$//' )
    END_VERSIONS
    """
}