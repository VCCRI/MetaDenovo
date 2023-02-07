#!/usr/bin/python2
# -*- coding: utf-8 -*-

## Author : Anushi Shah
## This program converts genotype of variants into numeric format.
## E.g. 0/1, 0/0, 1/1
## Usage example : python DenovoGear_numeric_genotype.py test_file.txt > output.txt

import sys
import os
import io


def numericGenotype(lines_arg):
	
	## Loop through each line of list variable (containing lines of input file).
	## Each line represents information from each variable.
	for each_line in lines_arg:
		cols = each_line.split(" ")
		event_type = cols[0]
		REF = cols[8]
		ALT = cols[10]
		tgt_dnm = cols[26]
		tgt_dnm_split = tgt_dnm.split("/")

		Child_GT = tgt_dnm_split[0]
		Mother_GT = tgt_dnm_split[1]
		Father_GT = tgt_dnm_split[2]
		Child_GT_binary = ""
		Mother_GT_binary = ""
		Father_GT_binary = ""
		
		### CHILD ###
		## Rules for converting genotype of Child into numeric format.
		if(event_type == "DENOVO-SNP" and Child_GT[0] in REF and Child_GT[1] in REF):
			Child_GT_binary = "0/0"
		elif (event_type == "DENOVO-SNP" and Child_GT[0] in REF and Child_GT[1] in ALT):
			Child_GT_binary = "0/1"
		elif (event_type == "DENOVO-SNP" and Child_GT[1] in REF and Child_GT[0] in ALT):
			Child_GT_binary = "0/1"
		elif(event_type == "DENOVO-INDEL" and Child_GT[0] == 'R' and Child_GT[1] == 'R'):
			Child_GT_binary = "0/0"         
		elif(event_type == "DENOVO-INDEL" and Child_GT[0] == 'R' and Child_GT[1] == 'D'):
			Child_GT_binary = "0/1"
		elif(event_type == "DENOVO-INDEL" and Child_GT[0] == 'D' and Child_GT[1] == 'R'):
			Child_GT_binary = "0/1"
		else:
			Child_GT_binary = "1/1"
		
		### MOTHER ###
		## Rules for converting genotype of Mother into numeric format.
		if(event_type == "DENOVO-SNP" and Mother_GT[0] in REF and Mother_GT[1] in REF):
			Mother_GT_binary = "0/0"
		elif (event_type == "DENOVO-SNP" and Mother_GT[0] in REF and Mother_GT[1] in ALT):
			Mother_GT_binary = "0/1"
		elif (event_type == "DENOVO-SNP" and Mother_GT[0] in ALT and Mother_GT[1] in REF):
			Mother_GT_binary = "0/1"
		elif(event_type == "DENOVO-INDEL" and Mother_GT[0] == 'R' and Mother_GT[1] == 'R'):
			Mother_GT_binary = "0/0"
		elif(event_type == "DENOVO-INDEL" and Mother_GT[0] == 'R' and Mother_GT[1] == 'D'):
			Mother_GT_binary = "0/1"
		elif(event_type == "DENOVO-INDEL" and Mother_GT[0] == 'D' and Mother_GT[1] == 'R'):
			Mother_GT_binary = "0/1"
		else:
			Mother_GT_binary = "1/1"
		
		### FATHER ###
		## Rules for converting genotype of Father into numeric format.
		if(event_type == "DENOVO-SNP" and Father_GT[0] in REF and Father_GT[1] in REF):
			Father_GT_binary = "0/0"
		elif (event_type == "DENOVO-SNP" and Father_GT[0] in REF and Father_GT[1] in ALT):
			Father_GT_binary = "0/1"
		elif (event_type == "DENOVO-SNP" and Father_GT[0] in ALT and Father_GT[1] in REF):
			Father_GT_binary = "0/1"    
		elif(event_type == "DENOVO-INDEL" and Father_GT[0] == 'R' and Father_GT[1] == 'R'):
			Father_GT_binary = "0/0"
		elif(event_type == "DENOVO-INDEL" and Father_GT[0] == 'R' and Father_GT[1] == 'D'):
			Father_GT_binary = "0/1"
		elif(event_type == "DENOVO-INDEL" and Father_GT[0] == 'D' and Father_GT[1] == 'R'):
			Father_GT_binary = "0/1"
		else:
			Father_GT_binary = "1/1"
				
		## print the line to standard output (file).
		print each_line.rstrip("\n")+" "+"Child_GT_binary"+" "+Child_GT_binary+" "+"Mother_GT_binary"+" "+Mother_GT_binary+" "+"Father_GT_binary"+" "+Father_GT_binary
    

if __name__ == '__main__':
 	input_file = sys.argv[1]
	
	## Open input file, read lines and store into a list variable.
	## Close the input file.
	DenovoGear_dnm_file = open(input_file, "r")
	lines = DenovoGear_dnm_file.readlines()
	DenovoGear_dnm_file.close()
	
	## Call numericGenotype function.
	numericGenotype(lines)
    
