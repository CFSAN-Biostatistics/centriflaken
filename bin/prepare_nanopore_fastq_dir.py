#!/usr/bin/env python3

import os
import re
import glob
import argparse
import logging

def main():
    # READ IN ARGUMENTS
    desc = """
    Takes in a file with flowcell ID, one per line and creates soft links
    to 'fastq_pass' directory at target location.

    Ex:

    prepare_nanopore_fastq_dir.py \
        -o /hpc/scratch/Kranti.Konganti/np_test \
        -f flowcells.txt

    where flowcells.txt contains the following lines:

    FAL11127
    FAL11151

    """
    parser = argparse.ArgumentParser(prog='prepare_nanopore_fastq_dir.py',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        description=desc)
    required = parser.add_argument_group('required arguments')
    
    required.add_argument("-f", dest='flowcells', required=True,
        help="Path to a text file containing Nanopore flowcell IDs, one per line")
    required.add_argument("-i", dest='inputdir',
        required=False, action='append', nargs='*',
        help="Path to search directory. This directory location is where" +
            " the presence of 'fastq_pass' will be searched for each flowcell.")
    required.add_argument("-o", dest='outputdir',
        required=True,
        help="Path to output directory. This directory is created by the script" +
            " and new soft links (symlinks) are created in this directory.")
    
    args = parser.parse_args()
    flowcells = args.flowcells
    output = args.outputdir
    inputs = args.inputdir

    logging.basicConfig(format='%(asctime)s - %(levelname)s => %(message)s', level=logging.DEBUG)

    if not inputs:
        inputs = ['/projects/nanopore/raw']
        nanopore_machines = ['RazorCrest', 'Revolution', 'ObiWan', 'MinIT',
            'Mayhem', 'CaptainMarvel', 'MinION', 'MinION_Padmini', 'RogueOne']
        logging.info(f"Searching default path(s). Use -i option if custom path should be searched.")
    else:
        nanopore_machines = ['custom']

    fastq_pass_found = {}
    was_fastq_pass_found = []

    for each_input in inputs:
        for machine in nanopore_machines:
            if ''.join(nanopore_machines) != 'custom':
                input = os.path.join(each_input, machine)
            else:
                input = ''.join(each_input)

            logging.info(f"Searching path: {input}")

            if (os.path.exists(flowcells) and os.path.getsize(flowcells) > 0):
                with open(flowcells, 'r') as fcells:
                    for flowcell in fcells:
                        if re.match('^\s*$', flowcell):
                            continue
                        flowcell = flowcell.strip()
                        fastq_pass_path = glob.glob(os.path.join(input, flowcell, f"**", f"*[!fast5]*", 'fastq_pass'))
                        # Try one more time since the flowcell user is trying to query may be the parent directory
                        # of fastq_pass
                        fastq_pass = fastq_pass_path if fastq_pass_path else glob.glob(os.path.join(input, f"**", f"*[!fast5]*", flowcell, 'fastq_pass'))
                        if not fastq_pass:
                            # logging.warning(f"Flowcell " +
                            #     os.path.join(input, flowcell).strip() +
                            #     f" does not seem to have a fastq_pass directory! Skipped!!")
                            if not flowcell in fastq_pass_found.keys():
                                fastq_pass_found[flowcell] = 0 
                        else:
                            fastq_pass_found[flowcell] = 1
                            sym_link_dir = os.path.join(output, flowcell)
                            sym_link_dir_dest = os.path.join(sym_link_dir, 'fastq_pass')
                            if not os.path.exists(sym_link_dir):
                                os.makedirs(sym_link_dir)
                                os.symlink(
                                    ''.join(fastq_pass),
                                    sym_link_dir_dest, target_is_directory=True
                                )
                                logging.info(f"New soft link created: {sym_link_dir_dest}")
                            else:
                                logging.info(f"Soft link {sym_link_dir_dest} already exists! Skipped!!")
                    fcells.close()
            else:
                logging.error(f"File {flowcells} is empty or does not exist!\n")

    for k,v in fastq_pass_found.items():
        if not v:
            was_fastq_pass_found.append(k)

    if was_fastq_pass_found:
        logging.warning("Did not find fastq_pass folder for the supplied flowcells: " +
                ', '.join(was_fastq_pass_found))

    if was_fastq_pass_found and len(was_fastq_pass_found) == len(fastq_pass_found):
        logging.error(f"None of the supplied flowcells were found! The output directory, {output} may not have been created!")
    else:
        logging.info(f"NOTE: Now you can use {output} directory as --input to cpipes.\n")

if __name__ == "__main__":
    main()