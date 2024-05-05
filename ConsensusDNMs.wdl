workflow ConsensusDNMs {
    
	#File DenovoGear_file = "s3://vccri-gwfcore-mictro/cromwell-execution/MetaDenovo_workflow/86429a68-8667-4c56-8278-a3773519f917/call-DenovoGear_p/DenovoGear_p.DenovoGearPipeline/9fd98288-5acf-4426-a6d2-59f12f74c424/call-ListOfDNMs/DenovoGear_listof_indels_file.txt"
	#File TrioDenovo_file = "s3://vccri-gwfcore-mictro/cromwell-execution/MetaDenovo_workflow/86429a68-8667-4c56-8278-a3773519f917/call-TrioDenovo_p/TrioDenovo_p.TrioDenovoPipeline/cdc0dc21-103d-46a7-b516-8902ffe72c18/call-ListOfDNMs/TrioDenovo_listof_indels_file.txt"
	#File varScan2_file = "s3://vccri-gwfcore-mictro/cromwell-execution/MetaDenovo_workflow/57354376-12f8-4b07-8513-bd8edeb03f2e/call-VarScan2_p/VarScan2_p.VarScan2Pipeline/728605b4-46dc-43b6-802f-d866bb8e98ab/call-ListOfDNMs/VarScan2_listof_indels_file.txt"
	#File PBT_file = "s3://vccri-gwfcore-mictro/cromwell-execution/MetaDenovo_workflow/86429a68-8667-4c56-8278-a3773519f917/call-PBT_p/PBT_p.PhasebytransmissionPipeline/9dd5671b-96d2-48e3-a54b-0d704e753803/call-ListOfDNMs/PBT_listof_dnINDELs_file.txt"
	
	File Consensus_DNM_script = "s3://vccri-giannoulatou-lab-denovo-mutations/MetaDenovo/MetaDenovoConsensusDNMs.sh"
	String variant_type
	#String variant_type = "INDEL"
	
		## Call callConsensusDNMs to generate output files for consensus of de novo mutations using four, three, two and one callers.
        call callConsensusDNMs {
            input:
                DenovoGear_file=DenovoGear_file,
				TrioDenovo_file=TrioDenovo_file,
				varScan2_file=varScan2_file,
				PBT_file=PBT_file,
				Consensus_DNM_script=Consensus_DNM_script,
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
		File Consensus_DNM_script
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
		  if grep -q $line ${DenovoGear_file}; then
			num_callers=$((num_callers+1))
		  fi
		  
		  if grep -q $line ${TrioDenovo_file}; then
			num_callers=$((num_callers+1))
		  fi
		  
		  if grep -q $line ${PBT_file}; then
			num_callers=$((num_callers+1))
		  fi
		  
		  if grep -q $line ${varScan2_file}; then
			num_callers=$((num_callers+1))
		  fi
		  
		  #echo $line"|"$num_callers
		  
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

