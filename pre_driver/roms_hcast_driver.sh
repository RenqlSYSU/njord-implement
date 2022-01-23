NJORD_PROJ_PATH=$1
RA_ROOT=$2
STRT_DATE_FULL=$3
DT=$4
CASE_NAME=$5


FCST_DAYS=1

# Set up paras derivatives 
STRT_DATE=${STRT_DATE_FULL:0:10}
INIT_HR=${STRT_DATE_FULL:11:2}
END_DATE=`date -d "$STRT_DATE +$FCST_DAYS days" "+%Y-%m-%d"`

STRT_DATE_PACK=${STRT_DATE//-/} # YYYYMMDD style
END_DATE_PACK=${END_DATE//-/}

ROMS_DOMAIN_ROOT=${NJORD_PROJ_PATH}/roms_swan_grid/
ICBC_ROOT=${RA_ROOT}/icbc/${CASE_NAME}/

CLMFILE=Projects/Njord/ow_icbc/d01/coawst_clm_${STRT_DATE_PACK}.nc
BDYFILE=Projects/Njord/ow_icbc/d01/coawst_bdy_${STRT_DATE_PACK}.nc


NTIMES=`expr $FCST_DAYS \* 86400 / $DT `

echo ">>>>ROMS: run roms_hcast_driver.sh..."

# modify roms.in
ROMS_IN=$NJORD_PROJ_PATH/roms_d01.in
sed -i "s@NTIMES_placeholder@NTIMES == ${NTIMES}@" $ROMS_IN
sed -i "s@DT_placeholder@DT == ${DT}.0d0@" $ROMS_IN
sed -i "s@CLMNAME_placeholder@CLMNAME == ${CLMFILE}@" $ROMS_IN
sed -i "s@BRYNAME_placeholder@BRYNAME == ${BDYFILE}@" $ROMS_IN

# relink ROMS icbc
ICBC_LK=${NJORD_PROJ_PATH}/ow_icbc/d01
rm -f $ICBC_LK
ln -sf ${ICBC_ROOT} ${ICBC_LK}
