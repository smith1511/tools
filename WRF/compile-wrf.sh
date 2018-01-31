#!/bin/bash

set -o pipefail
set -e

# Library versions
WRF_VERSION=3.8.1
WPS_VERSION=3.9.0.1
MPICH_VERSION=3.2
HDF5_VERSION=1.10.1
NETCDF_VERSION=4.4.1.1
NETCDF_FORTRAN_VERSION=4.4.4
NETCDF_CXX_VERSION=4.3.0

sudo yum install -y epel-release
sudo yum update -y
sudo yum group install -y "Development Tools"

# Comiler and flags
export CC=gcc
export CXX=g++
export FC=gfortran
export FCFLAGS=-m64
export F77=gfortran
export FFLAGS=-m64

# Paths
CWD=$(cd `dirname $0` && pwd)
export BUILD_DIR=$CWD/wrf
export SRC_DIR=$BUILD_DIR/src
export LIBS_DIR=$BUILD_DIR/libs
export TEST_DIR=$BUILD_DIR/tests
export MPICH_DIR=$LIBS_DIR/mpich

#export ZLIB_DIR=$LIBS_DIR/hdf5
#export HDF5=$LIBS_DIR/hdf5
#export NETCDF=$LIBS_DIR/netcdf
#export NETCDFINCLUDE=$NETCDF/include
#export NETCDFLIB=$NETCDF/lib
#export JASPER=$LIBS_DIR/jasper
#export JASPERLIB=$JASPER/lib
#export JASPERINC=$JASPER/include
#export LIBPNG=$LIBS_DIR/libpng

export ZLIB_DIR=$LIBS_DIR
export HDF5=$LIBS_DIR
export NETCDF=$LIBS_DIR
export NETCDFINCLUDE=$NETCDF/include
export NETCDFLIB=$NETCDF/lib
export JASPER=$LIBS_DIR
export JASPERLIB=$JASPER/lib
export JASPERINC=$JASPER/include
export LIBPNG=$LIBS_DIR

# Update path
export PATH=$MPICH_DIR/bin:$PATH

# Compiler
export CPPFLAGS="-I$HDF5/include -I$NETCDF/include -I$ZLIB_DIR/include -I$MPICH_DIR/include -I$LIBPNG/include"
export LDFLAGS="-L$HDF5/lib -L$NETCDF/lib -L$ZLIB_DIR/lib -L$JASPERLIB -L$LIBPNG/lib -L$MPICH_DIR/lib"
export LD_LIBRARY_PATH="$HDF5/lib:$NETCDF/lib:$ZLIB_DIR/lib:$JASPERLIB:$LIBPNG/lib"


mkdir -p $BUILD_DIR
mkdir -p $SRC_DIR
mkdir -p $TEST_DIR
mkdir -p $LIBS_DIR

cd $SRC_DIR

# Download dependencies
wget http://www.mpich.org/static/downloads/3.2/mpich-${MPICH_VERSION}.tar.gz
wget ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-${NETCDF_VERSION}.tar.gz
wget ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-fortran-${NETCDF_FORTRAN_VERSION}.tar.gz
wget -O netcdf-cxx-${NETCDF_CXX_VERSION}.tar.gz https://github.com/Unidata/netcdf-cxx4/archive/v${NETCDF_CXX_VERSION}.tar.gz
wget http://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/jasper-1.900.1.tar.gz
wget http://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/libpng-1.2.50.tar.gz
wget http://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/zlib-1.2.7.tar.gz
wget https://support.hdfgroup.org/ftp/HDF5/current/src/hdf5-${HDF5_VERSION}.tar.gz

# MPICH
tar xzvf mpich-${MPICH_VERSION}.tar.gz
cd mpich-${MPICH_VERSION}
./configure --prefix=$LIBS_DIR/mpich
make -j4
make install
cd ..

