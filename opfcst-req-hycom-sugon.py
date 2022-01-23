#/usr/bin/env python3
'''
Date: Nov 20, 2021 

This is the top driver for njord forecast run 

Revision:
Nov 20, 2021 --- modify from hcast-run-single.py 

Zhenning LI
'''
import os, sys, logging.config
import datetime
import lib

CWD=sys.path[0]

def main_run():
    
    # controller config handler
    cfg_hdl=lib.cfgparser.read_cfg(CWD+'/conf/fcst.ini')
    
    if (cfg_hdl['INPUT']['model_init_ts']== 'realtime'):
        today = datetime.datetime.today()
        init_ts = today.replace(hour=12)
        cfg_hdl['INPUT']['model_init_ts']=init_ts.strftime('%Y%m%d%H')
    else:
        init_ts=datetime.datetime.strptime(
                cfg_hdl['INPUT']['model_init_ts'], '%Y%m%d%H')
       
    run_days=int(cfg_hdl['INPUT']['model_run_days'])
    roms_domain_root=CWD+'/domaindb/'+cfg_hdl['INPUT']['nml_temp']+'/'
    
    # -----------ROMS DOWNLOAD AND INTERP-----------
    if cfg_hdl['ROMS']['download_flag']=='1' or cfg_hdl['ROMS']['interp_flag']=='1':
        
        # 1 STRT_DATE_FULL
        args=init_ts.strftime('%Y-%m-%d_%H')+' '
        # 2 NJORD_ROOT
        args=args+roms_domain_root+' '
        # 3 RA_ROOT
        args=args+cfg_hdl['ROMS']['ra_root']+' '
        # 4 FCST_DAYS
        args=args+cfg_hdl['INPUT']['model_run_days']+' '
        # 5 DOWNLOAD
        args=args+cfg_hdl['ROMS']['download_flag']+' '
        # 6 INTERP
        args=args+cfg_hdl['ROMS']['interp_flag']+' '
        # 7 BUFDAY
        args=args+'2'
        # run utils/hycom_down_interp.sh 
        os.system('ssh smp2 sh '+CWD+'/utils/hycom_down_interp_fcst.sh '+args)

if __name__ == '__main__':
    main_run()
