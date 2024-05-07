workflow ConsensusDNMs {
   	
	##File Consensus_DNM_script = "s3://vccri-giannoulatou-lab-denovo-mutations/MetaDenovo/MetaDenovoConsensusDNMs.sh"
	String variant_type
	#String variant_type = "INDEL"
	
		## Call callConsensusDNMs to generate output files for consensus of de novo mutations using four, three, two and one callers.
        call callConsensusDNMs {
            input:
                DenovoGear_file=DenovoGear_file,
				TrioDenovo_file=TrioDenovo_file,
				varScan2_file=varScan2_file,
				PBT_file=PBT_file,
				## Consensus_DNM_script=Consensus_DNM_script,
				variant_type=variant_type
        }
		
		output {
			Array[File] output_text_files = callConsensusDNMs.output_text_files
		}
		
}

## This task calls script MetaDenovoConsensusDNMs.sh.
## It generates list of de novo mutations using consensus of using four, three, two and one callers.
## Variant type = snp or indel is passed argument.
## Five output files are generated depending on number of consensus of callers and also de novo mutations from all callers combined.

task callConsensusDNMs {
        File DenovoGear_file
		File TrioDenovo_file
		File varScan2_file
		File PBT_file
##		File Consensus_DNM_script
		String variant_type
    
	runtime {
        docker: "ubuntu:18.04"
        memory: "8GB"
        cpu: 2
        disks: "local-disk"
    }
    
	command {
		
		## Combine de novo mutations from four callers into one combined one.
		LINES=$(cat ${DenovoGear_file} ${TrioDenovo_file} ${PBT_file} ${varScan2_file} | sort | uniq)

		## Loop through all combined de novo mutations.
		## Check if each variant exists in which of the four callers and increase the num_callers if there's match.

		for line in $LINES
		do
		  num_callers=0
		  caller_id="|"
		  if grep -q $line ${DenovoGear_file}; then
			num_callers=$((num_callers+1))
			caller_id+="D"
		  fi
		  
		  if grep -q $line ${TrioDenovo_file}; then
			num_callers=$((num_callers+1))
			caller_id+="T"
		  fi
		  
		  if grep -q $line ${PBT_file}; then
			num_callers=$((num_callers+1))
			caller_id+="P"
		  fi
		  
		  if grep -q $line ${varScan2_file}; then
			num_callers=$((num_callers+1))
			caller_id+="V"
		  fi
		  
		  #echo $line"|"$num_callers$caller_id
		  
		  if [ $num_callers -eq 4 ]; then 
#			echo $line"|"$num_callers >> MetaDenovo_four_callers_${variant_type}.txt
			echo $line"|"$num_callers$caller_id >> MetaDenovo_four_callers_${variant_type}.txt
		  elif [ $num_callers -eq 3 ]; then
#			echo $line"|"$num_callers >> MetaDenovo_three_callers_${variant_type}.txt
            echo $line"|"$num_callers$caller_id >> MetaDenovo_three_callers_${variant_type}.txt
		  elif [ $num_callers -eq 2 ]; then
#			echo $line"|"$num_callers >> MetaDenovo_two_callers_${variant_type}.txt
            echo $line"|"$num_callers$caller_id >> MetaDenovo_two_callers_${variant_type}.txt
		  elif [ $num_callers -eq 1 ]; then
#			echo $line"|"$num_callers >> MetaDenovo_one_callers_${variant_type}.txt
            echo $line"|"$num_callers$caller_id >> MetaDenovo_one_callers_${variant_type}.txt
		  else
		    echo "Caller number out of range"
		  fi
				  
		done

		
		cat ${DenovoGear_file} ${TrioDenovo_file} ${PBT_file} ${varScan2_file} | sort | uniq > ALL_dn${variant_type}.txt

	}
    
	output {
		 Array[File] output_text_files = glob("*.txt")
	}
}