export CC=$LIBS_DIR/mpich/bin/mpicc
export FC=$LIBS_DIR/mpich/bin/mpifort
export F77=$LIBS_DIR/mpich/bin/mpifort

# zlib
# we put this in hdf5 because otherwise WRF doesn't seem to include the LDFLAG (-L...) for zlib
tar xzvf zlib-1.2.7.tar.gz
cd zlib-1.2.7
./configure --prefix=$ZLIB_DIR
make -j4
make install
cd ..

# libpng
tar xzvf libpng-1.2.50.tar.gz
cd libpng-1.2.50
./configure --prefix=$LIBPNG
make -j4
make install
cd ..

# JasPer
tar xzvf jasper-1.900.1.tar.gz
cd jasper-1.900.1
./configure --prefix=$JASPER
make -j4
make install
cd ..

# HDF5
tar -xvzf hdf5-${HDF5_VERSION}.tar.gz
cd hdf5-${HDF5_VERSION}
./configure --prefix=$HDF5 --enable-fortran --with-zlib=$ZLIB_DIR --enable-shared --enable-parallel
make -j4
make install
cd ..

# NetCDF
tar xzvf netcdf-${NETCDF_VERSION}.tar.gz
cd netcdf-${NETCDF_VERSION}
./configure --prefix=$NETCDF --enable-parallel-tests
make -j4
make install
cd ..

tar xvfz netcdf-fortran-${NETCDF_FORTRAN_VERSION}.tar.gz
cd netcdf-fortran-${NETCDF_FORTRAN_VERSION}
./configure --prefix=$NETCDF
make -j4
make install
cd ..

tar xvfz netcdf-cxx-${NETCDF_CXX_VERSION}.tar.gz
cd netcdf-cxx4-${NETCDF_CXX_VERSION}
./configure --prefix=$NETCDF
make -j4
make install
cd .

# Library Compatibility Tests

# Test #1: Fortran + C + NetCDF
cd $SRC_DIR
wget http://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/Fortran_C_NETCDF_MPI_tests.tar
tar -xvf Fortran_C_NETCDF_MPI_tests.tar
cp ${NETCDF}/include/netcdf.inc .
gfortran -c 01_fortran+c+netcdf_f.f
gcc -c 01_fortran+c+netcdf_c.c
gfortran 01_fortran+c+netcdf_f.o 01_fortran+c+netcdf_c.o \
     -L${NETCDF}/lib -lnetcdff -lnetcdf
./a.out

# Test #2: Fortran + C + NetCDF + MPI
mpif90 -c 02_fortran+c+netcdf+mpi_f.f
mpicc -c 02_fortran+c+netcdf+mpi_c.c
mpif90 02_fortran+c+netcdf+mpi_f.o \
02_fortran+c+netcdf+mpi_c.o \
     -L${NETCDF}/lib -lnetcdff -lnetcdf
mpirun ./a.out


# WRF
cd $BUILD_DIR
wget http://www2.mmm.ucar.edu/wrf/src/WRFV${WRF_VERSION}.TAR.gz
tar xvfz WRFV${WRF_VERSION}.TAR.gz
rm WRFV${WRF_VERSION}.TAR.gz
cd WRFV3
export WRFIO_NCD_LARGE_FILE_SUPPORT=1
# Select #34 for GNU dmpar
# Option 1 basic nesting
./configure << EOF
34
1
EOF
./compile em_real

# WPS
cd $BUILD_DIR
wget http://www2.mmm.ucar.edu/wrf/src/WPSV${WPS_VERSION}.TAR.gz
tar xvfz WPSV${WPS_VERSION}.TAR.gz
rm WPSV${WPS_VERSION}.TAR.gz
cd WPS
./clean
# Option 3 for parallel, Option #1 for serial
./configure << EOF
1
EOF
./compile

#rm -rf $SRC_DIR

cd $BUILD_DIR

tar cvf wrf.tar *
gzip wrf.tar

mv wrf.tar.gz $CWD
