container:
  "docker://charlotteknight/eft2obs:LO"

wildcard_constraints:
  version = r"[0-9]+"

configfile: "config.json"

localrules: all, copy_cards, copy_restrict_cards, setup_process, auto_detect, setup_SM_gen, make_param_card, merge_yoda, get_scaling, add_versions,add_versions_common,add_versions_CMS

# rule all:
#   input:
#     expand("results/equations/{proc}.common.json", proc=config.keys())
# rule all:
#   input:
#     expand("results/equations/{proc}.common.json", proc=["WH_lep_SMEFTsim_topU3l", "WH_lep_SMEFTsim_topU3l_ATLAS"])
# rule all:
#  input:
#    expand("results/equations/{proc}.common.json", proc=["WH_lep_SMEFTsim_topU3l", "ZH_lep_SMEFTsim_topU3l", "ttH_SMEFTsim_topU3l"]),
#    expand("results/equations/{proc}.json", proc=["WH_lep_SMEFTsim_topU3l", "ZH_lep_SMEFTsim_topU3l", "ttH_SMEFTsim_topU3l"]),
#    expand("results/equations/{proc}.CMS.json", proc=["WH_lep_SMEFTsim_topU3l", "ZH_lep_SMEFTsim_topU3l", "ttH_SMEFTsim_topU3l"])
# rule all:
#  input:
#    expand("results/equations/{proc}.common.json", proc=["H_eemm_SMEFTsim_topU3l", "H_ttmm_SMEFTsim_topU3l", "H_llll_test_SMEFTsim_topU3l"]),
#    expand("results/equations/{proc}.json", proc=["H_eemm_SMEFTsim_topU3l", "H_ttmm_SMEFTsim_topU3l", "H_llll_test_SMEFTsim_topU3l"]),
#    expand("results/equations/{proc}.CMS.json", proc=["H_eemm_SMEFTsim_topU3l", "H_ttmm_SMEFTsim_topU3l", "H_llll_test_SMEFTsim_topU3l"])
rule all:
 input:
   expand("results/equations/{proc}.common.json", proc=["H_eemm_SMEFTsim_topU3l"]),
   expand("results/equations/{proc}.json", proc=["H_eemm_SMEFTsim_topU3l"]),
   expand("results/equations/{proc}.CMS.json", proc=["H_eemm_SMEFTsim_topU3l"])
# rule all:
#   input:
#     expand("results/equations/{proc}.common.json", proc=["WH_lep_SMEFTsim_topU3l", "ZH_lep_SMEFTsim_topU3l"])
# rule all:
#   input:
#     expand("results/equations/{proc}.common.json", proc=["WH_lep_SMEFTsim_topU3l"])

def get_copy_cards_sed_line(wildcards):
  if wildcards.version == "1":
    return f"sed -i 's/NP=0/NP<=1/g' results/cards/{wildcards.proc}.{wildcards.version}/proc_card.dat"
  if wildcards.version == "2":
    return f"sed -i 's/NPprop=0/NPprop<=2/g' results/cards/{wildcards.proc}.{wildcards.version}/proc_card.dat"
  else:
    return ""

