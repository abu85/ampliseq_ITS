# Bioinformatic analysis with [nf-core/ampliseq](https://nf-co.re/ampliseq/2.3.2) pipeline

### nfcore/ampliseq pipeline summary

---------- Abu Bakar Siddique, PhD, SLUBI, SLU

##### 01. Tmux ------------------------------
Tmux is a tool that will allow you to start any pipeline or workflow and run it in the background, allowing you to do other stuff during long calculations. As an added bonus, it will keep your processes going if you leave the server or your connection is unstable and crashes. First you needs to be log in virtual (mycase UPPMAX’s module system), after which you can initiate a new terminal in tmux by following commands:

module load tmux
tmux new -s ampliseq_tutorial # or any other name you like

Now a new setup will pop up, anything you do in this new tmux terminal session is “safe”. When the connection to the server crashes mid-session, just reconnect to UPPMAX and do
module load tmux
tmux attach -t its_real_run

tmux set mouse on  # enable mouse support for things like scrolling and selecting text

To put tmux in background and keep the processes inside running, press Ctrl+B, release, press D. With tmux ls you can see which sessions are ongoing (can be multiple ones!) and you could connect to. To reattach to your earlier session type tmux attach -t nf_tutorial as shown above.

To kill a tmux session and stop any process running in it, press Ctrl+B, release, press X followed by Y.

All of this might seem to add unnecessary hassle but tmux is extremely valuable when working on a server. Instead of having to redo a long list of computational step when the connection to a server inevitably crashes, just reconnect to the ongoing tmux session and you are back exactly where you were when the crash happened! Tmux actually can do even more useful things, so if you want to know more, have a look at this quick and easy guide to tmux:https://www.hamvocke.com/blog/a-quick-and-easy-guide-to-tmux/.


##### 02. Setup: Nextflow (Nextflow	21.10.6)

Installation

module purge                        # Clears all existing loaded modules, to start fresh
module load uppmax bioinfo-tools    # Base UPPMAX environment modules, needed for everything else
module load Nextflow                # Note: Capital N!


Alternatively, to install yourself (when not on UPPMAX for example):

cd ~/bin    # Your home directory bin folder - full of binary executable files, already on your PATH
curl -s https://get.nextflow.io | bash


Environment variable setup
Nextflow has a large list of bash environment variables that can be set to configure how it runs.

Note

If you don’t want to enter these commands every time you log in, the most convenient way to set these is to add them to the end of your .bashrc file in your home directory. Once here, they will be applied every time you log in automatically. [You don’t need to do that for this exercise session]

# Don't let Java get carried away and use huge amounts of memory
export NXF_OPTS='-Xms1g -Xmx4g'

# Don't fill up your home directory with cache files
export NXF_HOME=$HOME/nxf-home
export NXF_TEMP=${SNIC_TMP:-$HOME/glob/nxftmp}
Upon execution of the command, $USER will be replaced with your login name.

My case:
export NXF_OPTS='-Xms1g -Xmx4g'
export NXF_HOME=$/proj/snic2022-22-289/nobackup/abu/ampliseq_its/real_run/
export NXF_TEMP=${SNIC_TMP:-$HOME/glob/nxftmp}



##### 03. Check that Nextflow works ---------------------------
It’s always good to have a mini test to check that everything works.

These pipelines can create large temporary files and large result files, so we will do these exercises in the project folder. Make a new directory there and run the Nextflow test command as follows:

mkdir /proj/g2021025/nobackup/$USER # create personal folder in project directory
cd /proj/g2021025/nobackup/$USER
mkdir nextflow-hello-test
cd nextflow-hello-test
nextflow run hello
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



#### 04. Setup: nf-core -----------------------------------
Recently, all nf-core pipelines have been made available on UPPMAX (rackham and Bianca) so they can be run on these servers without any additional setup besides loading the nf-core-pipelines module.

module load nf-core-pipelines/latest
Loading this module exposes the variable $NF_CORE_PIPELINES. This is the location on the server where all pipelines are stored. Have a look at all pipelines and versions that are available

tree -L 2 $NF_CORE_PIPELINES -I 'singularity_cache_dir'

