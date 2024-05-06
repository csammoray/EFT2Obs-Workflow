container:
  "docker://charlotteknight/eft2obs"

DECAY_PROCS = ["H_aa", "H_bb", "H_cc", "H_gg", "H_tautau", "H_WW", "H_Za", "H_ZZ", "H_mumu",
                "H_llll", "H_llnunu", "H_lnuqq",  "H_nunuqq", "H_qqqq"]
DECAY_PROCS = ["%s_SMEFTsim_topU3l"%proc for proc in DECAY_PROCS]

Z_PROCS = ["%s_SMEFTsim_topU3l"%proc for proc in ["Z_ll", "Z_qq", "Z_vv"]]

PROD_PROCS = ["tHq", "tHW", "ttH", "WH_lep", "ZH_lep", "bbH", "qqH"]
PROD_PROCS = ["%s_SMEFTsim_topU3l"%proc for proc in PROD_PROCS]

ALL_PROCS = DECAY_PROCS + Z_PROCS + PROD_PROCS

rule all:
  input:
    expand("results/{proc}/equation.json", proc=ALL_PROCS)    

rule copy_cards:
  input:
    "cards/{proc}/proc_card.dat"
  output:
    "results/cards/{proc}/proc_card.dat"
  shell:
    """
    cp cards/{wildcards.proc}/* results/cards/{wildcards.proc}/
    cp -r cards/restrict_cards/ results/cards/restrict_cards/
    """

rule setup_process:
  input:
    "results/cards/{proc}/proc_card.dat"
  output:
    "results/process_output/{proc}/MGMEVersion.txt"
  shell:
    """
    set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; export PATH=${{PATH}}:/eft2obs/scripts ; popd
    ./EFT2Obs/scripts/setup_model_for_proc.sh {wildcards.proc}
    ./EFT2Obs/scripts/setup_process.sh {wildcards.proc}
    """

rule auto_detect:
  input:
    "results/process_output/{proc}/MGMEVersion.txt"
  output:
    "results/cards/{proc}/reweight_card.dat",
    "results/cards/{proc}/config.json"
  shell:
    """
    set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; export PATH=${{PATH}}:/eft2obs/scripts ; popd
    ./EFT2Obs/scripts/setup_model_for_proc.sh {wildcards.proc}
    ./EFT2Obs/scripts/auto_detect_operators.py -p {wildcards.proc} 
    """

rule make_param_card:
  input:
    "results/cards/{proc}/config.json"
  output:
    "results/cards/{proc}/param_card.dat"
  shell:
    """
    set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; export PATH=${{PATH}}:/eft2obs/scripts ; popd
    ./EFT2Obs/scripts/make_param_card.py -p {wildcards.proc} -c results/cards/{wildcards.proc}/config.json -o results/cards/{wildcards.proc}/param_card.dat
    """

rule make_gridpack:
  input:
    "results/process_output/{proc}/MGMEVersion.txt",
    "results/cards/{proc}/param_card.dat",
    "results/cards/{proc}/reweight_card.dat"
  output:
    "results/process_output/gridpack_{proc}.tar.gz"
  shell:
    """
    set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; export PATH=${{PATH}}:/eft2obs/scripts ; popd
    ./EFT2Obs/scripts/setup_model_for_proc.sh {wildcards.proc}
    ./EFT2Obs/scripts/make_gridpack.sh {wildcards.proc}
    """

rule run_gridpack:
  input:
    "results/process_output/gridpack_{proc}.tar.gz"
  output:
    "results/{proc}/yoda/Rivet_1.yoda"
  shell:
    """
    set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; export PATH=${{PATH}}:/eft2obs/scripts ; popd
    export HIGGSPRODMODE=WH
    ./EFT2Obs/scripts/run_gridpack.py --gridpack results/process_output/gridpack_{wildcards.proc}.tar.gz -s 1 -e 500 -p HiggsTemplateCrossSectionsStage1,HiggsTemplateCrossSections -o results/{wildcards.proc}/yoda
    """

rule get_scaling:
  input:
    "results/{proc}/yoda/Rivet_1.yoda"
  output:
    "results/{proc}/equation.json"
  shell:
    """
    set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; export PATH=${{PATH}}:/eft2obs/scripts ; popd
    ./EFT2Obs/scripts/get_scaling.py -c results/cards/{wildcards.proc}/config.json -i results/{wildcards.proc}/yoda/Rivet_1.yoda --hist "/HiggsTemplateCrossSections/pT_V" --save json -o results/{wildcards.proc}/equation
    """

# rule make_config:
#   input:
#     "results/process_output/{proc}/MGMEVersion.txt"
#   output:
#     "results/cards/{proc}/config.json"
#   shell:
#     """
#     set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; export PATH=${{PATH}}:/eft2obs/scripts ; popd
#     ./EFT2Obs/scripts/make_config.py -p {wildcards.proc} -o results/cards/{wildcards.proc}/config.json --pars SMEFT:4 --def-val 1.0
#     """

# rule make_reweight_card:
#   input:
#     "results/cards/{proc}/config.json"
#   output:
#     "results/cards/{proc}/reweight_card.dat"
#   shell:
#     """
#     set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; export PATH=${{PATH}}:/eft2obs/scripts ; popd
#     ./EFT2Obs/scripts/make_reweight_card.py results/cards/{wildcards.proc}/config.json results/cards/{wildcards.proc}/reweight_card.dat
#     """