#!/bin/bash

## Program to generate list of de novo mutations using consensus of number of callers.
## Takes variant_type as input i.e. snp or indel
## Takes input files with list of de novo mutations for four callers : DenovoGear, TrioDenovo, Phasebytransmission and VarScan2
## Five output files are generated depending on number of consensus of callers and also de novo mutations from all callers combined.

## Input parameters
variant_type=$1
DenovoGear_file=$2
TrioDenovo_file=$3
PBT_file=$4
VarScan2_file=$5

## Combine de novo mutations from four callers into one combined one.
LINES=$(cat $DenovoGear_file $TrioDenovo_file $PBT_file $VarScan2_file | sort | uniq)

## Loop through all combined de novo mutations.
## Check if each variant exists in which of the four callers and increase the num_callers if there's match.

for line in $LINES
do
  num_callers=0
  if grep -q $line $DenovoGear_file; then
	num_callers=$((num_callers+1))
  fi
  
  if grep -q $line $TrioDenovo_file; then
	num_callers=$((num_callers+1))
  fi
  
  if grep -q $line $PBT_file; then
	num_callers=$((num_callers+1))
  fi
  
  if grep -q $line $VarScan2_file; then
	num_callers=$((num_callers+1))
  fi

#echo $line"|"$num_callers
	
	## Switch case to print out de novo mutation into the file according to the number of callers called it.
	case $num_callers in
		4) echo $line"|"$num_callers >> 'MetaDenovo_four_callers_'$variant_type'.txt' ;;
		3) echo $line"|"$num_callers >> 'MetaDenovo_three_callers_'$variant_type'.txt' ;;
		2) echo $line"|"$num_callers >> 'MetaDenovo_two_callers_'$variant_type'.txt' ;;
		1) echo $line"|"$num_callers >> 'MetaDenovo_one_callers_'$variant_type'.txt' ;;
		*) echo $line"|"$num_callers >> 'MetaDenovo_no_match_'$variant_type'.txt' ;;
	esac
  
done

combined_DNMs_file='ALL_dn'$variant_type'.txt'

# Combine DNMs from all callers -> ALL_dnSNPs.txt
cat $DenovoGear_file $TrioDenovo_file $PBT_file $varScan2_file | sort | uniq > $combined_DNMs_file


exit
