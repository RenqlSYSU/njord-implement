#!/bin/sh

source ~/njord/bashrc_njord
cd /home/pathop/njord/workspace/njord_pipeline/implement 

python3 ./opfcst-spinup-sugon.py
python3 ./opfcst-req-hycom-sugon.py
