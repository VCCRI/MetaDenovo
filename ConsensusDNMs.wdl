workflow ConsensusDNMs {
    
	File DenovoGear_file
	File TrioDenovo_file
	File varScan2_file
	File PBT_file
	File Consensus_DNM_script
	String variant_type
	
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
        memory: "4GB"
        cpu: 2
        disks: "local-disk"
    }
    
	command {
		
			sh ${Consensus_DNM_script} ${variant_type} ${DenovoGear_file} ${TrioDenovo_file} ${varScan2_file} ${PBT_file}
	}
    
	output {
		 File MetaDenovo_four_callers = "MetaDenovo_four_callers_${variant_type}.txt"
		 File MetaDenovo_three_callers = "MetaDenovo_three_callers_${variant_type}.txt"
		 File MetaDenovo_two_callers = "MetaDenovo_two_callers_${variant_type}.txt"
		 File MetaDenovo_one_callers = "MetaDenovo_one_callers_${variant_type}.txt"
		 File ALL_DNMs = "ALL_dn${variant_type}.txt"
	}
}

