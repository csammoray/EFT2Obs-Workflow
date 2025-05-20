# EFT2Obs-Workflow

Clone the repo with the EFT2Obs submodule:
```
git clone --recursive https://github.com/bonanomi/EFT2Obs-Workflow.git
```

To create the snakemake environment:
```
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh

conda create -n snakemake_py python=3.9
conda activate snakemake_py
conda install -c conda-forge mamba
eval "$(mamba shell hook --shell bash)"

mamba env create -n snakemake -f env.yaml
```

To source the environment do:
```
source env.sh
apptainer pull docker://charlotteknight/eft2obs:LO
```

where the second one is needed only the first time.

To run the workflow first run:
```
snakemake --sdm apptainer --apptainer-args "--writable-tmpfs -B /afs -B /cvmfs/cms.cern.ch -B /tmp -B /etc/sysconfig/ngbauth-submit -B ${XDG_RUNTIME_DIR} -B /eos --env KRB5CCNAME='FILE:${XDG_RUNTIME_DIR}/krb5cc' " -c 1
```

The `-c 1` tells snakemake to use one core. Specify a greater number if desired (it probably will be).

Note that the `-B` (or `--bind`) directories are not strictly necessary, and probably are unnecessary for condor jobs.

You can run on a different `Snakemake` file using the `-S` option (`default=Snakemake`).

To run on the batch at Imperial College (some minor work may be needed to extend to other condor systems), install some extra packages:
```
cookiecutter --output-dir ~/.config/snakemake gh:Snakemake-Profiles/htcondor
```
and then run snakemake with `--profile` option and without `-c 1`:
```
snakemake --sdm apptainer --apptainer-args "--writable-tmpfs --bind /vols  " --profile /afs/cern.ch/user/U/USER/.config/snakemake/USER/
```