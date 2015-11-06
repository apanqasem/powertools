# FOR PREDICTING CPU POWER WITH THE NEURAL NETWORK MODEL
# Author: Mario A. Gutierrez
# Last Revision: 3 March 2015

######################################################################

args = commandArgs(trailingOnly=TRUE) # Get command-line arguments.

if (length(args) == 0) {
   cat("Usage: ann.r --m [amd|intel] --dataset [filename] --testset(opt.) [filename]\n")
   cat("Usage: ann.r --m [amd|intel] --predict [filename]\n")
} else {

library(neuralnet)

filename = "data.dat"   # Default input data filename.
testset = ""            # Default testset filename.
modelname = "ann.mdl"   # Default model filename.
use_predict = FALSE     # Is this script being run for prediction?
removeOutlier = FALSE   # Fix problem with intel power collection.

# ANN training parameters
topo = c(5, 3)    # The network hidden layer topology.
errt = 0.00999    # Limit for training.

# Parse command-line arguments.
# --predict [filename]: use provided data for prediction.
# --dataset [filename]: use provided data for training.
# --testset [filename]: use provided data for error testing. 
# --m [amd|intel]: which performance counter names to use.
if (length(args) != 0) {

   if ("--predict" %in% args) {
      use_predict = TRUE
      filename = args[which(args == "--predict") + 1]
   } 
   
   if ("--dataset" %in% args) {
      use_predict = FALSE
      filename = args[which(args == "--dataset") + 1]
   }
   
   if ("--k" %in% args) {
      use_predict = FALSE
      k = strtoi(args[which(args == "--k") + 1], base=10)
   }
   
   if ("--testset" %in% args) {
      use_predict = FALSE
      testset = args[which(args == "--testset") + 1]
   }
   
   if ("--m" %in% args) {
      nm <- args[which(args == "--m") + 1]
      if (nm == "intel") {
         PERFNAMES <- c("UNHALTED_CLK_CYCLES", 
                        "INSTR_RETIRED_ANY",
                        "UOPS_RETIRED_ALL",
                        "RESOURCE_STALLS_ANY",
                        "FP_COMP_OPS_EXE_X87",
                        "BR_MISP_RETIRED_ALL_BRANCHES")
         removeOutlier = TRUE
      }
      else if (nm == "amd") {
         PERFNAMES <- c("CPU_CLOCKS_UNHALTED",
                        "INSTRUCTIONS_RETIRED",
                        "UOPS_RETIRED",
                        "DISPATCH_STALLS",
                        "DISPATCHED_FAST_FPU",
                        "BRANCH_MISPREDICT_RETIRED")
      }
   }
}

# Load data
cat("Loading file", filename)
data = read.table(filename, header=TRUE)

# Remove extreme outliers, and sleep data.
if ("POWER" %in% names(data) && removeOutlier == TRUE) {
   data <- data[data$POWER < 75, ]
   data <- data[data$POWER > 15, ]
}

cat("\n  ", nrow(data), "data samples loaded.\n")

# Do same for test data if available.
if (testset != "") {
   cat("Loading test data", testset)
   data.test = read.table(testset, header=TRUE)
   if ("POWER" %in% names(data) && removeOutlier == TRUE) {
      data.test = data.test[data.test$POWER < 75, ]
      data.test = data.test[data.test$POWER > 15, ]
   }
   cat("  ", nrow(data.test), "test data samples loaded.\n\n")
} else {
   cat("\n")
}

####################### NEURAL NETWORK ANALYSIS #####################

# Load maximum data value for normalization?
if (use_predict == TRUE) {
   load(modelname, envir=parent.frame())
} else {
   data.max = c(max(data$POWER), max(data))
}

# Normalize data.
if ("POWER" %in% names(data)) {
    # Normalization of power and perf. counter values done separately 
    # since the values are so drastically different.
    t = data$POWER / data.max[1]     # Normalize power values.
    data.norm = data / data.max[2]   # Normalize data values.
    data.norm$POWER = t
} else {
    # If no power value, skip power normalization.
    data.norm = data / data.max[2]   # Normalize data values.
}

# Normalize test data if available.
if (testset != "") {
   t = data.test$POWER / data.max[1] 
   data.test = data.test / data.max[2]
   data.test$POWER = t
}

# ANN TRAINING
if (use_predict == FALSE) {
   
   cat("Training ANN with network topology ")
   cat(length(PERFNAMES)-1, topo, 1, sep="-")
   cat("...\n")
   
   # Train ANN
   nnet = neuralnet(as.formula(paste("POWER ~", paste(PERFNAMES, collapse="+"))), 
                                  data.norm, hidden=topo, threshold=errt)

   # Calculate error on the separate test set if available.
   if (testset != "") {
      predictions = compute(nnet, data.test[,PERFNAMES])$net.result
      me.test = mean(abs(predictions - data.test$POWER)) * data.max[1]
      cat("   Prediction error on test data is", me.test, "\n")
   }
   
   # Save model.
   save(nnet, data.max, file=modelname)
   cat("done.\n\n")
   

# PREDICTION
} else {
   # Compute predictions, (nnet should be loaded from model).
   predictions = compute(nnet, data.norm[,PERFNAMES])$net.result * data.max[1]
   rownames(predictions) <- NULL
   
   # If provided prediction dataset contains a POWER column,
   if ("POWER" %in% names(data)) {
      # Put actual values alongside predicted values and print the set.
      predictions = cbind(predictions, data$POWER)
      rownames(predictions) <- NULL
      colnames(predictions) <- c("Predicted Values", "Actual Values")
      print(predictions)
      
      # Show error statistics.
      if (nrow(predictions) > 1) {  # Calculate SD only if more than one prediction.
        err = abs(predictions[,1] - predictions[,2])
        if ("POWER" %in% names(data)) cat("\nMean prediction error is", mean(err), "+/-", sd(err), "Watts\n\n")
      } else {
        if ("POWER" %in% names(data)) cat("\nPrediction error is", abs(predictions[1,1] - predictions[1,2]), "Watts\n\n")
      }
      
   # If dataset has no POWER column.
   } else {
      colnames(predictions) <- c("Predicted Values")
      rownames(predictions) <- NULL
      print(predictions)
   }
}

}
