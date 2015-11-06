# Merges datasets with the same headers.

args = commandArgs(trailingOnly=TRUE)
writeto = "ccat.dat"

# --out: output data filename
if ("--out" %in% args) {
   i = which(args == "--out") # check if output data file spec.
   if (length(i) == 1) {
      writeto = args[i + 1]
      args = args[-i]
      args = args[-i]
   }
}

if (length(args) != 0) {
    # Read in initial dataset.
   data = read.table(args[1], header=TRUE)
   
   # Read in and append other datasets.
   i = 2
   while (i <= length(args)) {
      data = rbind(data, read.table(args[i], header=TRUE))
      i = i + 1
   }
   
   # Write to specified file.
   write.table(data, writeto, row.names=FALSE)
}
