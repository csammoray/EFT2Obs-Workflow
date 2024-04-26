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

I assume that you have apptainer installed on your system. For the time being, we need to increase the size of the temporary overlay (so you can write inside the container):
```
sudo apptainer config global --set "sessiondir max size" "1024"
```
More details about overlays: [https://apptainer.org/docs/user/main/persistent_overlays.html](https://apptainer.org/docs/user/main/persistent_overlays.html)

One could now run the snakemake command and it will internally pull the docker (converted by apptainer) container. However, I recommend pulling it with apptainer first
```
apptainer pull charlotteknight/eft2obs
```

To run the workflow first source some environment variables with `source env_vars.sh`. Then run:
```
snakemake --cores 1 --sdm apptainer --apptainer-args "--writable-tmpfs " -p results/WH_lep_SMEFTsim_topU3l/equation.json
```
