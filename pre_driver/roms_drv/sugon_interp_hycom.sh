#!/bin/bash
#SBATCH -J hycom
#SBATCH --comment=FULL_COUPLE_NJORD_HYCOM
#SBATCH -n 1
#SBATCH --ntasks-per-node=64
#SBATCH -p xhacexclu01
#SBATCH -t 3:00:00
#SBATCH -o /public1/home/cqair/pathop/njord/workspace/njord_pipeline/implement/log/hycom.log 
#SBATCH -e /public1/home/cqair/pathop/njord/workspace/njord_pipeline/implement/log/hycom.log 
#SBATCH --exclusive

source ~/.bashrc_njord
matlab -nodesktop -nosplash -r gen_icbc_exp930

