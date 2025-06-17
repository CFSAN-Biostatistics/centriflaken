// Define any required imports for this specific workflow
import java.nio.file.Paths
import nextflow.file.FileHelper

// Include any necessary methods
include { \
    summaryOfParams; stopNow; fastqEntryPointHelp; sendMail; \
    addPadding; wrapUpHelp   } from "${params.routines}"
include { seqkitrmdupHelp    } from "${params.toolshelp}${params.fs}seqkitrmdup"
include { kraken2Help        } from "${params.toolshelp}${params.fs}kraken2"
include { centrifugeHelp     } from "${params.toolshelp}${params.fs}centrifuge"
include { megahitHelp        } from "${params.toolshelp}${params.fs}megahit"
include { spadesHelp         } from "${params.toolshelp}${params.fs}spades"
include { serotypefinderHelp } from "${params.toolshelp}${params.fs}serotypefinder"
include { seqsero2Help       } from "${params.toolshelp}${params.fs}seqsero2"
include { mlstHelp           } from "${params.toolshelp}${params.fs}mlst"
include { abricateHelp       } from "${params.toolshelp}${params.fs}abricate"

// Exit if help requested before any subworkflows
if (params.help) {
    log.info help()
    exit 0
}

// Include any necessary modules and subworkflows
include { PROCESS_FASTQ           } from "${params.subworkflows}${params.fs}process_fastq"
include { FASTQC                  } from "${params.modules}${params.fs}fastqc${params.fs}main"
include { SEQKIT_RMDUP            } from "${params.modules}${params.fs}seqkit${params.fs}rmdup${params.fs}main"
include { CENTRIFUGE_CLASSIFY     } from "${params.modules}${params.fs}centrifuge${params.fs}classify${params.fs}main"
include { CENTRIFUGE_PROCESS      } from "${params.modules}${params.fs}centrifuge${params.fs}process${params.fs}main"
include { SEQKIT_GREP             } from "${params.modules}${params.fs}seqkit${params.fs}grep${params.fs}main"
include { MEGAHIT_ASSEMBLE        } from "${params.modules}${params.fs}megahit${params.fs}assemble${params.fs}main"
include { SPADES_ASSEMBLE         } from "${params.modules}${params.fs}spades${params.fs}assemble${params.fs}main"
include { KRAKEN2_CLASSIFY        } from "${params.modules}${params.fs}kraken2${params.fs}classify${params.fs}main"
include { KRAKEN2_EXTRACT_CONTIGS } from "${params.modules}${params.fs}kraken2${params.fs}extract_contigs${params.fs}main"
include { SEROTYPEFINDER          } from "${params.modules}${params.fs}serotypefinder${params.fs}main"
include { SEQSERO2                } from "${params.modules}${params.fs}seqsero2${params.fs}main"
include { MLST                    } from "${params.modules}${params.fs}mlst${params.fs}main"
include { ABRICATE_RUN            } from "${params.modules}${params.fs}abricate${params.fs}run${params.fs}main"
include { ABRICATE_SUMMARY        } from "${params.modules}${params.fs}abricate${params.fs}summary${params.fs}main"
include { TABLE_SUMMARY           } from "${params.modules}${params.fs}cat${params.fs}tables${params.fs}main"
include { MULTIQC                 } from "${params.modules}${params.fs}multiqc${params.fs}main"
include { DUMP_SOFTWARE_VERSIONS  } from "${params.modules}${params.fs}custom${params.fs}dump_software_versions${params.fs}main"



/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    INPUTS AND ANY CHECKS FOR THE CENTRIFLAKEN-HY WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def kraken2_db_dir = file ( "${params.kraken2_db}" )
def centrifuge_x = file ( "${params.centrifuge_x}" )
def spades_custom_hmm = (params.spades_hmm ? file ( "${params.spades_hmm}" ) : false)
def reads_platform = 0
def abricate_dbs = [ 'ncbiamrplus', 'resfinder', 'megares', 'argannot' ]

reads_platform += (params.input ? 1 : 0)

if (!kraken2_db_dir.exists() || !centrifuge_x.getParent().exists()) {
    stopNow("Please check if the following absolute paths are valid:\n" +
        "${params.kraken2_db}\n${params.centrifuge_x}\n" +
        "Cannot proceed further!")
}

if (spades_custom_hmm && !spades_custom_hmm.exists()) {
    stopNow("Please check if the following SPAdes' custom HMM directory\n" +
        "path is valid:\n${params.spades_hmm}\nCannot proceed further!")
}

if (reads_platform < 1 || reads_platform == 0) {
    stopNow("Please mention at least one absolute path to input folder which contains\n" +
            "FASTQ files sequenced using the --input option.\n" +
        "Ex: --input (Illumina or Generic short reads in FASTQ format)")
}

