workflow TrioDenovoPipeline {
	File gatk_vcf = "path-of-VCF-file"
	File ped_file = "path-of-pedigree-file"
	File snpSiftJar = "s3://anushi-eagle-simulator-data/softwares/snpEff/SnpSift.jar"
	
	#File gatk_vcf
	#File ped_file
	#File snpSiftJar
	
		## call RunTriodenovo that runs TrioDenovo caller.
        call RunTriodenovo {
            input:
                gatk_vcf=gatk_vcf,
				ped_file=ped_file
        }
		
		## call DenovoQualityDatatype task on the VCF file from TrioDenovo caller.
		call DenovoQualityDatatype {
            input:
			Triodenovo_VCF_file=RunTriodenovo.triodenovo_output_vcf_file
		}
	
		## call AnnotateDNMsTrioDenovoVCF task to annotate VCF file.
		call AnnotateDNMsTrioDenovoVCF {
            input:
			snpSiftJarFile=snpSiftJar,
            Triodenovo_chr1_22_vcf=DenovoQualityDatatype.Triodenovo_chr1_22_vcf
		}
		
		## call ListOfDNMs to generate lists of de novo mutations.
		call ListOfDNMs {
            input:
			Triodenovo_annotated_file=AnnotateDNMsTrioDenovoVCF.Triodenovo_output_file_annotated
		}
		
		output {
			File triodenovo_output_vcf_file = RunTriodenovo.triodenovo_output_vcf_file
			File Triodenovo_output_DQ_datatype = DenovoQualityDatatype.Triodenovo_output_DQ_datatype
			File Triodenovo_chr1_22_vcf = DenovoQualityDatatype.Triodenovo_chr1_22_vcf
			File Triodenovo_output_file_annotated = AnnotateDNMsTrioDenovoVCF.Triodenovo_output_file_annotated
			File TrioDenovo_listof_allDNMs_file = ListOfDNMs.TrioDenovo_listof_allDNMs_file
			File TrioDenovo_list_of_snps_output = ListOfDNMs.TrioDenovo_list_of_snps_output
			File TrioDenovo_list_of_indels_output = ListOfDNMs.TrioDenovo_list_of_indels_output
		}
		
}

## Run TrioDenovo caller that takes VCF file and pedigree file as input.

task RunTriodenovo {
    File gatk_vcf
	File ped_file
    
	runtime {
        docker: "spashleyfu/ubuntu20_triodenovo:0.0.6"
        memory: "16GB"
        cpu: 2
        disks: "local-disk"
    }
    
	command {
		triodenovo --ped ${ped_file} --in_vcf ${gatk_vcf} --out_vcf Triodenovo.vcf
	}
    
	output {
        File triodenovo_output_vcf_file = "Triodenovo.vcf"
	}
}

## The data type of DQ variable is changed from Denovo Quality to float, because downstream processing tasks do not support this dataype.
## Also, chrX, chrY and chrM are filtered out from VCF file.

task DenovoQualityDatatype {
    File Triodenovo_VCF_file
	
    command {
		sed 's/Type=Denovo Quality/Type=float/g' ${Triodenovo_VCF_file} > Triodenovo_output_DQ_datatype.vcf | \ 
		grep -v "chrM\|chrX\|chrY" Triodenovo_output_DQ_datatype.vcf > Triodenovo_chr1_22.vcf
    }
    runtime {
        docker: "ubuntu:18.04"
        memory: "1GB"
        cpu: 1
        disks: "local-disk"
    }
   
    output {
        File Triodenovo_output_DQ_datatype = "Triodenovo_output_DQ_datatype.vcf"
		File Triodenovo_chr1_22_vcf = "Triodenovo_chr1_22.vcf"
	}
}


## The VCF file is annotated for variant type. 

task AnnotateDNMsTrioDenovoVCF {
    File snpSiftJarFile
	File Triodenovo_chr1_22_vcf
	
    command {
        java -jar ${snpSiftJarFile} varType ${Triodenovo_chr1_22_vcf} > Triodenovo_output_file_annotated.vcf 
    }
 
    runtime {
        docker: "openjdk:11.0-jdk"
        memory: "4GB"
        cpu: 1
        disks: "local-disk"
    }
   
    output {
        File Triodenovo_output_file_annotated = "Triodenovo_output_file_annotated.vcf"
	}
}

## Lists of de novo mutations with chromosome and position are generated for snps, indels and both.

task ListOfDNMs {
   File Triodenovo_annotated_file
	
	command {
	
		grep "VARTYPE=SNP\|VARTYPE=INS\|VARTYPE=DEL" ${Triodenovo_annotated_file} | cut -f1,2 | sed 's/\t/|/g' | sort | uniq > TrioDenovo_listof_allDNMs_file.txt | \
		
		grep "VARTYPE=SNP" ${Triodenovo_annotated_file} | cut -f1,2 | sed 's/\t/|/g' | sort | uniq > TrioDenovo_listof_snps_file.txt | \
		
		grep "VARTYPE=INS\|VARTYPE=DEL" ${Triodenovo_annotated_file} | cut -f1,2 | sed 's/\t/|/g' | sort | uniq > TrioDenovo_listof_indels_file.txt
	}
  
	runtime {
        docker: "ubuntu:18.04"
		memory: "1GB"
        cpu: 1
        disks: "local-disk"
    }
	
	output {
		File TrioDenovo_listof_allDNMs_file = "TrioDenovo_listof_allDNMs_file.txt"
		File TrioDenovo_list_of_snps_output = "TrioDenovo_listof_snps_file.txt"
		File TrioDenovo_list_of_indels_output = "TrioDenovo_listof_indels_file.txt"
    }
}

