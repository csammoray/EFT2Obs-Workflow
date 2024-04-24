container:
  "docker://charlotteknight/eft2obs"

rule collect:
  input:
    "HiggsTemplateCrossSections_pT_V.json"

rule setup_process:
  output:
    "procs/zh-HEL/MGMEVersion.txt"
  shell:
    """
    set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; export PATH=${{PATH}}:/eft2obs/scripts ; popd
    ./EFT2Obs/scripts/setup_process.sh zh-HEL
    """

rule make_config:
  input:
    "procs/zh-HEL/MGMEVersion.txt"
  output:
    "config_HEL_STXS.json"
  shell:
    """
    set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; export PATH=${{PATH}}:/eft2obs/scripts ; popd
    ./EFT2Obs/scripts/make_config.py -p zh-HEL -o config_HEL_STXS.json --pars newcoup:4,5,6,7,8,9,10,11,12 --def-val 0.01 --def-sm 0.0 --def-gen 0.0
    """

rule make_param_card:
  input:
    "config_HEL_STXS.json"
  output:
    "cards/zh-HEL/param_card.dat"
  shell:
    """
    set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; export PATH=${{PATH}}:/eft2obs/scripts ; popd
    ./EFT2Obs/scripts/make_param_card.py -p zh-HEL -c config_HEL_STXS.json -o cards/zh-HEL/param_card.dat
    """

rule make_reweight_card:
  input:
    "config_HEL_STXS.json"
  output:
    "cards/zh-HEL/reweight_card.dat"
  shell:
    """
    set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; export PATH=${{PATH}}:/eft2obs/scripts ; popd
    ./EFT2Obs/scripts/make_reweight_card.py config_HEL_STXS.json cards/zh-HEL/reweight_card.dat
    """

rule make_gridpack:
  input:
    "procs/zh-HEL/MGMEVersion.txt",
    "cards/zh-HEL/param_card.dat",
    "cards/zh-HEL/reweight_card.dat"
  output:
    "procs/gridpack_zh-HEL.tar.gz"
  shell:
    """
    set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; export PATH=${{PATH}}:/eft2obs/scripts ; popd
    ./EFT2Obs/scripts/make_gridpack.sh zh-HEL
    """

rule run_gridpack:
  input:
    "procs/gridpack_zh-HEL.tar.gz"
  output:
    "test-zh/Rivet_1.yoda"
  shell:
    """
    set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; export PATH=${{PATH}}:/eft2obs/scripts ; popd
    export HIGGSPRODMODE=ZH
    ./EFT2Obs/scripts/run_gridpack.py --gridpack procs/gridpack_zh-HEL.tar.gz -s 1 -e 500 -p HiggsTemplateCrossSectionsStage1,HiggsTemplateCrossSections -o test-zh
    """

rule get_scaling:
  input:
    "test-zh/Rivet_1.yoda"
  output:
    "HiggsTemplateCrossSections_pT_V.json"
  shell:
    """
    set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; export PATH=${{PATH}}:/eft2obs/scripts ; popd
    ./EFT2Obs/scripts/get_scaling.py -c config_HEL_STXS.json -i test-zh/Rivet_1.yoda --hist "/HiggsTemplateCrossSections/pT_V" --save json,txt,tex
    """