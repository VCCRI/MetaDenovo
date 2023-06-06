workflow DenovoGearPostProcessing {
    
	#Array[File] DNGOutputFiles_array = ["s3://vccri-gwfcore-mictro/cromwell-execution/MetaDenovo_workflow/fc5e52ed-8ade-41d7-b370-bc8e74eb8357/call-DenovoGear_p/348895e0-e536-41d6-ad41-0b2e6d9143cb/call-DenovoGear_caller/shard-21/chr22_dng.out", "s3://vccri-gwfcore-mictro/cromwell-execution/MetaDenovo_workflow/fc5e52ed-8ade-41d7-b370-bc8e74eb8357/call-DenovoGear_p/348895e0-e536-41d6-ad41-0b2e6d9143cb/call-DenovoGear_caller/shard-20/chr21_dng.out"]
	File python_file = "s3://vccri-giannoulatou-lab-denovo-mutations/MetaDenovo/DenovoGear_numeric_genotype.py"
	
	Array[File] DNGOutputFiles_array
	
	call CombineDenovoGearOutput { input: DNGOutputFiles=DNGOutputFiles_array }
	
	call NumericGenotype {
            input:
			python_file=python_file,
			DNG_file=CombineDenovoGearOutput.CombinedDNGOutput
    }
	
	call SelectDNMGenotype {
			input:
			Numeric_Genotype_input=NumericGenotype.DenovoGear_NumericGenotype_output
	}
	
	call SplitSnpIndel {
            input:
			Combined_DNG_Numeric_Genotype_file=SelectDNMGenotype.DenovoGear_DNM_Genotype_output
	}
	
	call ListOfDNMs {
            input:
			DenovoGear_DNMs_file=SelectDNMGenotype.DenovoGear_DNM_Genotype_output,
			DenovoGear_snp_file=SplitSnpIndel.DenovoGear_snp_file,
			DenovoGear_indel_file=SplitSnpIndel.DenovoGear_indel_file
	}
	
	
}


## Combines all the output files (chromosome wise) generated from running DenovoGear caller into one file.

task CombineDenovoGearOutput {
	Array[File] DNGOutputFiles

command {

	cat ${sep=" " DNGOutputFiles} > combinedoutput.DNG.txt
	
}

runtime {
	docker: "ubuntu:18.04"
	memory: "2GB"
    cpu: 1
    disks: "local-disk"
}

output {
	File CombinedDNGOutput = "combinedoutput.DNG.txt"
}

}

## Converts genotype of variants into binary format. e.g. C/T is converted to 0/1 based on reference.
task NumericGenotype {
		File python_file
		File DNG_file
	
	command {
		python ${python_file} ${DNG_file} > DenovoGear_NumericGenotype.txt
	}
  
	runtime {
        docker: "python:2.7.18-stretch"
		memory: "4GB"
        cpu: 2
        disks: "local-disk"
    }
	
	output {
        File DenovoGear_NumericGenotype_output = "DenovoGear_NumericGenotype.txt"
    }
}

## Filter variants with de novo mutation genotype pattern (Child = 0/1, father = 0/0, mother = 0/0)
## Here 0/1 = heterozygous alternate and 0/0 = homozygous reference.

task SelectDNMGenotype {
     File Numeric_Genotype_input
	
	command <<<
		awk '{ if (($47 == "0/1") && ($49 == "0/0") && ($51 == "0/0")) { print } }' ${Numeric_Genotype_input} > DenovoGear_DNM_Genotype_output.txt
	>>>
  
	runtime {
        docker: "ubuntu:18.04"
		memory: "1GB"
        cpu: 1
        disks: "local-disk"
    }
	
	output {
        File DenovoGear_DNM_Genotype_output = "DenovoGear_DNM_Genotype_output.txt"
	}
}

## Separate files for SNP and INDELs are generated.

task SplitSnpIndel {
        File Combined_DNG_Numeric_Genotype_file

	
	command {
		grep "DENOVO-SNP" ${Combined_DNG_Numeric_Genotype_file} > DenovoGear_snp_file.txt | \ 
		
		grep "DENOVO-INDEL" ${Combined_DNG_Numeric_Genotype_file} > DenovoGear_indel_file.txt
	}
  
	runtime {
        docker: "ubuntu:18.04"
		memory: "1GB"
        cpu: 1
        disks: "local-disk"
    }
	
	output {
        File DenovoGear_snp_file = "DenovoGear_snp_file.txt"
		File DenovoGear_indel_file = "DenovoGear_indel_file.txt"
    }
}

## Lists of de novo mutations with chromosome and position are generated for snps, indels and both.

task ListOfDNMs {
		File DenovoGear_DNMs_file
        File DenovoGear_snp_file
		File DenovoGear_indel_file
	
	command {
		cut -f5,7 -d' ' ${DenovoGear_DNMs_file} | sed 's/ /|/g' | sort | uniq > DenovoGear_listof_DNMs_file.txt | \ 
		
		cut -f5,7 -d' ' ${DenovoGear_snp_file} | sed 's/ /|/g' | sort | uniq > DenovoGear_listof_snps_file.txt | \ 
		
		cut -f5,7 -d' ' ${DenovoGear_indel_file} | sed 's/ /|/g' | sort | uniq > DenovoGear_listof_indels_file.txt
	}
  
	runtime {
        docker: "ubuntu:18.04"
		memory: "1GB"
        cpu: 1
        disks: "local-disk"
    }
	
	output {
		File DenovoGear_DNMs_file_output = "DenovoGear_listof_DNMs_file.txt"
        File DenovoGear_list_of_snps_output = "DenovoGear_listof_snps_file.txt"
		File DenovoGear_list_of_indels_output = "DenovoGear_listof_indels_file.txt"
    }
}



