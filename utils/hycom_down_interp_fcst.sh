STRT_DATE_FULL=$1 #YYYY-MM-DD_HH
ROMS_DOMAIN_ROOT=$2
RA_ROOT=$3
FCST_DAYS=$4
DOWNLOAD=$5
INTERP=$6
BUFDAY=$7

TRY_TIME=5

# cd to the dir containing this shell
source ~/njord/bashrc_njord
cd "$(dirname "$0")"

# Set up paras derivatives 
STRT_DATE=${STRT_DATE_FULL:0:10}
INIT_HR=${STRT_DATE_FULL:11:2}
END_DATE=`date -d "$STRT_DATE +$FCST_DAYS days" "+%Y-%m-%d"`
STRT_DATE_PACK=${STRT_DATE//-/} # YYYYMMDD style

OCN_RA_ROOT=${RA_ROOT}/hycom_subset/${STRT_DATE_PACK}${INIT_HR}/
ICBC_ROOT=${RA_ROOT}/icbc/${STRT_DATE_PACK}${INIT_HR}/

# Constants
MFILE=gen_icbc_exp930.m

if [ ! -d "$OCN_RA_ROOT" ]; then
    mkdir $OCN_RA_ROOT
fi

if [ ! -d "$ICBC_ROOT" ]; then
    mkdir $ICBC_ROOT
fi

cd ../pre_driver/roms_drv

if [ $DOWNLOAD == 1 ]
then
    echo ">>>>ROMS: Fetch HYCOM from "${STRT_DATE_PACK}" +"${FCST_DAYS}" days..."
    # test if file prepared
  
    python3 down-hycom-exp930-fcst-subset.py ${STRT_DATE_PACK}${INIT_HR} $OCN_RA_ROOT $FCST_DAYS $BUFDAY

    NFILE=`ls -l ${OCN_RA_ROOT}/hycom_* | wc -l`	
    while [ $NFILE -le $FCST_DAYS ] 
    do
        TRY_TIME=`expr $TRY_TIME - 1`
        if [ $TRY_TIME -eq 0 ]
        then
            echo "ERROR: exceed maximum try times."
            exit
        fi
        echo "Warning: corrupted download, try again in 120s."
        sleep 120 
    	python3 down-hycom-exp930-fcst-subset.py ${STRT_DATE_PACK}${INIT_HR} $OCN_RA_ROOT $FCST_DAYS $BUFDAY
    	NFILE=`ls -l ${OCN_RA_ROOT}/hycom_* | wc -l`	
    done
 
fi


if [ $INTERP == 1 ]
then
    # test if file prepared
    NFILE=`ls -l ${OCN_RA_ROOT}/hycom_* | wc -l`
    if [ $NFILE -le $FCST_DAYS ] 
    then
        echo "ERROR: Not enough hycom file for interp, exit."
        exit
    fi
    # modify m script
    cp ./${MFILE}.temp ./${MFILE}
    MATLAB_DATE=${STRT_DATE//-/,}
    FCST_DAYS_COUNT=`expr $FCST_DAYS + 1`
    sed -i "s/%T1_placeholder/T1=datetime(${MATLAB_DATE},${INIT_HR},0,0);/" $MFILE
    sed -i "s/%numdays_placeholder/numdays=${FCST_DAYS_COUNT};/" $MFILE
    sed -i "s@%ocn_ra_placeholder@ocn_ra= '${OCN_RA_ROOT}';@" $MFILE 
    sed -i "s@%wdr_placeholder@wdr = '${ICBC_ROOT}';@g" $MFILE 
    sed -i "s@%roms_swan_grid_dir_placeholder@roms_swan_grid_dir = '${ROMS_DOMAIN_ROOT}';@g" $MFILE 

    echo ">>>>ROMS: Create ICBC..."
    # clean icbc root
    rm -f ${ICBC_ROOT}/*
    matlab -c /home/software/matlab2014b/crack/license.lic -nodesktop -nosplash -r gen_icbc_exp930
fi

