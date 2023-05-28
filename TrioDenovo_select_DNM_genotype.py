#!/usr/bin/python2
# -*- coding: utf-8 -*-

## Author : Anushi Shah
## This program selects variants with DNM genotype for dnSNVs.
## i.e (Child-Mother-Father : 0/1 - 0/0 - 0/0 )
## Usage example : python2 TrioDenovo_select_DNM_genotype.py /g/data/jb96/anushi/denovo_project/data/simulated_data/family1_WGS_hg38_liftOver_V2/TriDenovo_GATK/Triodenovo_GATK_Variant_Annotated_SNPs.vcf > /g/data/jb96/anushi/denovo_project/data/simulated_data/family1_WGS_hg38_liftOver_V2/TriDenovo_GATK/Triodenovo_GATK_Selected_dnSNVs.vcf
## Please note, we don't use DNM pattern selection for dnINDELs as genoytypes are incorrectly printed by TrioDenovo for indels as per their website.
## (https://genome.sph.umich.edu/wiki/Triodenovo)

import sys
import os
import io


def SelectDNMGenotype(lines_arg):
	
	## Loop through each line of list variable (containing lines of input file).
	## Each line represents information from each variable.
	for each_line in lines_arg:
			if each_line.startswith("#"):
				print each_line.rstrip("\n")
			else:
				cols = each_line.split("\t")
				REF = cols[3]
				ALT = cols[4]
				INFO = cols[7]
				INFO_cols = INFO.split(";")
				FORMAT_parent1 = cols[9]
				FORMAT_cols_parent1 = FORMAT_parent1.split(":")
				gentotype_parent1 = FORMAT_cols_parent1[0]
				FORMAT_parent2 = cols[10]
				FORMAT_cols_parent2 = FORMAT_parent2.split(":")
				gentotype_parent2 = FORMAT_cols_parent2[0]
				FORMAT_child = cols[11]
				FORMAT_cols_child = FORMAT_child.split(":")
				gentotype_child = FORMAT_cols_child[0]

				vartype = ""
				if len(INFO_cols) == 3:
					vartype = INFO_cols[2]
				
				if gentotype_parent1 == REF+"/"+REF and gentotype_parent2 == REF+"/"+REF and vartype == "VARTYPE=SNP":
					if gentotype_child == REF+"/"+ALT or gentotype_child == ALT+"/"+REF:
						print each_line.rstrip("\n")
						##print REF+"\t"+ALT+"\t"+gentotype_parent1+"\t"+gentotype_parent2+"\t"+gentotype_child
				
																   

if __name__ == '__main__':
 	input_file = sys.argv[1]
	
	## Open input file, read lines and store into a list variable.
	## Close the input file.
	TrioDenovo_file = open(input_file, "r")
	lines = TrioDenovo_file.readlines()
	TrioDenovo_file.close()
	
	## Call SelectDNMGenotype function.
	SelectDNMGenotype(lines)
    
