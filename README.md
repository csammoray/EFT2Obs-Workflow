# EFT2Obs-Workflow

Clone the repo with the EFT2Obs submodule:
```
git clone --recursive https://github.com/Charlotte-Knight/EFT2Obs-Workflow.git
```

To create the snakemake environment:
```
curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj bin/micromamba
mv bin snakemake_env
export MAMBA_ROOT_PREFIX=${PWD}/snakemake_env
eval "$(./snakemake_env/micromamba shell hook -s posix)"

micromamba env create -n snakemake -f env.yaml
```

To source the environment do:
```
source env.sh
```

I assume that you have apptainer installed on your system. One could now run the snakemake command and it will internally pull the docker (converted by apptainer) container. However, I recommend pulling it with apptainer first
```
apptainer pull docker://charlotteknight/eft2obs:LO
```

To run the workflow first run:
```
snakemake --sdm apptainer --apptainer-args "--writable-tmpfs " -c 1
```

The `-c 1` tells snakemake to use one core. Specify a greater number if desired (it probably will be).

You may want to bind some additional directories such that they are visible inside the container. This is done the the `--bind` apptainer arg. For example, to bind the `/vols` directory, instead run:
```
snakemake --sdm apptainer --apptainer-args "--writable-tmpfs --bind /vols /home " -c 1
```

To run on the batch at Imperial College (some minor work may be needed to extend to other condor systems), install some extra packages:
```
cookiecutter --output-dir ~/.config/snakemake gh:Charlotte-Knight/htcondor-ic
```
and then run snakemake with `--profile htcondor` and without `-c 1`. 
```
snakemake --sdm apptainer --apptainer-args "--writable-tmpfs --bind /vols  " --profile htcondor
```