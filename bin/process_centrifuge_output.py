#!/usr/bin/env python

import os
import argparse
import logging as log
import pandas as pd
import numpy as np
from Bio import SeqIO


def main():
    # READ IN ARGUMENTS
    desc = """
    This script is part of the centriflaken pipeline: It processes centrifuge
    output and produces either a filtered FASTQ or a text file of FASTQ IDs based
    on the supplied taxa/bug
    """
    parser = argparse.ArgumentParser(prog='process_centrifuge_output.py', description=desc)
    parser.add_argument("-v", dest='verbose', action="store_true", help="For more verbose output")
    parser.add_argument("-i", dest='input_fastq', required=False,
        help="Path to input FASTQ file (same as input to centrifuge). If not mentioned, \
            a text file of sequence IDs are produced instead of a FASTQ file")
    parser.add_argument("-t", dest='taxa_filtered_fastq_file', required=True,
        help="Path to output FASTQ or output text file filtered by the taxa specified")
    parser.add_argument("-r", dest='cent_report', required=True, help="Path to centrifuge report")
    parser.add_argument("-o", dest='cent_output', required=True, help="Path to centrifuge output")
    parser.add_argument("-b", dest='bug', required=True,
        help="Name or fragment of name of the bug by which reads are extracted")
    args = parser.parse_args()

    # MORE INFO IF VERBOSE
    if args.verbose:
        log.basicConfig(format="%(levelname)s: %(message)s", level=log.DEBUG)
    else:
        log.basicConfig(format="%(levelname)s: %(message)s")

    # ASSIGN VARIABLES
    input_fastq = args.input_fastq
    taxa_filtered_fastq_file = args.taxa_filtered_fastq_file
    cent_report = args.cent_report
    cent_output = args.cent_output
    bug = args.bug
    report_col_list = ["name", "taxID"]
    output_col_list = ["taxID", "readID"]

    # Match and filter taxa names and ids from centrifuge report file
    report_df = pd.read_csv(cent_report, delimiter="\t", usecols=report_col_list)
    report_df['name'] = report_df['name'].str.lower()
    filt_report_df = report_df[report_df['name'].str.contains(bug.lower())]
    #print("\nMatching taxa names and ids:\n",filt_report_df)
    taxID_list = filt_report_df['taxID']

    # Match the above tax ids to read ids from centrifuge output file and deduplicate
    output_df = pd.read_csv(cent_output, delimiter="\t", usecols=output_col_list)
    filt_output_df = output_df.loc[output_df['taxID'].isin(taxID_list)]
    readID_list = filt_output_df['readID']
    readID_dedup_list = np.unique(readID_list)
    TF=open(taxa_filtered_fastq_file, "w")

    if (not input_fastq):
        # print("\nFILTERED READ ID LIST:\n", readID_dedup_list)
        for ID in readID_dedup_list:
            TF.write(f"{ID}\n")
    else:
        # Extract filtered reads from input fastq and write to output fastq
        print ("Indexing reads..")
        rec = SeqIO.index(input_fastq,"fastq")
        for i in readID_dedup_list:
            if i in rec:
                SeqIO.write(rec[i], TF, "fastq")

    TF.close()

if __name__ == "__main__":
    main()