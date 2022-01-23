import sys
import xarray as xr
import numpy as np

njord_path=sys.argv[1]
time_str=sys.argv[2]
time_str=time_str.replace('_','T')
time_obj=np.datetime64(time_str)

chg_file=njord_path+'/njord_rst_d01.nc.org'
d = xr.load_dataset(chg_file)
ocean_time =d['ocean_time']
d['ocean_time'].values[0]=time_obj
d.to_netcdf(njord_path+'/njord_rst_d01.nc','w')
