process CENTRIFUGE_CLASSIFY {
    tag "$meta.id"
    label 'process_medium'

    module (params.enable_module ? 'centrifuge' : null)
    conda (params.enable_conda ? "bioconda::centrifuge=1.0.4_beta" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/centrifuge:1.0.4_beta--h9a82719_6' :
        'quay.io/biocontainers/centrifuge:1.0.4_beta--h9a82719_6' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path('*.report.txt')                 , emit: report
    tuple val(meta), path('*.output.txt')                 , emit: output
    tuple val(meta), path('*.kreport.txt')                , emit: kreport
    tuple val(meta), path('*.sam')                        , optional: true, emit: sam
    tuple val(meta), path('*.mapped.fastq{,.1,.2}.gz')    , optional: true, emit: fastq_mapped
    tuple val(meta), path('*.unmapped.fastq{,.1,.2}.gz')  , optional: true, emit: fastq_unmapped
    path "versions.yml"                                   , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def paired = meta.single_end ? "-U ${reads}" :  "-1 ${reads[0]} -2 ${reads[1]}"
    def db = meta.centrifuge_x ?: ''
    def db_name = db.toString().replace(".tar.gz","")
    def unaligned = ''
    def aligned = ''
    if (meta.single_end) {
        unaligned = params.centrifuge_save_unaligned ? "--un-gz ${prefix}.unmapped.fastq.gz" : ''
        aligned = params.centrifuge_save_aligned ? "--al-gz ${prefix}.mapped.fastq.gz" : ''
    } else {
        unaligned = params.centrifuge_save_unaligned ? "--un-conc-gz ${prefix}.unmapped.fastq.gz" : ''
        aligned = params.centrifuge_save_aligned ? "--al-conc-gz ${prefix}.mapped.fastq.gz" : ''
    }
    def sam_output = params.centrifuge_out_fmt_sam ? "--out-fmt 'sam'" : ''
    """
    centrifuge \\
        -x $db \\
        -p $task.cpus \\
        $paired \\
        --report-file ${prefix}.centrifuge.report.txt \\
        -S ${prefix}.centrifuge.output.txt \\
        $unaligned \\
        $aligned \\
        $sam_output \\
        $args

    centrifuge-kreport -x $db_name ${prefix}.centrifuge.output.txt > ${prefix}.centrifuge.kreport.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        centrifuge: \$( centrifuge --version  | sed -n 1p | sed 's/^.*centrifuge-class version //')
    END_VERSIONS
    """
}