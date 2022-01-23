#!/bin/sh

source ~/.bash_profile
source ~/.bashrc_njord
cd /public1/home/cqair/pathop/njord/workspace/njord_pipeline/implement

python3 ./opfcst-spinup-sugon.py
python3 ./opfcst-req-hycom-sugon.py
