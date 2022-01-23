STRT_DATE=$1
END_DATE=$2
INIT_HR=$3
NJORD_ROOT=$4
ATM_RA_ROOT=$5
WPS_PATH=$6
WRF_PATH=$7
ATM_RA_RES=$8
FCST_DAYS=$9
TEST=${10}
DOWNLOAD=${11}

STRT_DATE_PACK=${STRT_DATE//-/} # YYYYMMDD style
END_DATE_PACK=${END_DATE//-/}

echo $WPS_PATH

cd wrf_drv/
GFS_DIR=${ATM_RA_ROOT}/${STRT_DATE_PACK}${INIT_HR}

if [ ! -d "$GFS_DIR" ]; then
    mkdir $GFS_DIR
fi

if [ $TEST == 0 ] && [ $DOWNLOAD == 1 ]
then
    echo ">>>>WRF: Fetch GFS from "${STRT_DATE_PACK}${INIT_HR}"Z to "${END_DATE_PACK}${INIT_HR}"Z... $FCST_DAYS @ $ATM_RA_RES to $ATM_RA_ROOT"
    #/home/pathsys/bin/copy_envf_gfs_realtime  ${STRT_DATE_PACK}${INIT_HR} $ATM_RA_RES $FCST_DAYS $ATM_RA_ROOT
    sh gfs_slicer.sh $GFS_DIR ${STRT_DATE_PACK}${INIT_HR} $FCST_DAYS
fi

sh auto_wps_gfs_realtime.sh $STRT_DATE $END_DATE $INIT_HR $GFS_DIR $WPS_PATH

sh run_real.sh $STRT_DATE_PACK $END_DATE_PACK $WRF_PATH $WPS_PATH $TEST

ln -sf $WRF_PATH/wrflow* $NJORD_ROOT
ln -sf $WRF_PATH/wrffdda* $NJORD_ROOT
ln -sf $WRF_PATH/wrfinput* $NJORD_ROOT
ln -sf $WRF_PATH/wrfbdy* $NJORD_ROOT
cp $WRF_PATH/namelist.input $NJORD_ROOT