this will look like this:
/sw/bioinfo/nf-core-pipelines/latest/rackham
|-- airrflow
|   |-- 1.0.0
|   |-- 1.1.0
|   |-- 1.2.0
|   `-- 2.0.0
|-- ampliseq
|   |-- 1.0.0
|   |-- 1.1.0
|   |-- 1.1.1
|   |-- 1.1.2
|   |-- 1.1.3
|   |-- 1.2.0
|   |-- 2.0.0
|   |-- 2.1.0
|   |-- 2.1.1
|   |-- 2.2.0
|   |-- 2.3.0
|   `-- 2.3.1
|-- atacseq
|   |-- 1.0.0

This directory also contains all necessary software for all pipelines in a folder called singularity_cache_dir. This means you do not have to install any tools at all; they all are here packaged in singularity containers!

Note

nf-core also comes as a Python package that is totally separate to Nextflow and is not required to run Nextflow pipelines. It does however offer some convenience functions to make your life a little easier. A description on how to install this package can be found here. This is useful if you want to run nf-core pipelines outside of UPPMAX or want to use some of the convenience functions included in the nf-core package. [not necessary for running the current exercises on UPPMAX; but the students not on UPPMAX might give this a try]



##### 05. Running a test workflow-------------------------------
It’s always a good idea to start working with a tiny test workflow when using a new Nextflow pipeline. This confirms that everything is set up and working properly, before you start moving around massive data files. To accommodate this, all nf-core pipelines come with a configuration profile called test which will run a minimal test dataset through the pipeline without needing any other pipeline parameters.

#### 05.1. Trying out atacseq
To try out for example the nf-core/atacseq pipeline and see if everything is working, let’s try the test dataset.

Remember the key points:

Start with a fresh new empty directory

$NF_CORE_PIPELINES specifies the path where all pipelines are stored

Specify the pipeline with $NF_CORE_PIPELINES/[name]/[version]/workflow

Use the uppmax configuration profile to run on UPPMAX from a login node
If using this, also specify an UPPMAX project with --project (two hyphens!)

Use the test configuration profile to run a small test

By specifying the --reservation g2021025_28, we make sure to only run on the nodes reserved for today. This should speed up the execution of the pipeline. This parameter should not be set if you run pipelines after the course, since there will be no reserved set of nodes then.

cd /proj/g2021025/nobackup/$USER
mkdir atacseq-test
cd atacseq-test
nextflow run $NF_CORE_PIPELINES/atacseq/1.2.1/workflow -profile test,uppmax --project g2021025 --clusterOptions '--reservation g2021025_28'
Now, I’ll be honest, there’s a pretty good chance that something will go wrong at this point. But that’s ok, that’s why we run a small test dataset! This is where you ask for help on Slack instead of suffering in silence.

If all goes well, you should start seeing some log output from Nextflow appearing on your console. Nextflow informs you which step of the pipeline it is doing and the percentage completed.

Even though the datasets in a test run are small, this pipeline can take a while because it submits jobs to the UPPMAX server via the resource manager SLURM. Depending on how busy the server is at the moment (and it might be quite busy if you all run this at the same time!), it may take a while before your jobs are executed. It might therefore be necessary to cancel the pipeline once Nextflow seems to progress though the different steps slowly but steadily.  If you want to cancel the pipeline execution to progress with the tutorial, press CTRL-C. Or alternatively, put it in the background using tmux, do some other things and reattach later to check in on the progress.

### 05.1.1 Generated files
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


### 05.1.2. Re-running a pipeline with -resume
Nextflow is very clever about using cached copies of pipeline steps if you re-run a pipeline.

Once the test workflow has finished or you have canceled it the middle of its execution, try running the same command again with the -resume flag. Hopefully almost all steps will use the previous cached copies of results and the pipeline will finish extremely quickly.

This option is very useful if a pipeline fails unexpectedly, as it allows you to start again and pick up where you left off.


### 05.1.3. Read the docs
The documentation for nf-core pipelines is a big part of the community ethos.

Whilst the test dataset is running (it’s small, but the UPPMAX job queue can be slow), check out the nf-core website. Every pipeline has its own page with extensive documentation. For example, the atacseq docs are at https://nf-co.re/atacseq

nf-core pipelines also have some documentation on the command line. You can run this as you would a real pipeline run, but with the --help option.

In a new fresh directory(!), try this out:

cd /proj/g2021025/nobackup/$USER
mkdir atacseq-help
cd atacseq-help
nextflow run $NF_CORE_PIPELINES/atacseq/1.2.1/workflow --help





