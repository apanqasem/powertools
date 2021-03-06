/*
 * file: README
 * 
 * author: Apan Qasem 
 *         apan@txstate.edu
 */ 



Contents of this directory 
-------------------------

README		this file 
getpower.sh 	driver script
models		R-based models for power estimation (see README in model/ for details)           
data   		sample data sets for training and testing models 



Build and Intsall Instructions
------------------------------

The power estimation models require R (and Rscript) to be installed on the
system. If you don't have R installed and in your path, install R before using
powertools. 

To build and install powertools 

   - untar the archive
   - cd into the powertools directory 
   - type 
         ./configure 
         
    - add powertools/bin to your PATH or copy powertools/bin/getpower.sh to a
      preferred location 



Using powertools
----------------

getpower.sh is the main driver script. This should be placed in a directory in
your PATH. Type "getpower.sh --help" for details on usage.  


Examples 
--------

To estimate processor power consumption on Intel with the ANN model, type 

      getpower.sh PWRTOOLS/models ann --predict test.dat

where 
  - PWRTOOLS is the install location of powertools 
  - test.dat is the input file with space-seperated values for the following six counters
       - "UNHALTED_CLK_CYCLES"
       - "INSTR_RETIRED_ANY"
       - "UOPS_RETIRED_ALL",
       - "BR_INST_RETIRED_ALL_BRANCHES"
       - "BR_INST_RETIRED_CONDITIONAL"
       - "L2_RQSTS_MISS"









  
