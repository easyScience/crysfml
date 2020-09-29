compiler=$1
echo "Building CrysFML with ${compiler##/*}"

rm -Rf build_release
mkdir build_release
cd build_release

cmake -D ARCH32=OFF -D CMAKE_BUILD_TYPE=Release -D CMAKE_Fortran_COMPILER=ifort -D USE_HDF=ON -D HDF5_INCLUDE_PATH=${HDF5_INCLUDE_PATH} -D HDF5_LIBRARY_PATH=${HDF5_LIBRARY_PATH} ..
cmake --build . && ctest