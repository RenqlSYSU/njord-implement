#/usr/bin/env python3
"""configuration funcs to get parameters from user"""
import os
import configparser

print_prefix='lib.cfgparser>>'

def read_cfg(config_file):
    """ Simply read the config files """
    config=configparser.ConfigParser()
    config.read(config_file)
    return config

def write_cfg(cfg_hdl, config_fn):
    """ Simply write the config files """
    with open(config_fn, 'w') as configfile:
        cfg_hdl.write(configfile)

def merge_cfg(cfg_org, cfg_tgt):
    """ merge the dynamic and static cfg """
    cfg_tgt['INPUT']=cfg_org['INPUT']
   
    return cfg_tgt

