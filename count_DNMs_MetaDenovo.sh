#!/bin/bash

dir=$1
#dir="/g/data/jb96/anushi/denovo_project/data/CHD_data/B1/939_recreated_AGHA_pipeline/CombineDNMsFromCallers/"
input=$dir"ALL_filtered_genotype_dnINDELs.txt"

LINES=$(cat $input)

for line in $LINES
do
  num_callers=0
  if grep -q $line $dir"dng_family1_formatted_chr1_22_INDEL.txt"; then
	num_callers=$((num_callers+1))
  fi
  
  if grep -q $line $dir"TrioDenovo_formatted_chr1_22_INDELs.txt"; then
	num_callers=$((num_callers+1))
  fi
  
  if grep -q $line $dir"PBT_formatted_chr1_22_INDELs.txt"; then
	num_callers=$((num_callers+1))
  fi
  
  if grep -q $line $dir"VarScan2_formatted_INDEL.txt"; then
	num_callers=$((num_callers+1))
  fi

echo $line"|"$num_callers
  
done

exit
