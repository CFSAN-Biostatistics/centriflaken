// Define any required imports for this specific workflow
import java.nio.file.Paths
import nextflow.file.FileHelper

// Include any necessary methods
include { \
    summaryOfParams; stopNow; fastqEntryPointHelp; sendMail; \
    addPadding; wrapUpHelp   } from "${params.routines}"
include { spadesHelp         } from "${params.toolshelp}${params.fs}spades"


// Exit if help requested before any subworkflows
if (params.help) {
    log.info help()
    exit 0
}

// Include any necessary modules and subworkflows
include { PROCESS_FASTQ           } from "${params.subworkflows}${params.fs}process_fastq"
include { SPADES_ASSEMBLE         } from "${params.modules}${params.fs}spades${params.fs}assemble${params.fs}main"
include { DUMP_SOFTWARE_VERSIONS  } from "${params.modules}${params.fs}custom${params.fs}dump_software_versions${params.fs}main"



/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    INPUTS AND ANY CHECKS FOR THE CENTRIFLAKEN-HY WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def spades_custom_hmm = (params.spades_hmm ? file ( "${params.spades_hmm}" ) : false)
def reads_platform = 0

reads_platform += (params.input ? 1 : 0)

if (spades_custom_hmm && !spades_custom_hmm.exists()) {
    stopNow("Please check if the following SPAdes' custom HMM directory\n" +
        "path is valid:\n${params.spades_hmm}\nCannot proceed further!")
}

if (reads_platform < 1 || reads_platform == 0) {
    stopNow("Please mention at least one absolute path to input folder which contains\n" +
            "FASTQ files sequenced using the --input option.\n" +
        "Ex: --input (Illumina or Generic short reads in FASTQ format)")
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN THE CENTRIFLAKEN-HY WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow SPADES_ONLY {
    main:
        ch_dummy = Channel.fromPath("${params.dummyfile}")
        ch_dummy2 = Channel.fromPath("${params.dummyfile2}")

        log.info summaryOfParams()

        PROCESS_FASTQ()
            .processed_reads
            .set { ch_processed_reads }

        PROCESS_FASTQ
            .out
            .versions
            .set { software_versions }

        // As of 06/02/2022, with the upcoming newer versions of NextFlow, we will be able to do
        // allowNull: true for both input and output, but until then, we have to use dummy files.
        // and work arounds.
        // https://github.com/nextflow-io/nextflow/pull/2893

        SPADES_ASSEMBLE (
            ch_processed_reads
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


        DUMP_SOFTWARE_VERSIONS (
            software_versions
                .unique()
                .collectFile(name: 'collected_versions.yml')
        )
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ON COMPLETE, SHOW GORY DETAILS OF ALL PARAMS WHICH WILL BE HELPFUL TO DEBUG
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (workflow.success) {
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
        spadesHelp(params).text +
        wrapUpHelp()
    )

    return addPadding(helptext)
}