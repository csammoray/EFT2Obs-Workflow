import json

#DECAY_PROCS = ["Z_ll", "Z_qq", "Z_vv", "H_aa", "H_bb", "H_cc", "H_gg", 
#               "H_tautau", "H_WW", "H_Za", "H_ZZ", "H_mumu", "H_llll",
#               "H_llnunu", "H_lnuqq",  "H_nunuqq", "H_qqqq"]
DECAY_PROCS = ["Z_ll", "Z_qq", "Z_vv", "H_aa", "H_bb", "H_cc", "H_gg", 
              "H_tautau", "H_WW", "H_Za", "H_ZZ", "H_mumu", "H_llll",
              "H_llnunu", "H_lnuqq",  "H_nunuqq"]
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

prod_modes = {
  "bbH_SMEFTsim_topU3l": "BBH",
  "qqH_SMEFTsim_topU3l": "VBF",
  "tHq_SMEFTsim_topU3l": "TH",
  "tHW_SMEFTsim_topU3l": "TH",
  "ttH_SMEFTsim_topU3l": "TTH",
  "WH_lep_SMEFTsim_topU3l": "WH",
  "ZH_lep_SMEFTsim_topU3l": "QQ2ZH"
}

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
    pc[proc]["njobs"] = 2
  else:
    pc[proc]["make_gridpack_runtime"] = 600
    pc[proc]["make_gridpack_threads"] = 8
    pc[proc]["nevents"] = 100
    pc[proc]["njobs"] = 2

for proc in list(pc.keys()):
  pc[proc.replace("_SMEFTsim_topU3l", "_prop_SMEFTsim_topU3l")] = pc[proc]

with open("config.json", "w") as f:
  json.dump(pc, f, indent=4)