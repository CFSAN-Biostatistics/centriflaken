process CENTRIFUGE_EXTRACT {
    tag "$meta.id"
    label 'process_low'

    //seqkit container contains required bash and other utilities
    module (params.enable_module ? "${params.swmodulepath}${params.fs}python${params.fs}3.8.1" : null)
    conda (params.enable_conda ? "conda-forge::sed=4.7 conda-forge::coreutils" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-039542721b6b463b663872ba8b7e9fbc05f01925:1de88053ebf8fb9884758395c4871f642c57750c-0':
        'quay.io/biocontainers/mulled-v2-039542721b6b463b663872ba8b7e9fbc05f01925:1de88053ebf8fb9884758395c4871f642c57750c-0' }"

    input:
    tuple val(meta), path(centrifuge_report)
    tuple val(meta), path(centrifuge_output)

    output:
    tuple val(meta), path('*.extract-centrifuge-bug-ids.txt'), emit: extracted
    path "versions.yml"                                      , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    grep -F '${params.centrifuge_extract_bug}' $centrifuge_report \
        | cut -f2 \
        | sort -u \
        | while read -r taxId; do
            echo -e "\t\$taxId"'\$'
        done > gotcha.txt

    cut -f1-3 $centrifuge_output | grep -E -f gotcha.txt | cut -f1 | sort -u > ${prefix}.extract-centrifuge-bug-ids.txt || true

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$( bash --version 2>&1 | sed '1!d; s/^.*version //; s/ (.*\$//' )
    END_VERSIONS

    ver=""
    sedver=""

    if [ "${workflow.containerEngine}" != "null" ]; then
        ver=\$( cut --help 2>&1 | sed -e '1!d; s/ (.*\$//' )
        sedver="\$ver"
    else
        ver=\$( cut --version 2>&1 | sed '1!d; s/^.*(GNU coreutils//; s/) //;' )
        sedver=\$( echo \$(sed --version 2>&1) | sed 's/^.*(GNU sed) //; s/ Copyright.*\$//' )
    fi

    cat <<-END_VERSIONS >> versions.yml
        cut: \$ver
        tail: \$ver
        sort: \$ver
        sed: \$sedver
    END_VERSIONS
    """
}