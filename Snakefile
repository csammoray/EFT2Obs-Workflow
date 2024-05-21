container:
  "docker://charlotteknight/eft2obs"

configfile: "config.json"

localrules: all, copy_proc_cards, copy_restrict_cards, auto_detect, make_param_card, get_scaling, merge_yoda

# rule all:
#   input:
#     expand("results/{proc}/equation.json", proc=config.keys())
rule all:
  input:
    expand("results/{proc}/equation.json", proc=["WH_lep_SMEFTsim_topU3l", "WH_lep_prop_SMEFTsim_topU3l", "ZH_lep_SMEFTsim_topU3l"])


rule copy_proc_cards:
  input:
    "cards/{proc}/proc_card.dat",
    "cards/{proc}/run_card.dat",
    "cards/{proc}/pythia8_card.dat"
  output:
    "results/cards/{proc}/proc_card.dat",
    "results/cards/{proc}/run_card.dat",
    "results/cards/{proc}/pythia8_card.dat"
  shell:
    """
    cp cards/{wildcards.proc}/* results/cards/{wildcards.proc}/
    """

rule copy_restrict_cards:
  output:
    "results/cards/restrict_cards/copied"
  shell:
    """
    cp -r cards/restrict_cards results/cards/
    touch results/cards/restrict_cards/copied
    """

rule setup_process:
  input:
    "results/cards/{proc}/proc_card.dat",
    "results/cards/restrict_cards/copied"
  output:
    "results/process_output/{proc}/MGMEVersion.txt",
    #"results/cards/{proc}/run_card.dat",
    #"results/cards/{proc}/pythia8_card.dat"
  resources:
    runtime=10
  shell:
    """
    set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; popd
    ./EFT2Obs/scripts/setup_model_for_proc.sh {wildcards.proc}
    ./EFT2Obs/scripts/setup_process.sh {wildcards.proc}
    sed -i 's/!partonlevel:mpi = off/partonlevel:mpi = off/g' results/cards/{wildcards.proc}/pythia8_card.dat
    """

rule auto_detect:
  input:
    "results/process_output/{proc}/MGMEVersion.txt"
  output:
    "results/cards/{proc}/reweight_card.dat",
    "results/cards/{proc}/config.json"
  shell:
    """
    set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; popd
    ./EFT2Obs/scripts/setup_model_for_proc.sh {wildcards.proc}
    ./EFT2Obs/scripts/auto_detect_operators.py -p {wildcards.proc} --noValidation
    """

rule make_param_card:
  input:
    "results/cards/{proc}/config.json"
  output:
    "results/cards/{proc}/param_card.dat"
  shell:
    """
    set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; popd
    ./EFT2Obs/scripts/make_param_card.py -p {wildcards.proc} -c results/cards/{wildcards.proc}/config.json -o results/cards/{wildcards.proc}/param_card.dat
    """

rule make_gridpack:
  input:
    "results/process_output/{proc}/MGMEVersion.txt",
    "results/cards/{proc}/param_card.dat",
    "results/cards/{proc}/reweight_card.dat",
    "results/cards/{proc}/run_card.dat",
    "results/cards/{proc}/pythia8_card.dat"
  output:
    "results/process_output/gridpack_{proc}.tar.gz"
  resources:
    runtime = lambda wc: config[wc.proc]["make_gridpack_runtime"],
  threads:
    lambda wc: config[wc.proc]["make_gridpack_threads"]
  shell:
    """
    set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; popd
    ./EFT2Obs/scripts/setup_model_for_proc.sh {wildcards.proc}
    ./EFT2Obs/scripts/make_gridpack.sh {wildcards.proc} 0 {threads}
    """

rule run_gridpack:
  input:
    "results/process_output/gridpack_{proc}.tar.gz"
  output:
    "results/{proc}/yoda/Rivet_{seed}.yoda"
  params:
    prodmode =    lambda wc: config[wc.proc]["prodmode"],
    nevents =    lambda wc: config[wc.proc]["nevents"],
    rivet =      lambda wc: config[wc.proc]["rivet"],
    extra_opts = lambda wc: config[wc.proc]["extra_opts"]
  resources:
    runtime=30
  shell:
    """
    set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; popd
    export HIGGSPRODMODE={params.prodmode}
    ./EFT2Obs/scripts/run_gridpack.py --gridpack results/process_output/gridpack_{wildcards.proc}.tar.gz -s {wildcards.seed} -e {params.nevents} -p {params.rivet} -o results/{wildcards.proc}/yoda {params.extra_opts}
    """

rule merge_yoda:
  input:
    expand("results/{{proc}}/yoda/Rivet_{i}.yoda", i=lambda wc: range(config[wc.proc]["njobs"]))
  output:
    "results/{proc}/yoda/Rivet.yoda"
  shell:
    """
    set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; popd
    yodamerge -o results/{wildcards.proc}/yoda/Rivet.yoda results/{wildcards.proc}/yoda/Rivet_*.yoda
    """

rule get_scaling:
  input:
    "results/{proc}/yoda/Rivet.yoda"
  output:
    "results/{proc}/equation.json"
  params:
    runset = lambda wildcards: config[wildcards.proc]
  shell:
    """
    set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; popd
    ./EFT2Obs/scripts/get_scaling.py -c results/cards/{wildcards.proc}/config.json -i results/{wildcards.proc}/yoda/Rivet.yoda --hist "/{params.runset[rivet]}/{params.runset[hist]}" --save common_json,txt -o results/{wildcards.proc}/equation --bin-labels EFT2Obs/resources/STXS_bin_labels.json --exclude-rel 0.001 --remove-empty-bins
    """