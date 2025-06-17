process KRAKEN2_CLASSIFY {
    tag "$meta.id"
    label 'process_low'

    module (params.enable_module ? "${params.swmodulepath}${params.fs}kraken2${params.fs}2.1.2" : null)
    conda (params.enable_conda ? 'bioconda::kraken2=2.1.2 conda-forge::pigz=2.6' : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-5799ab18b5fc681e75923b2450abaa969907ec98:87fc08d11968d081f3e8a37131c1f1f6715b6542-0' :
        'quay.io/biocontainers/mulled-v2-5799ab18b5fc681e75923b2450abaa969907ec98:87fc08d11968d081f3e8a37131c1f1f6715b6542-0' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path('*classified*')  , emit: classified
    tuple val(meta), path('*unclassified*'), emit: unclassified
    tuple val(meta), path('*.report.txt')  , emit: kraken_report
    tuple val(meta), path('*.output.txt')  , emit: kraken_output
    path "versions.yml"                    , emit: versions

    when:
    (task.ext.when == null || task.ext.when) && (meta.is_assembly ? reads.size() : 1)

    script:
    def args = task.ext.args ?: ''
    def db = meta.kraken2_db ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def readList = reads.collect{ it.toString() }
    def is_single_end = (meta.single_end || meta.is_assembly) ? true : false
    def paired = is_single_end ? "" : "--paired"
    def classified = is_single_end ? "--classified-out ${prefix}.classified.fastq" : "--classified-out ${prefix}.classified#.fastq"
    def unclassified = is_single_end ? "--unclassified-out ${prefix}.unclassified.fastq" : "--unclassified-out ${prefix}.unclassified#.fastq"
    args += (reads.getName().endsWith(".gz") ? ' --gzip-compressed ' : '')
    """
    kraken2 \\
        --db $db \\
        --threads $task.cpus \\
        $unclassified \\
        $classified \\
        --report ${prefix}.kraken2.report.txt \\
        --output ${prefix}.kraken2.output.txt \\
        $paired \\
        $args \\
        $reads

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kraken2: \$(echo \$(kraken2 --version 2>&1) | sed 's/^.*Kraken version //; s/ .*\$//')
    END_VERSIONS

    zcmd=""
    zver=""

    if type pigz > /dev/null 2>&1; then
        pigz -p $task.cpus *.fastq
        zcmd="pigz"
        zver=\$( echo \$( \$zcmd --version 2>&1 ) | sed -e '1!d' | sed "s/\$zcmd //" )
    elif type gzip > /dev/null 2>&1; then
        gzip *.fastq
        zcmd="gzip"
    
        if [ "${workflow.containerEngine}" != "null" ]; then
            zver=\$( echo \$( \$zcmd --help 2>&1 ) | sed -e '1!d; s/ (.*\$//' )
        else
            zver=\$( echo \$( \$zcmd --version 2>&1 ) | sed "s/^.*(\$zcmd) //; s/\$zcmd //; s/ Copyright.*\$//" )
        fi
    fi

    cat <<-END_VERSIONS >> versions.yml
        \$zcmd: \$zver
    END_VERSIONS
    """
}