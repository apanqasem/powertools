# FOR PREDICTING CPU POWER WITH A LINEAR REGRESSION MODEL
# Author: Mario A. Gutierrez
# Last Revision: 3 March 2015

######################################################################

args = commandArgs(trailingOnly=TRUE) # Get command-line arguments.

if (length(args) == 0) {
   cat("Usage: regr.r --m [amd|intel] --dataset [filename] --testset(opt.) [filename]\n")
   cat("Usage: regr.r --m [amd|intel] --predict [filename]\n")
} else {

filename = "data.dat"   # Default input data filename.
testset = ""            # Default testset filename.
modelname = "regr.mdl"   # Default model filename.
use_predict = FALSE     # Is this script being run for prediction?
removeOutlier = FALSE   # Fix problem with intel power collection.

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

###################### LINEAR REGRESSION ANALYSIS #####################

# REG TRAINING
if (use_predict == FALSE) {
   
   cat("Training linear regression model...\n")
   
   # Train linear regression model.
   regm = lm(as.formula(paste("POWER ~", paste(PERFNAMES, collapse="+"))), data)

   # Calculate error on the separate test set if available.
   if (testset != "") {
      predictions = as.matrix(cbind(1, data.test[,PERFNAMES])) %*% regm$coefficients
      me.test = mean(abs(predictions - data.test$POWER))
      cat("   Prediction error on test data is", me.test, "\n")
   }
   
   # Save the coefficients of the model.
   write.table(regm$coefficients, modelname)   
   cat("done.\n\n")
   
# PREDICTION
} else {
   # Load model coefficients.
   regm = read.table(modelname, header=TRUE)
   
   # Calculate predictions.
   predictions = as.matrix(cbind(1, data[,PERFNAMES])) %*% regm$x
   
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
