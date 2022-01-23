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
    cfg_hdl=lib.cfgparser.read_cfg(CWD+'/conf/config.fcst.spinup.ini')
    
    if (cfg_hdl['INPUT']['model_init_ts']== 'realtime'):
        today = datetime.datetime.today()
        today=today.replace(hour=12)
        # 1-day lead for spinup
        init_ts=today+datetime.timedelta(days=-1)
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
        args=args+'1'
        # run utils/hycom_down_interp.sh 
        os.system('sh '+CWD+'/utils/hycom_down_interp_fcst.sh '+args)
   
   # ----------------WRF PREPROCESS---------------
    if cfg_hdl['NJORD'].getboolean('run_wrf_driver'):
        cfg_smp=lib.cfgparser.read_cfg(CWD+'/wrf-top-driver/conf/config.njord.ini')
        
        cfg_smp['DOWNLOAD']['down_drv_data']=cfg_hdl['NJORD']['down_wrf_drv']
        
        # merge ctrler with cfg_hdl in njord_implement
        cfg_tgt=lib.cfgparser.merge_cfg(cfg_hdl, cfg_smp)

        # write ctrler
        lib.cfgparser.write_cfg(cfg_tgt, CWD+'/wrf-top-driver/conf/config.ini')
        
        # run wrf-top-driver
        os.system('cd wrf-top-driver; python top_driver.py')

   # ------------------NJORD LOOP-------------------
    curr_ts=init_ts
    # use resubmit tech for long runs to avoid large file/stability issues
    for iday in range(run_days):
        # 1
        args=cfg_hdl['INPUT']['wrf_root']+' '
        # 2
        args=args+curr_ts.strftime('%Y-%m-%d_%H')+' '
        # 3 init run flag
        if (iday==0):
            args=args+'1'+' ' # init run
        else:
            args=args+'0'+' '
        # 4 SPINUP_FLAG
        args=args+'1'+' '
        # 5 DOMAIN_GROUP
        args=args+cfg_hdl['INPUT']['nml_temp']+' '
        # 6 NJORD_ROOT
        args=args+cfg_hdl['NJORD']['njord_root']+' '
        # 7 RA_ROOT
        args=args+cfg_hdl['ROMS']['ra_root']+' '
        # 8 ARCH_ROOT
        args=args+'/placeholder/'+' '
        # 9 ROMS DT
        args=args+cfg_hdl['ROMS']['dt']+' '
        print(args) 
        # run hcast-ctl.sh
        os.system('sh '+CWD+'/fcst-ctl.sh '+args)
        curr_ts=init_ts+datetime.timedelta(days=iday+1)

if __name__ == '__main__':
    main_run()
