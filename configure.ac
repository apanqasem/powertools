#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ(2.61)
AC_INIT([powertools], [0.1], [apan@txstate.edu])
#AC_CONFIG_SRCDIR([src/driver/Args.C])
#AC_CONFIG_AUX_DIR([config])


# Checks for programs.
AC_PROG_AWK
AC_PROG_CXX
AC_PROG_CC
AC_PROG_RANLIB


AC_PATH_PROG(R, Rscript, no)



# Checks for libraries.

# Checks for header files.
AC_HEADER_DIRENT
AC_HEADER_STDC
AC_HEADER_SYS_WAIT
AC_CHECK_HEADERS([stdlib.h sys/time.h unistd.h getopt.h dirent.h])

# Checks for typedefs, structures, and compiler characteristics.
AC_HEADER_STDBOOL
AC_C_CONST

# Checks for library functions.
AC_FUNC_CLOSEDIR_VOID
AC_FUNC_FORK
AC_FUNC_MALLOC

#AC_CONFIG_FILES([Makefile])

AC_OUTPUT
