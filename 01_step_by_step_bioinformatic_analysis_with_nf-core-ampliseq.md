# Bioinformatic analysis with [nf-core/ampliseq](https://nf-co.re/ampliseq/2.3.2) pipeline

<font size=20>__ITS ampliseq analysis with nf-core/ampliseq pipeline (step by step)__</font>

1. [Prepare HPC (here its NAISS or Uppmax) & environment](#sec1) </br>
    1.1. [Log in](#sec1.1)</br>
    1.2. [Background (Tmux) set up](#sec1.2)</br>
2. [Nextflow setup](#sec2)</br>
    
3. [nf-core module setup](#sec3)</br>
    
4. [Running a test workflow](#sec4)</br>
    4.1 [Trying out ampliseq](#sec4.1)</br>
    4.1.2 [Things to look out for](#sec4.1.2)</br> 
5. [Running a nf-core/ampliseq workflow ](#sec5)</br>
    5.1. [Example data, samplesheet preparation](#sec5.1)</br>
    5.1.1 [Samplesheet preparation](#sec5.1.1)</br>
    5.1.2 [Things to look out for](#sec5.1.2)</br>
6. [Final ampliseq script ](#sec6)</br>

<a name="sec1"></a>
## 1. Prepare HPC (here its Uppmax) & environment
<a name="sec1.1"></a>
### 1.1. Log in in HPC (UPPMAX)
First you needs to be log in virtual computer cluster (mycase UPPMAX’s module system or HPC) with ssh, after which you can initiate a new terminal in tmux by following commands:

```
ssh username@rackham.uppmax.uu.se # change 'username' and 'rackham.uppmax.uu.se'
```
<a name="sec1.2"></a>
### 1.2. Background or Tmux set up 
Tmux is a tool that will allow you to start a new terminal or WSL screen with any pipeline or workflow and run it in the background, allowing you to do other stuff during long calculations. As an added bonus, it will keep your processes going if you leave the server or your connection is unstable and crashes. 
```
module load tmux # loading the tmux module
tmux new -s ampliseq_its # or any other name you like
```
Now a new setup will pop up, anything you do in this new tmux terminal session is “safe”. When the connection to the server crashes mid-session, just reconnect to UPPMAX and do
####### module load tmux
####### tmux attach -t ampliseq_its

```
tmux set mouse on  # enable mouse support for things like scrolling and selecting text
```
To put tmux in background and keep the processes inside running, press Ctrl+B, release, press D. With tmux ls you can see which sessions are ongoing (can be multiple ones!) and you could connect to. To reattach to your earlier session type tmux attach -t nf_tutorial as shown above.

To kill a tmux session and stop any process running in it, press Ctrl+B, release, press X followed by Y.

All of this might seem to add unnecessary hassle but tmux is extremely valuable when working on a server. Instead of having to redo a long list of computational step when the connection to a server inevitably crashes, just reconnect to the ongoing tmux session and you are back exactly where you were when the crash happened! Tmux actually can do even more useful things, so if you want to know more, have a look at this quick and easy guide to tmux:https://www.hamvocke.com/blog/a-quick-and-easy-guide-to-tmux/.

<a name="sec2"></a>
##### 2. Nextflow setup (Nextflow	21.10.6)

Installation
```
module purge                        # Clears all existing loaded modules, to start fresh
module load uppmax bioinfo-tools    # Base UPPMAX environment modules, needed for everything else
module load Nextflow                # Note: Capital N!
```

Alternatively, to install nextflow yourself on your PC (when not on UPPMAX for example), try:

```
cd ~/bin    # Your home directory bin folder - full of binary executable files, already on your PATH
curl -s https://get.nextflow.io | bash
```

# Don't let Java get carried away and use huge amounts of memory
export NXF_OPTS='-Xms1g -Xmx4g'
# Don't fill up your home directory with cache files
export NXF_HOME=$HOME/nxf-home
export NXF_TEMP=${SNIC_TMP:-$HOME/glob/nxftmp}
Upon execution of the command, $USER will be replaced with your login name.

My case these three commands were look like this:
```
export NXF_OPTS='-Xms1g -Xmx4g'
export NXF_HOME=$/proj_launch_dir/
export NXF_TEMP=${SNIC_TMP:-$HOME/glob/nxftmp}
```

##### Check that Nextflow works
It’s always good to have a mini test to check that everything works.

These pipelines can create large temporary files and large result files, so we will do these exercises in the project folder. Make a new directory there and run the Nextflow test command as follows:

mkdir /proj/g2021025/nobackup/$USER # create personal folder in project directory
cd /proj/g2021025/nobackup/$USER # go in there
mkdir nextflow-hello-test # make new folder named nextflow-hello-test
cd nextflow-hello-test # go in there

```
nextflow run hello
```
You should see something like this:

N E X T F L O W  ~  version 20.10.0
Pulling nextflow-io/hello ...
downloaded from https://github.com/nextflow-io/hello.git
Launching `nextflow-io/hello` [sharp_sammet] - revision: 96eb04d6a4 [master]
executor >  local (4)
[7d/f88508] process > sayHello (4) [100%] 4 of 4 ✔
Bonjour world!

Ciao world!

Hello world!

Hola world!
Succes!


<a name="sec3"></a>
### 3. nf-core module setup
Recently, all nf-core pipelines have been made available on UPPMAX (rackham and Bianca) so they can be run on these servers without any additional setup besides loading the nf-core-pipelines module.

```
module load nf-core-pipelines/latest
```
Loading this module exposes the variable $NF_CORE_PIPELINES. This is the location on the server where all pipelines are stored. 

Note:
nf-core also comes as a Python package that is totally separate to Nextflow and is not required to run Nextflow pipelines. It does however offer some convenience functions to make your life a little easier. A description on how to install this package can be found here. This is useful if you want to run nf-core pipelines outside of UPPMAX or want to use some of the convenience functions included in the nf-core package.

If your hpc or PC do not have them you must load them ahead of running the actual commands written bellow
```
nextflow pull nf-core/ampliseq
``` 
<a name="sec4"></a>
## 4. Running a test workflow
It’s always a good idea to start working with a tiny test workflow when using a new Nextflow pipeline. This confirms that everything is set up and working properly, before you start moving around massive data files. To accommodate this, all nf-core pipelines come with a configuration profile called test which will run a minimal test dataset through the pipeline without needing any other pipeline parameters.

<a name="sec4.1."></a>
### 4.1. Trying out ampliseq
To try out for example the nf-core/ampliseq pipeline and see if everything is working, let’s try the test dataset.

Remember the key points:

Start with a fresh new empty directory

$NF_CORE_PIPELINES specifies the path where all pipelines are stored

Specify the pipeline with $NF_CORE_PIPELINES/[name]/[version]/workflow

Use the uppmax configuration profile to run on UPPMAX from a login node
If using this, also specify an UPPMAX project with `--project` (two hyphens!)

Use the test configuration profile to run a small test

By specifying the `--reservation g2021025_28`, we make sure to only run on the nodes reserved for today. This should speed up the execution of the pipeline. This parameter should not be set if you run pipelines after the course, since there will be no reserved set of nodes then.

```
cd /proj/g2021025/nobackup/$USER
mkdir ampliseq-test
cd ampliseq-test
nextflow run $NF_CORE_PIPELINES/ampliseq/1.2.1/workflow -profile test,uppmax --project g2021025 --clusterOptions '--reservation g2021025_28'
```

Now, I’ll be honest, there’s a pretty good chance that something will go wrong at this point. But that’s ok, that’s why we run a small test dataset! This is where you ask for help on Slack instead of suffering in silence.

If all goes well, you should start seeing some log output from Nextflow appearing on your console. Nextflow informs you which step of the pipeline it is doing and the percentage completed.

Even though the datasets in a test run are small, this pipeline can take a while because it submits jobs to the hpc or  UPPMAX server via the resource manager SLURM. Depending on how busy the server is at the moment (and it might be quite busy if you all run this at the same time!), it may take a while before your jobs are executed. It might therefore be necessary to cancel the pipeline once Nextflow seems to progress though the different steps slowly but steadily.  If you want to cancel the pipeline execution to progress with the tutorial, press CTRL-C. Or alternatively, put it in the background using tmux, do some other things and reattach later to check in on the progress.

### 4.1.1 Generated files
The pipeline will create a bunch of files in your directory as it goes:

$ ls -a1
./
../
.nextflow/
.nextflow.log
.nextflow.pid
results/
work/
The hidden .nextflow files and folders contain information for the cache and detailed logs.

Each task of the pipeline runs in its own isolated directory, these can be found under work. The name of each work directory corresponds to the task hash which is listed in the Nextflow log.

As the pipeline runs, it saves the final files it generates to results (customise this location with --outdir). Once you are happy that the pipeline has finished properly, you can delete the temporary files in work:

rm -rf work/


<a name="sec4.1.2"></a>
### 4.1.2. Re-running a pipeline with '-resume'
Nextflow is very clever about using cached copies of pipeline steps if you re-run a pipeline.

Once the test workflow has finished or you have canceled it the middle of its execution, try running the same command again with the -resume flag. Hopefully almost all steps will use the previous cached copies of results and the pipeline will finish extremely quickly.

This option is very useful if a pipeline fails unexpectedly, as it allows you to start again and pick up where you left off.


#### Read the docs
The documentation for nf-core pipelines is a big part of the community ethos.

Whilst the test dataset is running (it’s small, but the UPPMAX job queue can be slow), check out the nf-core website. Every pipeline has its own page with extensive documentation. For example, the ampliseq docs are at [https://nf-co.re/ampliseq](https://nf-co.re/ampliseq)
or at [github](https://github.com/nf-core/ampliseq)
nf-core pipelines also have some documentation on the command line. You can run this as you would a real pipeline run, but with the --help option.

In a new fresh directory(!), try this out:
```
cd /proj/g2021025/nobackup/$USER
mkdir ampliseq-help
cd ampliseq-help
nextflow run $NF_CORE_PIPELINES/ampliseq/1.2.1/workflow --help
```


<a name="sec5"></a>
## 5. Running a nf-core/ampliseq workflow 

Now we get to the real deal! Once you’ve gotten this far, you start to leave behind the generalisations that apply to all nf-core pipelines. Now you have to rely on your wits and the nf-core documentation. We have prepared small datasets for a Ampliseq analysis and a BS-seq analysis. You can choose to do the one that interests you most or if you have time you can try both!

<a name="sec5.1"></a>
### 5.1. Example data
We have prepared some example data for you that comes from the exercises you’ve worked on earlier in the week. The files have been subsampled to make them small and quick to run, and are supplied as gzipped (compressed) FastQ files here: path/to/input/fasta/fastq_sub12_gz/

Make a new directory for this CHiP seq analysis and link the data files to a data folder in this directory. We link to these files in this tutorial instead of copying them (which would also be an option) so as not to fill up the filesystem.

cd /proj/g2021025/nobackup/$USER
mkdir ampliseq_analysis
cd ampliseq_analysis
mkdir input_files
cd input_files
ln -s path/to/input/fasta/*.fastq.gz .
ls
The last command should show you the 4 neural fastq.gz files in this folder.

<a name="sec5.1.1"></a>
### 5.1.1. Preparing the sample sheet
The nf-core/ampliseq pipeline uses a comma-separated sample sheet file to list all of the input files and which replicate / condition they belong to.

Take a moment to read the documentation and make sure that you understand the fields and structure of the file.

We have made a sample sheet for you which describes the different condition: samplesheet.csv. Copy it to you ampliseq_analysis folder.

cd .. # move up one directory
cp path/to/input/samplesheet.csv .
cat samplesheet.csv
The cat command shows you the contents of the sample sheet.

<a name="sec5.1.2"></a>
### 5.1.2. Things to look out for
The following things are easy mistakes when working with ampliseq sample sheets - be careful!

File paths of the fast.gz files are relative to where you launch Nextflow (i.e. the ampliseq_analysis folder), not relative to the sample sheet

Do not have any blank newlines at the end of the file

Use Linux line endings (\n), not windows (\r\n)

If using single end data, keep the empty column for the second FastQ file

Once you’ve got your sample sheet ready, you can launch the analysis! 

#####################3  amplicon sequencing real run ############ 
##################################################################
###################################################################

<a name="sec6"></a>
## 6. Final ampliseq script 

```
cd /proj/snic2022-22-289/nobackup/abu/ampliseq_its/

##### for remote run
module load tmux
tmux new -s ampliseq
# or tmux attach -t ampliseq
tmux set mouse on

module load uppmax bioinfo-tools  
module load Nextflow    
module load nf-core-pipelines/latest

export NXF_OPTS='-Xms1g -Xmx4g'
export NXF_HOME=$/proj/snic2022-22-289/nobackup/abu/ampliseq_its/
export NXF_TEMP=${SNIC_TMP:-$HOME/glob/nxftmp}
```
Explanation of the Parameters file ('.json' file) used here

```
nextflow run \ # nextflow command
nf-core/ampliseq \ # calling ampliseq pipeline
--input /path/to/input_files \ # location or path to input fastq files
-profile uppmax \ # hpc you run, may need to have your custom profile or configs see more in the pipeline description
--max_cpus 20 \ # maximum cpu the run can occupy
--max_memory 36.GB \ # maximum memory or node the run can occupy
--project snic2022-22-289 \ # the computational project your hpc will use
--FW_primer GCATCGATGAAGAACGCAGC \ # forword ITS primer was used in sample preparation
--RV_primer TCCTCCGCTTATTGATATGC \ # reverse ITS primer was used in sample preparation
--dada_ref_taxonomy unite-fungi \ # unite fungal database pipeline will use from its path
--cut_dada_ref_taxonomy \ # taxonomy will be separately saved
--qiime_ref_taxonomy unite-fungi \ # unite fungal database pipeline will use from its path
--email abu.siddique@slu.se \ # your email a summary of the run will be send to
--metadata path/to/samplesheet/samplesheet.tsv \ # metadata file for further downstream analysis
--cut_its its2 \ # only ITS2 region will be extracted and analysed
--illumina_pe_its \ # if the sample is pairend
--trunclenf 223 \ # forward truncation of the reads
--trunclenr 162 \ # reverse truncation of the reads
--exclude_taxa "mitochondria,chloroplast,archea,bacteria" \ # these taxa will be discarded if identified
--min_frequency 1 \ # Singletons will be removed or removes sequences with less than one total counts
--min_samples 1 \ # retain features (ASVs or OTUs) that are present in at least one sample:
-bg \ # run pipeline in the backgroun
-resume \ # start from where it previously stopped
--outdir results \ # where the result will be saved
--ignore_empty_input_files \ # empty samples will be discarded
--skip_ancom \ # avaid assigning ANCOM features
--ignore_failed_trimming \ # samples will be vaoided who fail to exist after trimming
> amplseq_real_run_full_log_x.txt # log file will be saves as this name in the running directory
```


# Downsampled: 

## Extract sampleID from sample_sheet_v1.csv
cut -f1 /home/abusiddi/SLUBI/scripts/sample_sheet_v2.csv > /home/abusiddi/SLUBI/scripts/sample_sheet_v2_ids.txt

The input (/proj/uppstore2018171/abu/tanasp/P22702/01-Ampliseq-Analysis/input/) has `379` samples

sample_sheet_v2.csv file has `329` samples

metadata_2024_07_22.txt file has `353` samples

sub_metadata_2024_07_22_v2.txt file has `303`


## Extract sampleID from metadata_2024_07_22.txt (assuming it's a tab-delimited file)
cut -f1 /home/abusiddi/SLUBI/scripts/metadata_2024_07_22.txt > /home/abusiddi/SLUBI/scripts/metadata_v2_ids.txt
## Find common sample IDs
comm -12 <(sort /home/abusiddi/SLUBI/scripts/sample_sheet_v2_ids.txt) <(sort /home/abusiddi/SLUBI/scripts/metadata_v2_ids.txt) > /home/abusiddi/SLUBI/scripts/common_ids_v2.txt
## Filter sample_sheet_v1.csv based on common sample IDs
awk 'NR==FNR{a[$1]; next} FNR==1 || $1 in a' /home/abusiddi/SLUBI/scripts/common_ids_v2.txt /home/abusiddi/SLUBI/scripts/sample_sheet_v2.csv > /home/abusiddi/SLUBI/scripts/sub_sample_sheet_v2.tsv
## Filter metadata_2024_07_22.txt based on common sample IDs
awk 'NR==FNR{a[$1]; next} FNR==1 || $1 in a' /home/abusiddi/SLUBI/scripts/common_ids_v2.txt /home/abusiddi/SLUBI/scripts/metadata_2024_07_22.txt > /home/abusiddi/SLUBI/scripts/sub_metadata_2024_07_22_v2.txt

## nf-core/amplisecq command
 
nextflow run nf-core/ampliseq -r dev -profile uppmax -params-file /home/abusiddi/SLUBI/scripts/nf-params_v3.json --max_cpus 20 --max_memory 128.GB --project naiss2024-22-116 --min_frequency 5 --min_samples 2 --ignore_empty_input_files --ignore_failed_trimming --skip_fastqc --skip_dada_quality -bg -work-dir "./work3" --qiime_ref_tax_custom "/proj/naiss2023-23-270/nobackup/nxf/tanasp/sh_qiime_release_04.04.2024.tgz" > log25.txt

Error

### change file to the right format (.gz)
```
cd /proj/uppstore2018171/abu/tanasp/P22702/01-Ampliseq-Analysis/subsampled_v2/
gzip --force *.fastq.gz
```
then 
```
for file in *.fastq.gz.gz; do
     mv "${file}" "${file%.gz.gz}.gz"
done
```

# nextflow nf-core command 

## Downsampled data Command
Parameters file: [nf-params_v3.json](https://github.com/abu85/ampliseq_ITS/blob/main/nf-params_v3.json)
```
nextflow run nf-core/ampliseq -r dev -profile uppmax -params-file /home/abusiddi/SLUBI/scripts/nf-params_v3.json --max_cpus 20 --max_memory 128.GB --project naiss2024-22-116 --min_frequency 5 --min_samples 2 --ignore_empty_input_files --ignore_failed_trimming --skip_fastqc --skip_dada_quality -bg -work-dir "./work3" --qiime_ref_tax_custom "/proj/naiss2023-23-270/nobackup/nxf/tanasp/sh_qiime_release_04.04.2024.tgz" > log25.1txt
```
Finished unsuccessfully, but key results are obtained


## Full data command
Parameters file: [nf-params_v4.json](https://github.com/abu85/ampliseq_ITS/blob/main/nf-params_v4.json)
```
nextflow run nf-core/ampliseq -r dev -profile uppmax -params-file /home/abusiddi/SLUBI/scripts/nf-params_v4.json --max_cpus 20 --max_memory 128.GB --project naiss2024-22-116 --min_frequency 5 --min_samples 2 --ignore_empty_input_files --ignore_failed_trimming --skip_fastqc --skip_dada_quality -bg -work-dir "./work4" --qiime_ref_tax_custom "/proj/naiss2023-23-270/nobackup/nxf/tanasp/sh_qiime_release_04.04.2024.tgz" > log_full_run1.txt
```
finished successfully


Rest analysis was done on rstudio with R scripts (qurato scripts) as .qmd script.

### *** Details on the bioinformatic method, data & results can be found on Zenodo repository [link](https://zenodo.org/records/10839669))
