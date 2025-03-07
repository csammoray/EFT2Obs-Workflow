import json

DECAY_PROCS = ["H_aa", "H_bb", "H_cc", "H_gg", 
#               "Z_ll", "Z_qq", "Z_vv",
              "H_tautau", "H_Za", "H_mumu", "H_llll",
              "H_llnunu", "H_lnuqq",  "H_nunuqq", "H_qqqq"]
DECAY_PROCS = ["%s_SMEFTsim_topU3l"%proc for proc in DECAY_PROCS]

decay_pc = {
  proc: {
    "rivet": "inclusive",
    "hist": "myh1",
    "prodmode": "",
    "extra_opts": "--rivet-ignore-beams"
  } for proc in DECAY_PROCS
}

PROD_PROCS = ["tHq", "tHW", "ttH", "WH_lep", "ZH_lep", "bbH", "qqH"]
PROD_PROCS = ["%s_SMEFTsim_topU3l"%proc for proc in PROD_PROCS]

#PROD_PROCS += [f"{proc}_ATLAS" for proc in PROD_PROCS]

prod_modes = {
  "bbH_SMEFTsim_topU3l": "BBH",
  "qqH_SMEFTsim_topU3l": "VBF",
  "tHq_SMEFTsim_topU3l": "TH",
  "tHW_SMEFTsim_topU3l": "TH",
  "ttH_SMEFTsim_topU3l": "TTH",
  "WH_lep_SMEFTsim_topU3l": "WH",
  "ZH_lep_SMEFTsim_topU3l": "QQ2ZH"
}
# for key in list(prod_modes.keys()):
#   prod_modes[f"{key}_ATLAS"] = prod_modes[key]

prod_pc = {
  proc: {
    "rivet": "HiggsTemplateCrossSectionsLess",
    "hist": "HTXS_stage1_2_pTjet30",
    "prodmode": prod_modes[proc],
    "extra_opts": ""
  } for proc in PROD_PROCS
}

ALL_PROCS = DECAY_PROCS + PROD_PROCS
pc = decay_pc | prod_pc

two_body_procs = ["Z_ll", "Z_qq", "Z_vv", "H_aa", "H_bb", "H_cc", "H_gg", 
               "H_tautau", "H_Za", "H_mumu"]
two_body_procs = ["%s_SMEFTsim_topU3l"%proc for proc in two_body_procs]

for proc in pc:
  if proc in two_body_procs:
    pc[proc]["make_gridpack_runtime"] = 10
    pc[proc]["make_gridpack_threads"] = 1
    pc[proc]["nevents"] = 10
    pc[proc]["njobs"] = 1
    pc[proc]["prop_corr"] = False
  else:
    pc[proc]["make_gridpack_runtime"] = 20
    pc[proc]["make_gridpack_threads"] = 4
    pc[proc]["nevents"] = 5000
    pc[proc]["njobs"] = 20
    pc[proc]["prop_corr"] = True

for proc in pc:
  pc[proc]["lhe"] = proc in decay_pc

with open("config.json", "w") as f:
  json.dump(pc, f, indent=4)