#!/usr/bin/env python

import os
import argparse
import logging as log
import pandas as pd
import numpy as np
from Bio import SeqIO


def main():
    # READ IN ARGUMENTS
    desc = """This script is part of the centriflaken pipeline:  
        - accepts assembled contigs (assembly.fasta from flye) and kraken classification (kraken_output.txt from kraken2) output 
        - filters the assembled contigs based on taxa specified 
        - outputs an assembled and filtered fasta (assembled_filtered_contigs.fasta) """
    parser = argparse.ArgumentParser(prog='extract_assembled_filtered_contigs.py', description=desc)
    parser.add_argument("-v", dest='verbose', action="store_true", help="for more verbose output")
    parser.add_argument("-i", dest='input_fasta', required=True, help="Path to input fasta file (assembled output from flye)")
    parser.add_argument("-o", dest='assembled_filtered_contigs', required=True, help="Path to output fasta file filtered by taxa specified")
    parser.add_argument("-k", dest='kraken_output', required=True, help="Path to kraken output file")
    parser.add_argument("-b", dest='bug', required=True, help="name or fragment of name of bug")
    args = parser.parse_args()

    # MORE INFO IF VERBOSE
    if args.verbose:
        log.basicConfig(format="%(levelname)s: %(message)s", level=log.DEBUG)
    else:
        log.basicConfig(format="%(levelname)s: %(message)s")

    # ASSIGN VARIABLES
    input_fasta = args.input_fasta
    assembled_filtered_contigs = args.assembled_filtered_contigs
    kraken_output = args.kraken_output
    bug = args.bug

    # Match and filter taxa names and ids from kraken output file
    report_df = pd.read_csv(kraken_output, delimiter="\t", usecols=[1,2], header=None)
    report_df.columns = ["contig", "name"]
    report_df['name'] = report_df['name'].str.lower()
    filt_report_df = report_df[report_df['name'].str.contains(bug.lower())]
    print("\nMatching taxa names and ids:\n",filt_report_df)
    filtered_contig_list = filt_report_df['contig']

    # Extract filtered reads from assembled input fasta and write to output fasta
    print ("Indexing reads..")
    rec = SeqIO.index(input_fasta,"fasta")
    TF=open(assembled_filtered_contigs, "w")
    for i in filtered_contig_list:
        if i in rec:
            SeqIO.write(rec[i], TF, "fasta")
    TF.close() 

    
if __name__ == "__main__":
    main()