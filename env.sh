export MAMBA_ROOT_PREFIX=${PWD}/snakemake_env
eval "$(./snakemake_env/micromamba shell hook -s posix)"
micromamba activate snakemake

export EFT2OBS_DIR=/eft2obs
export PROC_DIR=$(pwd)/results/process_output
export CARDS_DIR=$(pwd)/results/cards
export TMPDIR=$(pwd)/tmp

cp resources/diff_bin_labels.json EFT2Obs/resources
cp resources/CMS_2025_I2872501.cc EFT2Obs/RivetPlugins