if (params.centrifuge_extract_bug != params.kraken2_extract_bug) {
    stopNow("Please make sure that the bug to be extracted is same\n" +
    "for both --centrifuge_extract_bug and --kraken2_extract_bug options.")
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN THE CENTRIFLAKEN-HY WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow CENTRIFLAKEN_HY {
    main:
        ch_asm_filtered_contigs = Channel.empty()
        ch_mqc_custom_tbl = Channel.empty()
        ch_dummy = Channel.fromPath("${params.dummyfile}")
        ch_dummy2 = Channel.fromPath("${params.dummyfile2}")

        log.info summaryOfParams()

        PROCESS_FASTQ()
            .processed_reads
            .map {
                meta, fastq ->
                meta.centrifuge_x = params.centrifuge_x
                meta.kraken2_db = params.kraken2_db
                [meta, fastq]
            }
            .set { ch_processed_reads }

        PROCESS_FASTQ
            .out
            .versions
            .set { software_versions }

        FASTQC ( ch_processed_reads )

        if (params.seqkit_rmdup_run) {
            SEQKIT_RMDUP ( ch_processed_reads )

            SEQKIT_RMDUP
                .out
                .fastx
                .set { ch_processed_reads }

            software_versions
                .mix ( SEQKIT_RMDUP.out.versions.ifEmpty(null) )
                .set { software_versions }
        }

        CENTRIFUGE_CLASSIFY ( ch_processed_reads )

        CENTRIFUGE_PROCESS (
            CENTRIFUGE_CLASSIFY.out.report
                .join( CENTRIFUGE_CLASSIFY.out.output )
        )

        ch_processed_reads.join ( CENTRIFUGE_PROCESS.out.extracted )
            .set { ch_centrifuge_extracted }

        SEQKIT_GREP ( ch_centrifuge_extracted )

        // As of 06/02/2022, with the upcoming newer versions of NextFlow, we will be able to do
        // allowNull: true for both input and output, but until then, we have to use dummy files.
        // and work arounds.
        // https://github.com/nextflow-io/nextflow/pull/2893
        if (params.spades_run) {
            SPADES_ASSEMBLE (
                SEQKIT_GREP.out.fastx
                    .combine(ch_dummy)
                    .combine(ch_dummy2)
            )

            SPADES_ASSEMBLE
                .out
                .assembly
                .set { ch_assembly }

            software_versions
                .mix ( SPADES_ASSEMBLE.out.versions.ifEmpty(null) )
                .set { software_versions }
        } else if (params.megahit_run) {
            MEGAHIT_ASSEMBLE (
                SEQKIT_GREP.out.fastx
            )

            MEGAHIT_ASSEMBLE
                .out
                .assembly
                .set { ch_assembly }

            software_versions
                .mix ( MEGAHIT_ASSEMBLE.out.versions.ifEmpty(null) )
                .set { software_versions }
        }

        ch_assembly
            .map {
                meta, fastq ->
                meta.is_assembly = true
                [meta, fastq]
            }
            .set { ch_assembly }

        ch_assembly.ifEmpty { [ false, false ] }

        KRAKEN2_CLASSIFY ( ch_assembly )

        KRAKEN2_EXTRACT_CONTIGS (
            ch_assembly
                .join( KRAKEN2_CLASSIFY.out.kraken_output ),
            params.kraken2_extract_bug
        )

        KRAKEN2_EXTRACT_CONTIGS
            .out
            .asm_filtered_contigs
            .map {
                meta, fastq ->
                meta.organism = params.kraken2_extract_bug.split(/\s+/)[0].capitalize()
                meta.serotypefinder_db = params.serotypefinder_db
                [meta, fastq]
            }
            .set { ch_asm_filtered_contigs }

        SEROTYPEFINDER ( ch_asm_filtered_contigs )

        SEQSERO2 ( ch_asm_filtered_contigs )

        MLST ( ch_asm_filtered_contigs )

        ABRICATE_RUN ( 
            ch_asm_filtered_contigs, 
            abricate_dbs
        )

        ABRICATE_RUN
            .out
            .abricated
            .map { meta, abres -> [ abricate_dbs, abres ] }
            .groupTuple(by: [0])
            .map { it -> tuple ( it[0], it[1].flatten() ) }
            .set { ch_abricated }

        ABRICATE_SUMMARY ( ch_abricated )

        CENTRIFUGE_CLASSIFY.out.kreport
            .map { meta, kreport -> [ kreport ] }
            .flatten()
            .concat ( 
                KRAKEN2_CLASSIFY.out.kraken_report
                .map { meta, kreport -> [ kreport ] }
                .flatten(),
                FASTQC.out.zip
                .map { meta, zip -> [ zip ] }
                .flatten()
            )
            .set { ch_mqc_classify }

        if (params.serotypefinder_run) {
            SEROTYPEFINDER
                .out
                .serotyped
                .map { meta, tsv -> [ 'serotypefinder', tsv ] }
                .groupTuple(by: [0])
                .map { it -> tuple ( it[0], it[1].flatten() ) }
                .set { ch_mqc_custom_tbl }
        } else if (params.seqsero2_run) {
            SEQSERO2
                .out
                .serotyped
                .map { meta, tsv -> [ 'seqsero2', tsv ] }
                .groupTuple(by: [0])
                .map { it -> tuple ( it[0], it[1].flatten() ) }
                .set { ch_mqc_custom_tbl }
        }

        ch_mqc_custom_tbl
            .concat (
                ABRICATE_SUMMARY.out.ncbiamrplus.map{ it -> tuple ( it[0], it[1] )},
                ABRICATE_SUMMARY.out.resfinder.map{ it -> tuple ( it[0], it[1] )},
                ABRICATE_SUMMARY.out.megares.map{ it -> tuple ( it[0], it[1] )},
                ABRICATE_SUMMARY.out.argannot.map{ it -> tuple ( it[0], it[1] )},
            )
            .groupTuple(by: [0])
            .map { it -> [ it[0], it[1].flatten() ]}
            .set { ch_mqc_custom_tbl }

        TABLE_SUMMARY ( ch_mqc_custom_tbl )

        DUMP_SOFTWARE_VERSIONS (
            software_versions
                .mix (
                    FASTQC.out.versions,
                    CENTRIFUGE_CLASSIFY.out.versions,
                    CENTRIFUGE_PROCESS.out.versions,
                    SEQKIT_GREP.out.versions,
                    KRAKEN2_CLASSIFY.out.versions.ifEmpty(null),
                    KRAKEN2_EXTRACT_CONTIGS.out.versions.ifEmpty(null),
                    SEROTYPEFINDER.out.versions.ifEmpty(null),
                    SEQSERO2.out.versions.ifEmpty(null),
                    MLST.out.versions.ifEmpty(null),
                    ABRICATE_RUN.out.versions.ifEmpty(null),
                    ABRICATE_SUMMARY.out.versions.ifEmpty(null),
                    TABLE_SUMMARY.out.versions.ifEmpty(null)
                )
                .unique()
                .collectFile(name: 'collected_versions.yml')
        )

        DUMP_SOFTWARE_VERSIONS
            .out
            .mqc_yml
            .concat (
                ch_mqc_classify,
                TABLE_SUMMARY.out.mqc_yml
            )
            .collect()
            .set { ch_multiqc }

        MULTIQC ( ch_multiqc )
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ON COMPLETE, SHOW GORY DETAILS OF ALL PARAMS WHICH WILL BE HELPFUL TO DEBUG
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (workflow.success) {
        // CREATE APPROPRIATE DIRECTORIES AND MOVE AS REQUESTED BY STAKEHOLDER(S)
        //
        // Nextflow's .moveTo will error out if directories contain files and it
        // would be complex to include logic to skip directories 
        //
        def final_intermediate_dir = "${params.output}${params.fs}${params.pipeline}-steps"
        def final_results_dir = "${params.output}${params.fs}${params.pipeline}-results"
        def kraken2_ext_contigs =  file( "${final_intermediate_dir}${params.fs}kraken2_extract_contigs", type: 'dir' )
        def final_intermediate = file( final_intermediate_dir, type: 'dir' )
        def final_results = file( final_results_dir, type: 'dir' )
        def pipeline_output = file( params.output, type: 'dir' )

        if ( !final_intermediate.exists() ) {
            final_intermediate.mkdirs()

            FileHelper.visitFiles(Paths.get("${params.output}"), '*') {
                if ( !(it.name ==~ /^(${params.cfsanpipename}|multiqc|\.nextflow|${workflow.workDir.name}|${params.pipeline}).*/) ) {
                    FileHelper.movePath(
                        it, Paths.get( "${final_intermediate_dir}${params.fs}${it.name}" )
                    )
                }
            }
        }

        if ( kraken2_ext_contigs.exists() && !final_results.exists() ) {
            final_results.mkdirs()

            FileHelper.movePath(
                Paths.get( "${final_intermediate_dir}${params.fs}kraken2_extract_contigs" ),
                Paths.get( "${final_results_dir}${params.fs}kraken2_extract_contigs" )
            )
        }

        sendMail()
    }
}

workflow.onError {
    sendMail()
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    HELPER METHODS FOR CENTRIFLAKEN-HY WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def help() {

    Map helptext = [:]

    helptext.putAll (
        fastqEntryPointHelp() +
        seqkitrmdupHelp(params).text +
        kraken2Help(params).text +
        centrifugeHelp(params).text +
        megahitHelp(params).text +
        spadesHelp(params).text +
        serotypefinderHelp(params).text +
        seqsero2Help(params).text +
        mlstHelp(params).text +
        abricateHelp(params).text +
        wrapUpHelp()
    )

    return addPadding(helptext)
}