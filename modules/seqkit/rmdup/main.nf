process SEQKIT_RMDUP {
    tag "$meta.id"
    label 'process_low'

    module (params.enable_module ? "${params.swmodulepath}${params.fs}seqkit${params.fs}2.2.0" : null)
    conda (params.enable_conda ? "bioconda::seqkit=2.2.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqkit:2.1.0--h9ee0642_0':
        'quay.io/biocontainers/seqkit:2.1.0--h9ee0642_0' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*duplicated.details.txt"), optional: true
    tuple val(meta), path("*.gz")                   , emit: fastx
    path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def rmdup_d = params.seqkit_rmdup_d ? "-d ${prefix}.seqs.duplicated.fastq.gz" : ""
    def rmdup_D = params.seqkit_rmdup_D ? "-D ${prefix}.duplicated.details.txt" : ""

    def extension = "fastq"
    if ("$reads" ==~ /.+\.fasta|.+\.fasta.gz|.+\.fa|.+\.fa.gz|.+\.fas|.+\.fas.gz|.+\.fna|.+\.fna.gz/) {
        extension = "fasta"
    }

    if (meta.single_end) {
        """
        seqkit \\
            rmdup \\
            $rmdup_d \\
            $rmdup_D \\
            -j $task.cpus \\
            -o ${prefix}.seqkit-rmdup.${extension}.gz \\
            $args \\
            $reads

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            seqkit: \$( seqkit | sed '3!d; s/Version: //' )
        END_VERSIONS
        """
    } else {
        """
        seqkit \\
            rmdup \\
            $rmdup_d \\
            $rmdup_D \\
            -j $task.cpus \\
            -o ${prefix}.R1.seqkit-rmdup.${extension}.gz \\
            $args \\
            ${reads[0]}

        seqkit \\
            rmdup \\
            $rmdup_d \\
            $rmdup_D \\
            -j $task.cpus \\
            -o ${prefix}.R2.seqkit-rmdup.${extension}.gz \\
            $args \\
            ${reads[1]}

        seqkit \\
            pair \\
            -j $task.cpus \\
            -1 ${prefix}.R1.seqkit-rmdup.${extension}.gz \\
            -2 ${prefix}.R2.seqkit-rmdup.${extension}.gz

        rm ${prefix}.R1.seqkit-rmdup.${extension}.gz
        rm ${prefix}.R2.seqkit-rmdup.${extension}.gz

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            seqkit: \$( seqkit | sed '3!d; s/Version: //' )
        END_VERSIONS
        """
    }
}
