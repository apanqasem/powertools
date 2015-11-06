#!/bin/bash

if [ $# -lt 1 ]; then
  echo "usage :"
  echo "    $0 \"prog [ prog args ]\" [ file ]"
  echo "    file is output file for counter values (defaul : counters.dat)"
  echo ""
  exit
fi

execstr=$1

if [ "$2" ]; then
    outfile=$2
else
    outfile="counters.dat"
fi

# determine number of cores using nproc
NPROC=`which nproc`
[ $NPROC  ] || { echo  "could not determine number of cores\nexiting ...;"; exit; }

cores=`${NPROC}`
cores=$(($cores-1))

# extract arch info
model=`cat /proc/cpuinfo | grep -m 1 "model name" | awk -F ":" '{print $2}' | awk '{print $2}'`

if [ "${model}" = "Phenom(tm)" ]; then
    numcounters=6
    counters[0]="r0076"  # CPU_CLOCKS_UNHALTED
    counters[1]="r00C0"  # INSTRUCTIONS_RETIRED
    counters[2]="r00C1"  # UOPS_RETIRED
    counters[3]="r00D1"   # DISPATCH_STALLS		
    counters[4]="r0002"   # DISPATCHED_FAST_FPU         
    counters[5]="r00C3"   # BRANCH_MISPREDICT_RETIRED
fi

if [ "${model}" = "Xeon(R)" ]; then
    numcounters=12
    counters[0]=r0110 # FP_COMP_OPS_EXE_X87:PMC0
    counters[1]=r00c4 
    counters[2]=r01c4
    counters[3]=r00c5
    counters[4]=r00c0
    counters[5]=r01c2
    counters[6]=r01A2
    counters[7]=r400D
    counters[8]=r412E
    counters[9]=r0280
    counters[10]=rAA24 # L2_RQSTS_MISS
    counters[11]=cycles
fi
if  [ "${model}" = "Core(TM)2" ]; then 
    numcounters=6
    counters[0]=cycles 
    counters[1]=instructions 
    counters[2]=r0fc2 # uops_retired 
    counters[3]=r00c4 # br_inst_retired_any
    counters[4]=r00c5 # BR_INST_RETIRED_MISPRED 
    counters[5]=rff2e # L2_RQSTS_ALL_CORES_ALL_MESI
fi


# remove old counters file 
if [ -r ${outfile} ]; then
    rm -rf ${outfile}
fi

# always normalize 
normalize=1
 # scale counters to 8 seconds
normscale=8 

if [ "${model}" = "Phenom(tm)" ]; then
    fts=`perf stat -a -e ${counters[0]},${counters[1]},${counters[2]} -x " " --log-fd 1 $execstr | grep -E "${counters[0]}|${counters[1]}|${counters[2]}" | awk '{printf $1 "\t"}' | awk '{print}'`

    # this is test instance : don't need power, use dummy variable
    power=16
    # CPU_CLK
    val[0]=`echo -n ${fts} | awk '{print $1}'`
    # INSTR_RETIRED
    val[1]=`echo -n ${fts} | awk '{print $2}'`
    # UOPS_RETIRED
    val[2]=`echo -n ${fts} | awk '{print $3}'`

    fts=`perf stat -a -e ${counters[3]},${counters[4]},${counters[5]} -x " " --log-fd 1 $execstr | grep -E "${counters[3]}|${counters[4]}|${counters[5]}" | awk '{printf $1 "\t"}' | awk '{print}'`

    # DISPATCH_STALLS		
    val[3]=`echo -n ${fts} | awk '{print $1}'`
    # DISPATCHED_FAST_FPU         
    val[4]=`echo -n ${fts} | awk '{print $2}'`
    # BRANCH_MISPREDICT_RETIRED
    val[5]=`echo -n ${fts} | awk '{print $3}'`

    runtime=`(time $execstr) 2>&1 | grep -E "real|user" | awk '{print $2}' | \
         sed 's/m/ /' | sed 's/s//' |\
         awk '{printf "%3.2f\t", ($1 * 60 + $2)}'`
    runtime=`echo -n ${runtime} | awk '{print $1}'`
    
fi
if [ "${model}" = "Xeon(R)" ]; then
    
    fts=`perf stat -e ${counters[0]},${counters[1]},${counters[2]},${counters[3]},${counters[4]} -x " " --log-fd 1 $execstr | grep -E "${counters[0]}|${counters[1]}|${counters[2]}|${counters[3]}|${counters[4]}" | awk '{printf $1 "\t"}' | awk '{print}'`

    # this is test instance : don't need power, use dummy variable
    power=16
    # CPU_CLK
    val[0]=`echo -n ${fts} | awk '{print $1}'`
    # INSTR_RETIRED
    val[1]=`echo -n ${fts} | awk '{print $2}'`
    # UOPS_RETIRED
    val[2]=`echo -n ${fts} | awk '{print $3}'`
    val[3]=`echo -n ${fts} | awk '{print $4}'`
    val[4]=`echo -n ${fts} | awk '{print $5}'`

    fts=`perf stat -a -e ${counters[5]},${counters[6]},${counters[7]},${counters[8]} -x " " --log-fd 1 $execstr | grep -E "${counters[5]}|${counters[6]}|${counters[7]}|${counters[8]}" | awk '{printf $1 "\t"}' | awk '{print}'`

    val[5]=`echo -n ${fts} | awk '{print $1}'`

    val[6]=`echo -n ${fts} | awk '{print $2}'`
    # DISPATCH_STALLS		
    val[7]=`echo -n ${fts} | awk '{print $3}'`
    # DISPATCHED_FAST_FPU         
    val[8]=`echo -n ${fts} | awk '{print $4}'`
    # BRANCH_MISPREDICT_RETIRED

  fts=`perf stat -a -e ${counters[5]},${counters[9]},${counters[10]},${counters[11]} -x " " --log-fd 1 $execstr | grep -E "${counters[5]}|${counters[9]}|${counters[10]}|${counters[11]}" | awk '{printf $1 "\t"}' | awk '{print}'`

  val[9]=`echo -n ${fts} | awk '{print $1}'`
  val[10]=`echo -n ${fts} | awk '{print $2}'`
  val[11]=`echo -n ${fts} | awk '{print $3}'`

   runtime=`(time $execstr) 2>&1 | grep -E "real|user" | awk '{print $2}' | \
         sed 's/m/ /' | sed 's/s//' |\
         awk '{printf "%3.2f\t", ($1 * 60 + $2)}'`

   runtime=`echo -n ${runtime} | awk '{print $1}'`
fi


if  [ "${model}" = "Core(TM)2" ]; then 

    # power, don't have counters, set dummy value 
    power=16
    
    fts=`perf stat -e ${counters[0]},${counters[1]},${counters[2]},${counters[3]} -x " " --log-fd 1 $execstr | grep -E "${counters[0]}|${counters[1]}|${counters[2]}|${counters[3]}" | awk '{printf $1 "\t"}' | awk '{print}'`

    # CPU_CLK
    val[0]=`echo -n ${fts} | awk '{print $1}'`
    # INSTR_RETIRED
    val[1]=`echo -n ${fts} | awk '{print $2}'`
    # UOPS_RETIRED
    val[2]=`echo -n ${fts} | awk '{print $3}'`

    fts=`perf stat -e ${counters[3]} -x " " --log-fd 1 $execstr | grep -E "${counters[3]}" | awk '{printf $1 "\t"}' | awk '{print}'`

     val[3]=`echo -n ${fts} | awk '{print $1}'`

    fts=`perf stat -e ${counters[4]},${counters[5]} -x " " --log-fd 1 $execstr | grep -E "${counters[4]}|${counters[5]}" | awk '{printf $1 "\t"}' | awk '{print}'`

    val[4]=`echo -n ${fts} | awk '{print $1}'`
    val[5]=`echo -n ${fts} | awk '{print $2}'`

    runtime=`(time $execstr) 2>&1 | grep -E "real|user" | awk '{print $2}' | \
         sed 's/m/ /' | sed 's/s//' |\
         awk '{printf "%3.2f\t", ($1 * 60 + $2)}'`
    
    runtime=`echo -n ${runtime} | awk '{print $1}'`
fi

#
# normalize counter values and dump to file 
#

# models trained with counter values collected at interval k
# test data must be scaled to same interval 
echo -n $power " ">> ${outfile}
if [ $DEBUG ]; then 
    echo ${val[@]}
fi

if [ $runtime = 0.00 ]; then
    runtime=0.01
fi

if [ $normalize -eq 1 ]; then
    i=0;
    while [ $i -lt ${numcounters} ]; do
        val=${val[$i]}
        val[$i]=`echo "scale = 2; $val / ${runtime} * ${normscale} " | bc`
        echo -n ${val[$i]} " " >> ${outfile} 
        i=$(($i+1))
    done
    
    echo " " >> ${outfile}
fi


