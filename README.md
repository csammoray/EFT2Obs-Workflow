# EFT2Obs-Workflow

To create the snakemake environment:
```
curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj bin/micromamba
mv bin snakemake_env
export MAMBA_ROOT_PREFIX=${PWD}/snakemake_env
eval "$(./snakemake_env/micromamba shell hook -s posix)"

micromamba create -c conda-forge -c bioconda -n snakemake snakemake
micromamba activate snakemake
```

To source the environment from a fresh terminal later do:
```
export MAMBA_ROOT_PREFIX=${PWD}/snakemake_env
eval "$(./snakemake_env/micromamba shell hook -s posix)"
micromamba activate snakemake
```

I assume that you have apptainer installed on your system. 

To run the workflow first source some environment variables with `source env_vars.sh`. Then run:
```
snakemake --cores 1 --sdm apptainer
```
