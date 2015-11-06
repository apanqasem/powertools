#!/bin/bash

if [ $# -lt 1 ]; then
    echo "usage: "
    echo "      power.sh [OPTIONS] \"<command>\""
    echo " "
    echo "Options: "
    echo -e "        -m, --model\t specify estimato, valid options reg and ann"
    echo -e "        -v, --verbose\t verbose mode"
    exit 1
fi


while [ $# -gt 0 ]; do
    key="$1"
    case $key in
        -m|--model)
            model="$2"
            shift # option has parameter
            ;;
        -v|--verbose)
            verbose=true
            ;;
        *)
           # unknown option
           if [ "$execstr" = "" ]; then
               execstr=$1
           else
               echo Unknown option: $key
               exit 0
           fi
           ;;
    esac
    shift # option(s) fully processed, proceed to next input argument
done

[ "$model" ] || { model=regr; }
[ "$model" = "ann" ] || [ "$model" = "regr" ] || { echo "unknown model $model"; exit 0; }


[ `which get_evts_for_pwr_estimator.sh` ] || { echo "powertools not installed. Existing..."; exit 1; }
[ `which pwr_estimator.sh` ] || { echo "powertools not installed. Existing..."; exit 1; }

MODELPATH=~/tools/powertools/models
[ -r $MODELPATH/$model.mdl ] || { echo "model not found $MODELPATH/$model.mdl"; exit 0; }

ARCH=intel
OUTFILE=counters.dat

get_evts_for_pwr_estimator.sh "$execstr" 

pwr=`pwr_estimator.sh $MODELPATH $model $ARCH --predict $OUTFILE 2> /dev/null\
                       | grep "\[1" | awk '{print $2}'`

if [ "$verbose" ]; then 
    echo "Average power consumption: $pwr watts"
else
    echo "$pwr"
fi


# cleanup
rm -rf $OUTFILE