##### 06. Running a real workflow ---------------------------

Now we get to the real deal! Once you’ve gotten this far, you start to leave behind the generalisations that apply to all nf-core pipelines. Now you have to rely on your wits and the nf-core documentation. We have prepared small datasets for a chip-seq analysis and a BS-seq analysis. You can choose to do the one that interests you most or if you have time you can try both!

#### 06.1.  CHiP-seq
### Example data
We have prepared some example data for you that comes from the exercises you’ve worked on earlier in the week. The files have been subsampled to make them small and quick to run, and are supplied as gzipped (compressed) FastQ files here: /sw/courses/epigenomics/nextflow/fastq_sub12_gz/

Make a new directory for this CHiP seq analysis and link the data files to a data folder in this directory. We link to these files in this tutorial instead of copying them (which would also be an option) so as not to fill up the filesystem.

cd /proj/g2021025/nobackup/$USER
mkdir chip_seq_analysis
cd chip_seq_analysis
mkdir input_files
cd input_files
ln -s /sw/courses/epigenomics/nextflow/fastq_sub12_gz/neural/*.fastq.gz .
ls
The last command should show you the 4 neural fastq.gz files in this folder.

### 06.1.1. Preparing the sample sheet
The nf-core/chipseq pipeline uses a comma-separated sample sheet file to list all of the input files and which replicate / condition they belong to.

Take a moment to read the documentation and make sure that you understand the fields and structure of the file.

We have made a sample sheet for you which describes the different condition: samplesheet.csv. Copy it to you chip_seq_analysis folder.

cd .. # move up one directory
cp /sw/courses/epigenomics/nextflow/samplesheet.csv .
cat samplesheet.csv
The cat command shows you the contents of the sample sheet.

### 06.1.2. Things to look out for
The following things are easy mistakes when working with chipseq sample sheets - be careful!

File paths of the fast.gz files are relative to where you launch Nextflow (i.e. the chip_seq_analysis folder), not relative to the sample sheet

Do not have any blank newlines at the end of the file

Use Linux line endings (\n), not windows (\r\n)

If using single end data, keep the empty column for the second FastQ file

### 06.1.3. Running the pipeline
Once you’ve got your sample sheet ready, you can launch the analysis! 

#####################3  amplicon sequencing real run ############ 
##################################################################
###################################################################

## Final script --------------------------------
/proj/snic2022-22-289/nobackup/abu/ampliseq_its/real_run/



### for remote run
module load tmux
tmux new -s ampliseq
tmux set mouse on

module load uppmax bioinfo-tools  
module load Nextflow    
module load nf-core-pipelines/latest

export NXF_OPTS='-Xms1g -Xmx4g'
export NXF_HOME=$/proj/snic2022-22-289/nobackup/abu/ampliseq_its/
export NXF_TEMP=${SNIC_TMP:-$HOME/glob/nxftmp}

tmux attach -t ampliseq


nextflow run nf-core/ampliseq --input /proj/snic2022-22-289/nobackup/abu/ampliseq_its/input_files -profile uppmax --max_cpus 20 --max_memory 36.GB --project snic2022-22-289 --FW_primer GCATCGATGAAGAACGCAGC --RV_primer TCCTCCGCTTATTGATATGC --dada_ref_taxonomy unite-fungi --cut_dada_ref_taxonomy --qiime_ref_taxonomy unite-fungi --email abu.siddique@slu.se --metadata /proj/snic2022-22-289/nobackup/abu/ampliseq_its/samplesheet.tsv --cut_its its2 --illumina_pe_its --trunclenf 223 --trunclenr 162 --exclude_taxa "mitochondria,chloroplast,archea,bacteria" --min_frequency 1 --min_samples 1 -bg -resume --outdir /proj/snic2022-22-289/nobackup/abu/ampliseq_its/real_run/results --ignore_empty_input_files --skip_ancom --ignore_failed_trimming > amplseq_real_run_full_log_x.txt



Ctrl+B, release, press D


OneDrive - Umeå universitet

cd /mnt/c/Users/user_id/OneDrive\ \-\ \Umeå\ \universitet/Onedrive_21_01_2020/SwAsp_metagenom/results

scp -r abusiddi@rackham.uppmax.uu.se:/proj/snic2022-22-289/nobackup/abu/ampliseq_its/real_run/results .


