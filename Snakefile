container:
  "docker://charlotteknight/eft2obs"

rule collect:
  input:
    "results/{proc}/equation.json"

rule setup_process:
  input:
    "cards/{proc}/proc_card.dat"
  output:
    "results/process_output/{proc}/MGMEVersion.txt"
  shell:
    """
    set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; export PATH=${{PATH}}:/eft2obs/scripts ; popd
    ./EFT2Obs/scripts/setup_model_for_proc.sh {wildcards.proc}
    ./EFT2Obs/scripts/setup_process.sh {wildcards.proc}
    """

# rule auto_detect:
#   input:
#     "results/process_output/{proc}/MGMEVersion.txt"
#   output:
#     "cards/{proc}/param_card.dat",
#     "cards/{proc}/reweight_card.dat",
#     "cards/{proc}/config.json"
#   shell:
#     """
#     set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; export PATH=${{PATH}}:/eft2obs/scripts ; popd
#     ./EFT2Obs/scripts/setup_model_for_proc.sh {wildcards.proc}
#     ./EFT2Obs/scripts/auto_detect_operators.py -p {wildcards.proc} 
#     """

rule make_config:
  input:
    "results/process_output/{proc}/MGMEVersion.txt"
  output:
    "results/{proc}/config.json"
  shell:
    """
    set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; export PATH=${{PATH}}:/eft2obs/scripts ; popd
    ./EFT2Obs/scripts/make_config.py -p {wildcards.proc} -o results/{wildcards.proc}/config.json --pars SMEFT:4,5,7
    """

rule make_param_card:
  input:
    "results/{proc}/config.json"
  output:
    "cards/{proc}/param_card.dat"
  shell:
    """
    set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; export PATH=${{PATH}}:/eft2obs/scripts ; popd
    ./EFT2Obs/scripts/make_param_card.py -p {wildcards.proc} -c results/{wildcards.proc}/config.json -o cards/{wildcards.proc}/param_card.dat
    """

rule make_reweight_card:
  input:
    "results/{proc}/config.json"
  output:
    "cards/{proc}/reweight_card.dat"
  shell:
    """
    set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; export PATH=${{PATH}}:/eft2obs/scripts ; popd
    ./EFT2Obs/scripts/make_reweight_card.py results/{wildcards.proc}/config.json cards/{wildcards.proc}/reweight_card.dat
    """

rule make_gridpack:
  input:
    "results/process_output/{proc}/MGMEVersion.txt",
    "cards/{proc}/param_card.dat",
    "cards/{proc}/reweight_card.dat"
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
    ./EFT2Obs/scripts/get_scaling.py -c results/{wildcards.proc}/config.json -i results/{wildcards.proc}/yoda/Rivet_1.yoda --hist "/HiggsTemplateCrossSections/pT_V" --save json -o results/{wildcards.proc}/equation
    """