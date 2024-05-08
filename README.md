MetaDenovo : An automated framework to detect de novo mutations from whole genome trio data using cloud computing technology

MetaDenovo utilizes consensus for current state-of-the-art de novo callers (DeNovoGear, VarScan2, TrioDeNovo and PhaseByTransmission). It is developed using Cromwell (an open-source Workflow Management System for bioinformatics) and WDL(Workflow Definition Language) developed by Broad Institute. It is executed on AWS Cloud computing environment.

## Input File Requirements 

  o	WGS BAM files for trio (Mother, Father, Child)
  
  o	Trio VCF file from variant calling pipeline 
  
  o	Genome Reference file (.fa format)
  
  o	Pedigree file (PED file format)

## System Requirements 

### Cromwell Setup on Amazon Web Services : 

Please check out this link for help in setting up Cromwell Workflow : https://docs.opendata.aws/genomics-workflows/

It consists of mainly three steps :

  a.	Creation of Amazon VPC 
  
  b.	Creation of Genomics Workflow Core
  
  c.	Creation of Workflow Orchestrators using Cromwell

Please make sure if you have sufficient credits available for utilizing AWS.

## Running MetaDenovo.WDL script 

a.	Access Cromwell server (EC2 instance) via AWS Session Manager

b.	Type in the command “sudo su - ec2-user” to switch to the user’s home directory.

c.	Copy MetaDenovo repository onto Cromwell server

       git clone https://github.com/VCCRI/MetaDenovo.git 

d.	Zip of dependent files into imports directory.

       zip import *.wdl 

e.	Copy the directory "code_extend" into your own S3 bucket. The py files are used by MetaDenovo workflow and 
    need to be accessible by the batch instances created by MetaDenvo workflow.
	
* Update the parameters in UserInputs.json/UserInputs_demo.json 
* "MetaDenovo_workflow.python_file": "s3://<your S3 location>/code_extend/DenovoGear_numeric_genotype.py",
* "MetaDenovo_workflow.selectDNMGenotype_program": "s3://<your S3 location>/code_extend/TrioDenovo_select_DNM_genotype.py"

g.	Run the MetaDenovo DEMO workflow using curl command :

       curl -X POST "http://localhost:8000/api/workflows/v1" -H "accept: application/json" -F "workflowSource=@MetaDenovo.wdl" -F "workflowDependencies=@imports.zip" -F "workflowInputs=@UserInputs_demo.json" -F "workflowOptions=@Options_demo.json"
	
* Modify UserInputs_demo.json with S3 path to the "code_extend/" py files. 

* Mmodify Options_demo.json files to set your output S3 directory path.

* The output files are stored under the "final_workflow_outputs_dir" specified in Options_demo.json

  For de novo SNVs : ALL_dnSNP.txt, MetaDenovo_four_callers_SNP.txt, MetaDenovo_three_callers_SNP.txt, MetaDenovo_two_callers_SNP.txt and MetaDenovo_one_callers_SNP.txt

  For de novo INDELs : ALL_dnINDEL.txt, MetaDenovo_three_callers_INDEL.txt, MetaDenovo_two_callers_INDEL.txt and MetaDenovo_one_callers_INDEL.txt

* The worklow log files is located under wf_logs directory (provided by final_workflow_log_dir parameter in Options_demo.json file) on S3.

* Check for the message "Workflow MetaDenovo_workflow complete" in the workflow log file for successful workflow completion.

* It should take less than 1 hour to run DEMO data.

h.	Run the MetaDenovo workflow for your now data :

Provide the AWS S3 storage service paths to the following input file parameters in the MetaDenovo_UserInputs.json:
 
* mother_bam = Aligned BAM file of mother

* mother_bam_bai = Index file of aligned BAM file of mother

* father_bam = Aligned BAM file of father

* father_bam_bai = Index file of aligned BAM file of father

* child_bam = Aligned BAM file of offspring

* child_bam_bai = Index file of aligned BAM file of offspring

* chromosome IDs = list of chromosomes to interrogate for DNMs, eg [1,2,3]

* reference = reference genome fasta file

* reference_fai = Index file of reference genome fasta file

* reference_dict = Dictionary file of reference genome fasta file

* ped_file = trio’s pedigree file

* gatk_vcf = GATK processed VCF file for trio

* python_file = <your S3 location>/code_extend/DenovoGear_numeric_genotype.py

* selectDNMGenotype_program = <your S3 location>/code_extend/TrioDenovo_select_DNM_genotype.py

Setup your MetaDenovo_Options.json to contain the AWS S3 storage service paths where MetaDenovo outputs are to be stored:

* final_workflow_outputs_dir = location to store output DNMs files from MetaDenovo, which contains the consensus DNMs reports mentioned above and the original DNM results from each DNM caller.

* use_relative_output_paths: true

* final_workflow_log_dir = location to store workflow logs - a unique ID log file keeps track of all steps from the MetaDeNovo workflow.

* final_call_logs_dir = location to store call logs

MetaDeNovo is executed using the following command on the  Cromwell server:
  
 curl -X POST "http://localhost:8000/api/workflows/v1" 
 
-H "accept: application/json"

 -F "workflowSource=@MetaDenovo.wdl" 
 
-F "workflowDependencies=@imports.zip" 

-F "workflowInputs=@ MetaDenovo_UserInputs.json "

 -F "workflowOptions=@ MetaDenovo_Options.json"

Here, MetaDeNovo.wdl is the main WDL file. All sub-workflow WDL files for the four DNMs callers are zipped into the imports.zip folder. 

Take note of the "id" after submission as that is needed to check on the status of your workflow run.

"id":"1c2f0368-e876-4699-9049-7a5510f6df2f","status":"Submitted"}

i.	Checking the status of your MetaDenovo workflow run :

curl -X GET "http://localhost:8000/api/workflows/v1/1c2f0368-e876-4699-9049-7a5510f6df2f/status"

Response:

{"status":"Running","id":"1c2f0368-e876-4699-9049-7a5510f6df2f"}

{"status":"Running","id":"1c2f0368-e876-4699-9049-7a5510f6df2f"}
