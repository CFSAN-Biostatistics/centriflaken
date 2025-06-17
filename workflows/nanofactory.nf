//
// Start nanofactory workflow. Since this is a special
// case workflow wherein most of the bioinformatics
// tools are not used, there won't be any modules or
// subworkflows and therefore all the processes 
// reside here.
//

// Include any necessary methods.
include { addPadding; summaryOfParams; stopNow} \
    from "${params.routines}"

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PROCESS DEFINITIONS FOR NANOFACTORY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process SETPUBLISHDIR {
    label 'process_femto'
    module (params.enable_module ? params.enable_module : null)
    conda  (params.enable_conda ? params.enable_conda : null)

    input:
        val options

    output:
        stdout

    shell:
        '''
        project_setup.py -s !{options.sample_sheet} \
            !{options.alt_settings} !{options.verbose} -b
        '''
}

process PROJECTSETUP {
    label 'process_femto'
    publishDir "${publish_dir.trim()}", mode: 'copy', overwrite: false
    module (params.enable_module ? params.enable_module : null)
    conda  (params.enable_conda ? params.enable_conda : null)

    input:
        val options
        val publish_dir
    
    output:
        stdout

    script:
        params.publish_dir = "${publish_dir.trim()}"

    shell:
        '''
        project_setup.py -y -s !{options.sample_sheet} !{options.alt_settings} \
            !{options.purge} !{options.runtype} !{options.logfile} \
            !{options.loglevel} !{options.verbose} !{options.nocopy} \
            !{options.fix_existing}

        cat < original_source.txt
        '''
}

process TRIMDEMUX {
    label 'process_pico'
    module (params.enable_module ? params.enable_module : null)
    conda  (params.enable_conda ? params.enable_conda : null)
    cpus "${params.guppy_threads}"

    input:
        val options
        val original_source

    output:
        path 'source.txt'

    shell:
        '''
        trim_demux.py -s !{options.sample_sheet} !{options.verbose} \
            !{options.alt_settings} !{options.guppy_config} -t !{options.guppy_threads}
        '''
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    WORKFLOW ENTRY POINT
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow NANOFACTORY {

    if ( params.help ) {
        log.info help()
    } else if ( params.sample_sheet == null ||
        params.sample_sheet.length() == 0 ) {
        
        log.info help()
        stopNow("Please provide absolute path to a JSON formatted sample sheet using the\n" + 
            "--sample_sheet option.")
    } else {
        log.info summaryOfParams()

        options = Channel.empty()
        Channel
            .from(setOptions())
            .set { options }

        take:
            options

        main:
            SETPUBLISHDIR(options)
            PROJECTSETUP(options, SETPUBLISHDIR.out)
            TRIMDEMUX(options, PROJECTSETUP.out)
    }
}


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    HELPER METHODS FOR NANOFACTORY WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def setOptions() {

    Map options = [:]

    options['sample_sheet'] ?= "${params.sample_sheet}"
    options['verbose'] = params.verbose ? "-v" : ""
    options['alt_settings'] = params.global_settings ? "-c ${params.global_settings}" : ""
    options['purge'] = params.setup_purge_existing ? "-p" : ""
    options['logfile'] = params.log_file ? "-l ${params.log_file}" : ""
    options['loglevel'] = params.log_level ? "--loglevel ${params.log_level}" : ""
    options['nocopy'] = params.setup_nocopy ? "--nocopy" : ""
    options['runtype'] = params.setup_runtype ? "-r ${params.setup_runtype}" : ""
    options['fix_existing'] = params.setup_fix_existing ? "-f" : ""
    options['guppy_config'] = params.guppy_config ? " -g ${params.guppy_config}" : ""
    options['mode'] = params.mode ? "-m ${params.mode}" : "-m prod"
    options['mail_group'] = params.mail_group ? "-g ${params.mail_group}" : "-g stakeholders"
    options['guppy_threads'] = params.guppy_threads ? "${params.guppy_threads}" : 1
    options['pad'] = pad.toInteger()
    options['nocapitalize'] = true
    
    return options
}

def help() {

    Map helptext = [:]

    helptext['help'] = true
    helptext['nocapitalize'] = true
    helptext['Workflow'] =  "${params.pipeline}"
    helptext['Author'] = "${params.workflow_author}"
    helptext['Version'] = "${params.workflow_version}\n"
    helptext['Usage'] = "cpipes --pipeline nanofactory [options]\n"
    helptext['Required'] = ""
    helptext['--sample_sheet'] = "The JSON-formatted sample sheet for this run. Normally provided by Pore Refiner.\n"
    helptext['Other options'] = ""
    helptext['--global_settings'] = "An alternate global settings file.  If not present the installed default will be used."
    helptext['--log_file'] = "Path and file name to a log file relative to the project directory (Default: 'logs/workflow.log')"
    helptext['--log_level'] = "One of 'debug', 'info', 'warning', 'error', 'fatal' (Default: 'info')"
    helptext['--mode'] = "Set the run mode.  One of 'dev', 'test', 'stage', or 'prod' (Default: 'prod')"
    helptext['--verbose'] = "Use to enable more verbose console output from each tool\n"
    helptext['Project setup options'] = ""
    helptext['--disable_project_setup'] = "Do not do project setup (Default:  setup is enabled)"
    helptext['--setup_purge_existing'] = "Before setting up the project area delete any existing files (Default: don't purge)"
    helptext['--setup_nocopy'] = "During setup, do NOT copy the original data files to the scrach location (Default: copy)"
    helptext['--setup_runtype'] = "Set things up for the indicated run type (Currently not used)"
    helptext['--setup_runtype'] = "Set things up for the indicated run type (Currently not used)"
    helptext['--enable_module'] = "Software environment module. Ex: --enable_module 'nanofactory/current'"
    helptext['--enable_conda'] = "CONDA environment module. Ex: --enable_conda nanofactory\n"
    helptext['Help options'] = ""
    helptext['--help'] = "Display this message.\n"

    return addPadding(helptext)
}
