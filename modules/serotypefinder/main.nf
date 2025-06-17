process SEROTYPEFINDER {
    tag "$meta.id"
    label 'process_low'

    module (params.enable_module ? "${params.swmodulepath}${params.fs}serotypefinder${params.fs}2.0.2" : null)
    conda (params.enable_conda ? "bioconda::serotypefinder=2.0.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/serotypefinder:2.0.1--py39hdfd78af_0' :
        'quay.io/biocontainers/serotypefinder:2.0.1--py39hdfd78af_0' }"

    input:
    tuple val(meta), path(fasta)

    output:
    path("${meta.id}${params.fs}*")
    tuple val(meta), path("${meta.id}${params.fs}${meta.id}.tsv"), emit: serotyped
    path "versions.yml"                                          , emit: versions

    when:
    (task.ext.when == null || task.ext.when) && fasta.size() > 0

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def is_compressed = fasta.getName().endsWith(".gz") ? true : false
    def fasta_name = fasta.getName().replace(".gz", "")
    def serotypefinder_db = "${meta.serotypefinder_db}"
    def serotypefinder_cmd = (params.enable_module ? "serotypefinder.py" : "serotypefinder")
    """
    if [ "$is_compressed" == "true" ]; then
        gzip -c -d $fasta > $fasta_name
    fi

    mkdir -p $prefix > /dev/null 2>&1

    $serotypefinder_cmd \\
        $args \\
        -p $serotypefinder_db \\
        -o $prefix \\
        -i $fasta_name

    head -n1 ${prefix}${params.fs}results_tab.tsv | sed -E "s/(.*)/Name\\t\\1/g" > ${prefix}${params.fs}${prefix}.tsv
    tail -n+2 ${prefix}${params.fs}results_tab.tsv | sed -E "s/(.*)/${prefix}\\t\\1/g" >> ${prefix}${params.fs}${prefix}.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        serotypefinder: 2.0.1/2.0.2
    END_VERSIONS

    sedver=""
    headver=""
    tailver=""

    if [ "${workflow.containerEngine}" != "null" ]; then
        sedver=\$( sed --help 2>&1 | sed -e '1!d; s/ (.*\$//' )
        headver=\$( head --help 2>&1 | sed -e '1!d; s/ (.*\$//' )
        tailver="\$headver"
    else
        sedver=\$( echo \$(sed --version 2>&1) | sed 's/^.*(GNU sed) //; s/ Copyright.*\$//' )
        headver=\$( head --version 2>&1 | sed '1!d; s/^.*(GNU coreutils//; s/) //;' )
        tailver=\$( tail --version 2>&1 | sed '1!d; s/^.*(GNU coreutils//; s/) //;' )
    fi

    cat <<-END_VERSIONS >> versions.yml
        sed: \$sedver
        head: \$headver
        tail: \$tailver
    END_VERSIONS
    """
}