rule copy_cards:
  input:
    expand("cards/{{proc}}/{card}_card.dat", card=["proc", "pythia8", "run"])
  output:
    expand("results/cards/{{proc}}.{{version}}/{card}_card.dat", card=["proc", "pythia8", "run"])
  params:
    sed_line = get_copy_cards_sed_line
  shell:
    """
    ls results/cards
    cp cards/{wildcards.proc}/* results/cards/{wildcards.proc}.{wildcards.version}/
    sed -i 's/{wildcards.proc}/{wildcards.proc}.{wildcards.version}/g' results/cards/{wildcards.proc}.{wildcards.version}/proc_card.dat
    {params.sed_line}
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
    "results/cards/{proc}.{version}/proc_card.dat",
    "results/cards/restrict_cards/copied"
  output:
    "results/process_output/{proc}.{version}.tar.gz",
  resources:
    runtime=10
  shell:
    """
    set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; popd
    ./EFT2Obs/scripts/setup_model_for_proc.sh {wildcards.proc}.{wildcards.version}
    
    rm -rf ${{PROC_DIR}}/{wildcards.proc}.{wildcards.version}
    ./EFT2Obs/scripts/setup_process.sh {wildcards.proc}.{wildcards.version}
    
    pushd ${{PROC_DIR}} ; set -e ; tar -czf {wildcards.proc}.{wildcards.version}.tar.gz {wildcards.proc}.{wildcards.version} ; set +e ; rm -r {wildcards.proc}.{wildcards.version} ; popd
    """

rule auto_detect:
  input:
    "results/process_output/{proc}.{version}.tar.gz"
  output:
    "results/cards/{proc}.{version}/reweight_card.dat",
    "results/cards/{proc}.{version}/config.json"
  shell:
    """
    set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; popd
    pushd ${{PROC_DIR}} ; rm -rf {wildcards.proc}.{wildcards.version} ; tar -xf {wildcards.proc}.{wildcards.version}.tar.gz ; popd
    ./EFT2Obs/scripts/setup_model_for_proc.sh {wildcards.proc}.{wildcards.version}
    ./EFT2Obs/scripts/auto_detect_operators.py -p {wildcards.proc}.{wildcards.version} --noValidation --def-val 1.0
    rm -r ${{PROC_DIR}}/{wildcards.proc}.{wildcards.version}
    """

rule setup_SM_gen:
  input:
    "results/process_output/{proc}.0.tar.gz",
    expand("results/cards/{{proc}}.{{version}}/{card}_card.dat", card=["param", "proc", "pythia8", "reweight", "run"])
  output:
    "results/process_output/{proc}.{version}.SM_gen.tar.gz",
    expand("results/cards/{{proc}}.{{version}}.SM_gen/{card}_card.dat", card=["param", "proc", "pythia8", "reweight", "run"])
  shell:
    """
    tmpdir=$(mktemp -d -p results/process_output/)
    tar -xf results/process_output/{wildcards.proc}.0.tar.gz -C $tmpdir
    pushd $tmpdir
      mv {wildcards.proc}.0 {wildcards.proc}.{wildcards.version}.SM_gen
      set -e ; tar -czf {wildcards.proc}.{wildcards.version}.SM_gen.tar.gz {wildcards.proc}.{wildcards.version}.SM_gen ; set +e
      mv {wildcards.proc}.{wildcards.version}.SM_gen.tar.gz ../
    popd
    rm -r $tmpdir

    cp results/cards/{wildcards.proc}.{wildcards.version}/* results/cards/{wildcards.proc}.{wildcards.version}.SM_gen/
    ./EFT2Obs/scripts/proc_lines_to_reweight_lines.py results/cards/{wildcards.proc}.{wildcards.version}.SM_gen/proc_card.dat results/cards/{wildcards.proc}.{wildcards.version}.SM_gen/reweight_card.dat
    """
  
rule make_param_card:
  input:
    "results/cards/{proc}.{version}/config.json",
    "results/process_output/{proc}.{version}.tar.gz"
  output:
    "results/cards/{proc}.{version}/param_card.dat"
  shell:
    """
    set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; popd
    pushd ${{PROC_DIR}} ; rm -rf {wildcards.proc}.{wildcards.version} ; tar -xf {wildcards.proc}.{wildcards.version}.tar.gz ; popd
    ./EFT2Obs/scripts/make_param_card.py -p {wildcards.proc}.{wildcards.version} -c results/cards/{wildcards.proc}.{wildcards.version}/config.json -o results/cards/{wildcards.proc}.{wildcards.version}/param_card.dat
    rm -r ${{PROC_DIR}}/{wildcards.proc}.{wildcards.version}
    """

rule make_gridpack:
  input:
    "results/process_output/{proc}.{version}.SM_gen.tar.gz",
    expand("results/cards/{{proc}}.{{version}}.SM_gen/{card}_card.dat", card=["param", "pythia8", "reweight", "run"])
  output:
    "results/process_output/gridpack_{proc}.{version}.SM_gen.tar.gz"
  resources:
    runtime = lambda wc: config[wc.proc]["make_gridpack_runtime"],
  threads:
    lambda wc: config[wc.proc]["make_gridpack_threads"]
  shell:
    """
    set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; popd
    pushd ${{PROC_DIR}} ; rm -rf {wildcards.proc}.{wildcards.version}.SM_gen ; tar -xf {wildcards.proc}.{wildcards.version}.SM_gen.tar.gz ; popd
    ./EFT2Obs/scripts/setup_model_for_proc.sh {wildcards.proc}.{wildcards.version}.SM_gen
    ./EFT2Obs/scripts/make_gridpack.sh {wildcards.proc}.{wildcards.version}.SM_gen 0 {threads}
    rm -r ${{PROC_DIR}}/{wildcards.proc}.{wildcards.version}.SM_gen
    """

def getruntime(wildcards):
  import numpy as np
  import json

  n_events = config[wildcards.proc]["nevents"]
  with open(f"results/cards/{wildcards.proc}.{wildcards.version}/config.json") as f:
    param_config = json.load(f)
  n_param = len(param_config["parameters"]) 
  n_rw = int(2*n_param + n_param*(n_param-1)/2)

  n = [100, 500, 1000, 5000]
  p1 = [0.23362387, 0.44109408, 1.24349909, 1.96356422]
  p2 = [0.00011418, 0.00114819, 0.00371878, 0.00988041]
  p1n = np.interp(n_events, n, p1)
  p2n = np.interp(n_events, n, p2)

  cum_time = (p1n * n_rw + p2n * n_rw**2) / 60 # in miuntes
  
  runtime = 10 + cum_time * 1.5
  return runtime

rule run_rwpoint_direct:
  input:
    "results/process_output/{proc}.{version}.tar.gz",
    expand("results/cards/{{proc}}.{{version}}/{card}_card.dat", card=["param", "pythia8", "reweight", "run"])
  output:
    "results/direct/{proc}.{version}.{rwpoint}.txt"
  threads:
    lambda wc: config[wc.proc]["make_gridpack_threads"]
  shell:
    """
      set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; popd

      if [[ -z ${{_CONDOR_SCRATCH_DIR}} ]] ; then
        tmpdir=$(mktemp -d -p $(pwd)/results/process_output )
      else
        tmpdir=$(mktemp -d -p /tmp )
      fi
      tar -xf {input[0]} -C $tmpdir

      cp results/cards/{wildcards.proc}.{wildcards.version}/*.dat ${{tmpdir}}/{wildcards.proc}.{wildcards.version}/Cards/
      
      setters=$(EFT2Obs/scripts/extract_setters.py ${{tmpdir}}/{wildcards.proc}.{wildcards.version}/Cards/reweight_card.dat {wildcards.rwpoint} )

      pushd ${{tmpdir}}/{wildcards.proc}.{wildcards.version}
        {{
          echo "shower=OFF"
          echo "reweight=OFF"
          echo "done"
          echo "set gridpack False"
          echo "set nevents 100000"
          echo $setters
          echo "done"
        }} > mgrunscript
        ./bin/generate_events pilotrun --nb_core={threads} < mgrunscript > generate_events.log
      popd

      cp ${{tmpdir}}/{wildcards.proc}.{wildcards.version}/generate_events.log {output}
      rm -r $tmpdir
    """

rule collect_direct:
  input:
    expand("results/direct/{{proc}}.{{version}}.{rwpoint}.txt", rwpoint=lambda wc: config[wc.proc]["rwpoints"])
  output:
    "results/direct/{proc}.{version}.json"
  run:
    import json
    summary = {}
    for f in input:
      with open(f) as f:
        log = f.read()
      rwpoint = f.name.split(".")[-2]
      
      results = log.split("=== Results Summary for run: pilotrun tag: tag_1 ===")[-1].split("Nb of events")[0]
      results = results.strip("\n")
      print(results)
      num = float(results.split(":")[1].split(" +- ")[0])
      uncert = float(results.split(":")[1].split(" +- ")[1].split(" ")[0])
      summary[rwpoint] = [num, uncert]

    with open(output[0], "w") as f:
      json.dump(summary, f, indent=2)

rule run_gridpack_yoda:
  input:
    "results/process_output/gridpack_{proc}.{version}.SM_gen.tar.gz"
  output:
    "results/yoda/{proc}/{version}/Rivet_{seed}.yoda.gz"
  params:
    prodmode =    lambda wc: config[wc.proc]["prodmode"],
    nevents =    lambda wc: config[wc.proc]["nevents"],
    rivet =      lambda wc: config[wc.proc]["rivet"],
  resources:
    runtime=getruntime,
    mem_mb=8000
  shell:
    """
    set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; popd
    export HIGGSPRODMODE={params.prodmode}

    if [[ -z ${{_CONDOR_SCRATCH_DIR}} ]] ; then
      tmpdir=$(mktemp -d -p $(pwd)/results/process_output )
    else
      tmpdir=$(mktemp -d -p /tmp )
    fi
    tar -xf {input} -C $tmpdir
    pushd $tmpdir
      mkdir -p madevent/Events/GridRun
      ./run.sh {params.nevents} {wildcards.seed}
      mv events.lhe.gz madevent/Events/GridRun/unweighted_events.lhe.gz
      
      cd madevent
      echo "0" | ./bin/madevent reweight GridRun

      echo "pythia8" > mgrunscript
      echo "set HEPMCoutput:file $tmpdir/events.hepmc" >> mgrunscript
      ./bin/madevent shower GridRun < mgrunscript
    popd

    cp EFT2Obs/RivetPlugins/HiggsTemplateCrossSectionsLess.cc /eft2obs/RivetPlugins/HiggsTemplateCrossSectionsLess.cc
    pushd /eft2obs ; ./setup/setup_rivet_plugins.sh ; popd
    rivet --analysis={params.rivet} $tmpdir/events.hepmc -o {output}
    rm -r $tmpdir
    """

rule run_gridpack_lhe:
  input:
    "results/process_output/gridpack_{proc}.{version}.SM_gen.tar.gz"
  output:
    "results/lhe/{proc}/{version}/events_{seed}.lhe.gz"
  params:
    nevents =    lambda wc: config[wc.proc]["nevents"],
  resources:
    runtime=getruntime,
    mem_mb=8000
  shell:
    """
    set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; popd

    if [[ -z ${{_CONDOR_SCRATCH_DIR}} ]] ; then
      tmpdir=$(mktemp -d -p $(pwd)/results/process_output )
    else
      tmpdir=$(mktemp -d -p /tmp )
    fi
    tar -xf {input} -C $tmpdir
    pushd $tmpdir
      mkdir -p madevent/Events/GridRun
      ./run.sh {params.nevents} {wildcards.seed}
      mv events.lhe.gz madevent/Events/GridRun/unweighted_events.lhe.gz
      
      cd madevent
      echo "0" | ./bin/madevent reweight GridRun
    popd
    mv ${{tmpdir}}/madevent/Events/GridRun/unweighted_events.lhe.gz {output}
    rm -r $tmpdir
    """

rule merge_yoda:
  input:
    expand("results/yoda/{{proc}}/{{version}}/Rivet_{i}.yoda.gz", i=lambda wc: range(config[wc.proc]["njobs"]))
  output:
    "results/yoda/{proc}/{version}/Rivet.yoda"
  shell:
    """
    set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; popd
    yodamerge -o {output} {input}
    """

rule merge_lhe:
  input:
    expand("results/lhe/{{proc}}/{{version}}/events_{i}.lhe.gz", i=lambda wc: range(config[wc.proc]["njobs"]))
  output:
    "results/lhe/{proc}/{version}/events.lhe"
  shell:
    """
    set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; popd
    ./EFT2Obs/scripts/lhe_merge.py {output} {input}
    """

rule get_scaling:
  input:
    branch(lookup(dpath="{proc}/lhe", within=config), 
    then = "results/lhe/{proc}/{version}/events.lhe",
    otherwise = "results/yoda/{proc}/{version}/Rivet.yoda")
  output:
    "results/equations/{proc}.{version}.json",
    "results/equations/{proc}.{version}.common.json"
  params:
    runset = lambda wildcards: config[wildcards.proc],
    extra_args = lambda wildcards: "--skip-square-terms --skip-cross-terms" if wildcards.version == 2 else ""
  shell:
    """
    set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; popd
    ./EFT2Obs/scripts/get_scaling.py -c results/cards/{wildcards.proc}.{wildcards.version}/config.json -i {input} --hist "/{params.runset[rivet]}/{params.runset[hist]}" --save common_json,json -o results/equations/{wildcards.proc}.{wildcards.version} --bin-labels EFT2Obs/resources/STXS_bin_labels.json --remove-empty-bins --skip-print {params.extra_args}
    """

rule add_versions:
  input:
    branch(lookup(dpath="{proc}/prop_corr", within=config), 
    then = expand("results/equations/{{proc}}.{version}.json", version=[1, 2]),
    otherwise = expand("results/equations/{{proc}}.{version}.json", version=[1]))
  output:
    "results/equations/{proc}.json"
  resources:
    runtime=30
  shell:
    """
    set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; popd
    ./EFT2Obs/scripts/add_scaling.py -i {input} -o {output}
    """
  
rule add_versions_common:
  input:
    branch(lookup(dpath="{proc}/prop_corr", within=config), 
    then = expand("results/equations/{{proc}}.{version}.json", version=[1, 2]),
    otherwise = expand("results/equations/{{proc}}.{version}.json", version=[1]))
  output:
    "results/equations/{proc}.common.json"
  resources:
    runtime=30
  shell:
    """
    set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; popd
    ./EFT2Obs/scripts/add_scaling.py -i {input} -o {output} --common
    """

rule add_versions_CMS:
  input:
    branch(lookup(dpath="{proc}/prop_corr", within=config), 
    then = expand("results/equations/{{proc}}.{version}.json", version=[1, 2]),
    otherwise = expand("results/equations/{{proc}}.{version}.json", version=[1]))
  output:
    "results/equations/{proc}.CMS.json"
  resources:
    runtime=30
  shell:
    """
    set +u ; pushd /eft2obs ; source /eft2obs/env.sh ; popd
    ./EFT2Obs/scripts/add_scaling.py -i {input} -o {output} --CMS
    """