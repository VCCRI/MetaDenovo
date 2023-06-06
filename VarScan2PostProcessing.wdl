workflow VarScan2PostProcessing {
    
	File snpSiftJar = "s3://vccri-giannoulatou-lab-denovo-mutations/softwares/snpEff/SnpSift.jar"
	
	Array[File] VarScan2_output_snp_files
	Array[File] VarScan2_output_indel_files
	#File snpSiftJar
	
	## Post-processing steps are executed for two types of variants - snps and indels. 
	## The steps are executed in parallel for each variant type, so scatter parallelism is perfomed.
	
	call CombineVarScan2Output { 
		input: 
			VarScan2_snp_files_list=VarScan2_output_snp_files,
			VarScan2_indel_files_list=VarScan2_output_indel_files

	}
	
	call ExtractDNMsVarScan2VCF {
        input:
			snpSiftJarFile=snpSiftJar,
            VarScan2_snp_VCF_file=CombineVarScan2Output.VarScan2_snp_combined,
			VarScan2_indel_VCF_file=CombineVarScan2Output.VarScan2_indel_combined
		}
	
	call ListOfDNMs {
        input:
			VarScan2_snp_file=ExtractDNMsVarScan2VCF.VarScan2_snp_DNMs_file,
			VarScan2_indel_file=ExtractDNMsVarScan2VCF.VarScan2_indel_DNMs_file
		}
} 

## Output vcf files from VarScan2 caller are combined in this task.
## VarScan2 caller produces vcf files for snps and indels separately for each chromosome.
 
task CombineVarScan2Output {
        Array[File] VarScan2_snp_files_list
		Array[File] VarScan2_indel_files_list
	
    command {
        vcf-concat ${sep=" " VarScan2_snp_files_list} > VarScan2_snp_combined.vcf;vcf-concat ${sep=" " VarScan2_indel_files_list} > VarScan2_indel_combined.vcf
    }
 
    runtime {
        docker: "pegi3s/vcftools"
        memory: "1GB"
        cpu: 1
        disks: "local-disk"
    }
   
    output {
        File VarScan2_snp_combined = "VarScan2_snp_combined.vcf"
		File VarScan2_indel_combined = "VarScan2_indel_combined.vcf"
	}
}

## In this task, variants with DENOVO status and PASS filter are extracted from VCF files.
## These are real de novo mutations.

task ExtractDNMsVarScan2VCF {
        File snpSiftJarFile
		File VarScan2_snp_VCF_file
		File VarScan2_indel_VCF_file
    
    command {
		
        java -jar ${snpSiftJarFile} filter "( FILTER = 'PASS' & exists DENOVO & GEN[0].GT == '0/0'  & GEN[1].GT == '0/0' & GEN[2].GT == '0/1')" ${VarScan2_snp_VCF_file} > VarScan2_snp_DNMs_file.vcf;java -jar ${snpSiftJarFile} filter "( FILTER = 'PASS' & exists DENOVO & GEN[0].GT == '0/0'  & GEN[1].GT == '0/0' & GEN[2].GT == '0/1')" ${VarScan2_indel_VCF_file} > VarScan2_indel_DNMs_file.vcf
    }
 
    runtime {
        docker: "openjdk:11.0-jdk"
        memory: "2GB"
        cpu: 1
        disks: "local-disk"
    }
   
    output {
        File VarScan2_snp_DNMs_file = "VarScan2_snp_DNMs_file.vcf"
		File VarScan2_indel_DNMs_file = "VarScan2_indel_DNMs_file.vcf"
    }
}

## In this task, list of chromosome and positions for de novo mutations is produced as output.
## Output file for snp and indels are separated depending on the variant_type provided as input.
 
task ListOfDNMs {
    	File VarScan2_snp_file
		File VarScan2_indel_file
    
	command {
		grep "^chr" ${VarScan2_snp_file} | cut -f1,2 | sed 's/\t/|/g' | sort | uniq > VarScan2_listof_snps_file.txt | \
		
		grep "^chr" ${VarScan2_indel_file} | cut -f1,2 | sed 's/\t/|/g' | sort | uniq > VarScan2_listof_indels_file.txt
	}
  
	runtime {
        docker: "ubuntu:18.04"
		memory: "1GB"
        cpu: 1
        disks: "local-disk"
    }
	
	output {
		File VarScan2_list_of_snps_output = "VarScan2_listof_snps_file.txt"
		File VarScan2_list_of_indels_output = "VarScan2_listof_indels_file.txt"
    }
}

