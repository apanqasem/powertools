#!/bin/sh

DEBUG=0

# driver script for R-based power estimation model
# supported models regression and ANN

if [ $# -lt 5 ]; then
  echo 'Usage:'
  echo '  path_to_models [ann|regr] [amd|intel] --dataset [filename] --testset(opt.) [filename]'
  echo '  path_to_models [ann|regr] [amd|intel] --predict [filename]'
  exit
fi

# PROCESS THE COMMAND LINE ARGUMENTS.

# process command-line arguments, make sure necessary files 
MODELPATH=$1
[ -d $MODELPATH -a -r $MODELPATH ] || { echo "model path does not exist or not readable \nexiting..."; exit; }

# Check the model selection. ANN or LIN. REG.?
if [ "$2" = "ann" ] || [ "$2" = "regr" ]; then 
    model=$2
else
    echo "error: unrecognized model $2; options are ann, regr."
    exit 0
fi

[ -r $MODELPATH/$model.r ] || { echo "error: could not find $model model \nexiting..."; exit; }


# Check the processor selection.
if [ "$3" = "amd" ] || [ "$3" = "intel" ]; then 
    proc=$3
else
    echo "error: unrecognized processor $3; options are amd, intel."
    exit 0
fi

# Check if user wants prediction or training.
if [ "$4" = "--predict" ]; then 
    pred=1
    if [ "$5" ]; then
        datafile="$5"
    else
        echo "error: no data file specified"
        exit 0
    fi
elif [ "$4" = "--dataset" ]; then
    pred=0
    if [ "$5" ]; then
        datafile="$5"
    else
        echo "error: no data file specified"
        exit 0
    fi
fi

# Check if user has provided a test set.
test=0
if [ "$6" = "--testset" ]; then
    if [ $pred = 1 ]; then
        echo "In prediction mode. Test set will not be used."
    else
        test=1
        if [ "$7" ]; then
            testfile="$7"
        else
            echo "error: no test file specified"
            exit 0
        fi
    fi
fi

# Just some debugging stuff.
if [ "$DEBUG" = 1 ]; then 
    echo "Model: $model.r"
    echo "Proc: $proc"
    echo "Pred: $pred"
    echo "Dataset: $datafile"
    echo "Test: $test"
    if [ $test = 1 ]; then
        echo "Testset: $testfile"
    fi
    exit 0
fi

# If test provided training or test set files are not found.
[ -r $datafile ] || { echo "could not file data file: $datafile \nexiting ..."; exit; }
if [ $test = 1 ]; then
    [ -r $testfile ] || { echo "could not file test file: $testfile \nexiting ..."; exit; }
fi

# Check if the R interpreter is installed.
R=`which Rscript`
[ $R ] || { echo  "R not installed, needed to run models\nexiting ...;"; exit; }


if [ $pred = 1 ]; then

    # If using for prediction, check to see that the model data exists.
    [ -r $MODELPATH/$model.mdl ] || { echo "error: could not find trained model data \nexiting..."; exit; }
    
    # Choose proper header to use.
    if [ $proc = "amd" ]; then  # Use Phenom header, no power column.
        echo "WK" "CPU_CLOCKS_UNHALTED" "INSTRUCTIONS_RETIRED" "UOPS_RETIRED" "DISPATCH_STALLS" "DISPATCHED_FAST_FPU" "BRANCH_MISPREDICT_RETIRED" > header
    elif [ $proc = "intel" ]; then  # Use Sandybridge header, no power column.
        echo "WK" "FP_COMP_OPS_EXE_X87" "BR_INST_RETIRED_ALL_BRANCHES" "BR_INST_RETIRED_CONDITIONAL" "BR_MISP_RETIRED_ALL_BRANCHES" "INSTR_RETIRED_ANY" "UOPS_RETIRED_ALL" "RESOURCE_STALLS_ANY" "INT_MISC_STALL_CYCLES" "L3_LAT_CACHE_MISS" "ICACHE_MISSES" "L2_RQSTS_MISS" "UNHALTED_CLK_CYCLES" > header
    fi
    
    cp ${MODELPATH}/$model.mdl .
    cat header $datafile > test.tmp
    # echo -n "Power (W)\t" 
    $R $MODELPATH/$model.r --m $proc --predict test.tmp # 2> /dev/null | grep "\[1,\]" | awk '{print $2}'

    # clean tmp files, copied model file 
    rm -rf header test.tmp $model.mdl
    
else
    # Train the model using the test set if available.
    if [ $test = 1 ]; then
        $R ${MODELPATH}/$model.r --m $proc --dataset $datafile --testset $testfile
    else
        $R ${MODELPATH}/$model.r --m $proc --dataset $datafile
    fi
    if [ $model.mdl ]; then
        cp $model.mdl ${MODELPATH}
        rm $model.mdl
    else
        echo "model was not created."
    fi
fi
