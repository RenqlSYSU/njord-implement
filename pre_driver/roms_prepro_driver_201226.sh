STRT_DATE=$1
END_DATE=$2
NJORD_ROOT=$3
RA_ROOT=$4
INIT_HR=$5
FCST_DAYS=$6
TEST=$7
DOWNLOAD=$8
BUFFER_DAY=$9

MFILE=gen_icbc_fcst_exp930.m

OCN_RA_ROOT=${RA_ROOT}/hycom_subset/
ICBC_ROOT=${RA_ROOT}/icbc/
ROMS_DOMAIN_ROOT=${NJORD_ROOT}/Projects/Njord/roms_swan_grid/

if [ ! -d "$OCN_RA_ROOT" ]; then
    mkdir $OCN_RA_ROOT
fi


STRT_DATE_PACK=${STRT_DATE//-/} # YYYYMMDD style
END_DATE_PACK=${END_DATE//-/}

echo ">>>>ROMS: Fetch HYCOM from "${STRT_DATE_PACK}" to "${END_DATE_PACK}"..."
cd ./roms_drv

#rm -f $OCN_RA_ROOT/*
if [ $TEST == 0 ] && [ $DOWNLOAD == 1 ]
then
    python down-hycom-exp930-fcst-subset.py ${STRT_DATE_PACK}${INIT_HR} $OCN_RA_ROOT $FCST_DAYS $BUFFER_DAY
fi

echo ">>>>ROMS: Create ICBC..."
cp ./template/${MFILE}.temp ./${MFILE}
MATLAB_DATE=${STRT_DATE//-/,}
FCST_DAYS_COUNT=`expr $FCST_DAYS + 1`
#sed -i "/T1 = /c\T1 = datetime(${MATLAB_DATE},${INIT_HR},0,0);" gen_icbc_fcst_exp930.m
#sed -i "/numdays = /c\numdays = ${FCST_DAYS};" gen_icbc_fcst_exp930.m
sed -i "s/%T1_placeholder/T1=datetime(${MATLAB_DATE},${INIT_HR},0,0);/" $MFILE
sed -i "s/%numdays_placeholder/numdays=${FCST_DAYS_COUNT};/" $MFILE
sed -i "s@%url_placeholder@url = '${OCN_RA_ROOT}';@" $MFILE 
sed -i "s@%wdr_placeholder@wdr = '${ICBC_ROOT}';@g" $MFILE 
sed -i "s@%roms_swan_grid_dir_placeholder@roms_swan_grid_dir = '${ROMS_DOMAIN_ROOT}';@g" $MFILE 

if [ $TEST == 0 ]
then
    # clean icbc root
    rm -f ${ICBC_ROOT}/*.nc
    /usr/local/bin/matlab -nodesktop -nosplash -r gen_icbc_fcst_exp930
fi
cd ..

