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

## Running WDL script 

a.	Access Cromwell server (EC2 instance) via AWS Session Manager

b.	Type in command “sudo su - ec2-user” to switch of user’s home directory.

c.	Copy MetaDenovo WDL file onto Cromwell server

c.	Zip of dependent files into imports directory.

       zip imports DenovoGearPipeline.wdl DenovoGearPostProcessing.wdl VarScan2PostProcessing.wdl VarScan2Pipeline.wdl TrioDenovoPipeline.wdl PhasebytransmissionPipeline.wdl ConsensusDNMs.wdl

d.	Run the MetaDenovo workflow using curl command :

       curl -X POST "http://localhost:8000/api/workflows/v1" -H "accept: application/json" -F "workflowSource=@MetaDenovo.wdl" -F "workflowDependencies=@imports.zip"	

	



