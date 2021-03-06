# This script servers as the top driver of the forecast run
# of the COAWST system. It calls a series of 
# component drivers to preprocess and to coordinate the coupled 
# system run.


date

# change folder
ABS_PATH=$0
ABS_PATH=${ABS_PATH%/*}
echo $ABS_PATH
cd $ABS_PATH 

# paras
WRF_PATH=$1
STRT_DATE_FULL=$2 #YYYY-MM-DD_HH
INIT_RUN_FLAG=$3
SPINUP_FLAG=$4
DOMAIN_GROUP=$5
NJORD_ROOT=$6
RA_ROOT=$7
ARCH_ROOT=$8
ROMS_DT=$9

## stream control flags
TEST_FLAG=0
if [ $SPINUP_FLAG == 1 ]; then
    ARCHIVE_FLAG=0
else
    ARCHIVE_FLAG=1
fi

## set basic constants
FCST_DAYS=1
CPL_IN=coupling.in

# Set up paras derivatives 
STRT_DATE=${STRT_DATE_FULL:0:10}
INIT_HR=${STRT_DATE_FULL:11:2}
END_DATE=`date -d "$STRT_DATE +$FCST_DAYS days" "+%Y-%m-%d"`

STRT_DATE_PACK=${STRT_DATE//-/} # YYYYMMDD style
END_DATE_PACK=${END_DATE//-/}


## Generate Paths
### Set ROMS for generating ICBC for ocn
NJORD_PROJ_PATH=${NJORD_ROOT}/Projects/Njord/
#ARCH_ROOT=${ARCH_ROOT}/${STRT_DATE_PACK}${INIT_HR}/

# Load-balancing Configurations for Processors Layer
if [ $SPINUP_FLAG == 1 ]; then
    NTASKS_ATM=16

    NTASKS_OCN=48
    N_ITAKS_OCN=6
    N_JTAKS_OCN=8

    NTASKS_WAV=16
else
    NTASKS_ATM=42

    NTASKS_OCN=27
    N_ITAKS_OCN=3
    N_JTAKS_OCN=9

    NTASKS_WAV=16
fi

NTASKS_ALL=`expr $NTASKS_ATM + $NTASKS_OCN + $NTASKS_WAV`
echo "TOTAL CPUS:"$NTASKS_ALL


# Preprocessing
echo ">>PREPROCESSING..."

# ----------cp files----------


#cp ./domaindb/${DOMAIN_GROUP}/scrip*.nc $NJORD_PROJ_PATH/roms_swan_grid/
if [ $INIT_RUN_FLAG == 1 -a $SPINUP_FLAG == 1 ]; then
    ## coupling file
    cp ./db/${DOMAIN_GROUP}/${CPL_IN} ${NJORD_PROJ_PATH}/${CPL_IN}
    
    ## atm file
    ln -sf $WRF_PATH/wrflow* $NJORD_ROOT
    ln -sf $WRF_PATH/wrffdda* $NJORD_ROOT
    ln -sf $WRF_PATH/wrfinput* $NJORD_ROOT
    ln -sf $WRF_PATH/wrfbdy* $NJORD_ROOT
    cp $WRF_PATH/namelist.input $NJORD_ROOT
    
    ## ocean file
    cp ./db/${DOMAIN_GROUP}/roms_d01.in $NJORD_PROJ_PATH
    cp ./domaindb/${DOMAIN_GROUP}/roms_d01_lp0d1.nc $NJORD_PROJ_PATH/roms_swan_grid/
    
    ## swan file
    cp ./db/${DOMAIN_GROUP}/swan_d01.in $NJORD_PROJ_PATH
    cp ./domaindb/${DOMAIN_GROUP}/swan_* $NJORD_PROJ_PATH/roms_swan_grid/
else
    if [ $INIT_RUN_FLAG == 1 ]; then
        ## coupling file
        cp ./db/${DOMAIN_GROUP}/${CPL_IN} ${NJORD_PROJ_PATH}/${CPL_IN}
        # fcst with wrf init, ROMS and SWAN from warm restart
        ## atm file
        ln -sf $WRF_PATH/wrflow* $NJORD_ROOT
        ln -sf $WRF_PATH/wrffdda* $NJORD_ROOT
        ln -sf $WRF_PATH/wrfinput* $NJORD_ROOT
        ln -sf $WRF_PATH/wrfbdy* $NJORD_ROOT
        cp $WRF_PATH/namelist.input $NJORD_ROOT
    fi
    # warm restart run for SWAN and ROMS
    # bug fix for roms time
    echo $NJORD_ROOT $STRT_DATE_FULL
    python roms_time_bug_patch.py $NJORD_ROOT $STRT_DATE_FULL
    cp ./db/${DOMAIN_GROUP}/roms_d01.in.hot $NJORD_PROJ_PATH/roms_d01.in
    cp ./db/${DOMAIN_GROUP}/swan_d01.in.hot $NJORD_PROJ_PATH/swan_d01.in    
fi

# ----------cp files----------
cd ./pre_driver
date
sh wrf_fcst_driver.sh $STRT_DATE_PACK $END_DATE_PACK $INIT_RUN_FLAG $NJORD_ROOT
sh roms_fcst_driver.sh $NJORD_PROJ_PATH $RA_ROOT $STRT_DATE_FULL $ROMS_DT $INIT_RUN_FLAG
sh swan_fcst_driver.sh  $STRT_DATE $END_DATE $INIT_HR $NJORD_PROJ_PATH 
date
cd ..

## Change Processors Layer
sed -i "/NnodesATM =/c\ \ \ NnodesATM = ${NTASKS_ATM}" ${NJORD_PROJ_PATH}/${CPL_IN}
sed -i "/NnodesWAV =/c\ \ \ NnodesWAV = ${NTASKS_WAV}" ${NJORD_PROJ_PATH}/${CPL_IN}
sed -i "/NnodesOCN =/c\ \ \ NnodesOCN = ${NTASKS_OCN}" ${NJORD_PROJ_PATH}/${CPL_IN}
sed -i "/NtileI ==/c\ \ \ NtileI == ${N_ITAKS_OCN}" ${NJORD_PROJ_PATH}/roms_d01.in
sed -i "/NtileJ ==/c\ \ \ NtileJ == ${N_JTAKS_OCN}" ${NJORD_PROJ_PATH}/roms_d01.in

# Run script
cd $NJORD_ROOT
# clean wrfout
rm -f wrfout*

cat << EOF > run.sh
#mpirun --hostfile ./mpihosts --rankfile ./mpirank -n 96 ./coawstM ./Projects/GBA/coupling_gba.in >& cwstv3.${TSTMP}.log
mpirun -np ${NTASKS_ALL} ./coawstM ./Projects/Njord/${CPL_IN} >& cwstv3.log
#mpirun -hostfile ./mpihosts -n 96 ./coawstM ./Projects/GBA/coupling_gba.in >& cwstv3.${TSTMP}.log
EOF

echo ">>Run COAWST..."
if [ ${TEST_FLAG} == 0 ]; then
    sh run.sh
fi
date

# prepare for bug fix
mv njord_rst_d01.nc njord_rst_d01.nc.org

# Archive
if [ ${ARCHIVE_FLAG} == 1 ]
then
    if [ ! -d "${ARCH_ROOT}" ]; then
        mkdir ${ARCH_ROOT}
    fi
    mv wrfout* $ARCH_ROOT/
    mv njord_his_d01.nc $ARCH_ROOT/njord_his_d01.${STRT_DATE_PACK}.nc
    mv hsig_d01.nc $ARCH_ROOT/hsig_d01.${STRT_DATE_PACK}.nc
    mv pdir_d01.nc $ARCH_ROOT/pdir_d01.${STRT_DATE_PACK}.nc
    mv tps_d01.nc $ARCH_ROOT/tps_d01.${STRT_DATE_PACK}.nc
    mv hswell_d01.nc $ARCH_ROOT/hswell_d01.${STRT_DATE_PACK}.nc
    mv wind_d01.nc $ARCH_ROOT/wind_d01.${STRT_DATE_PACK}.nc
    mv swan_spec_yangjiang.nc $ARCH_ROOT/swan_spec_yangjiang.${STRT_DATE_PACK}.nc
fi

# Postprocessing
