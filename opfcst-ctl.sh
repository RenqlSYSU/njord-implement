# This script servers as the top driver of the operational
# forecast system of the COAWST system. It calls a series of 
# component drivers to preprocess and to coordinate the coupled 
# system run.

source ~/.bashrc
cd /home/lzhenn/array74/workspace/njord_pipeline/implement/
python fcst-run-single.py

