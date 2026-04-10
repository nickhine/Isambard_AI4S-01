Here are some instructions for building LAMMPS with the ML-IAP interface when using the uv package manager.
I have used forks of the current (as of 07/03/2026) lammps and mace git repos, but this should work if mace is installed from pip (though I haven't tried this).
Please let me know if you have anuy questions!

```
# Prepare node for building
srun --nodes=1 --ntasks=1 --gpus=1 --time=01:30:00 --pty bash
module load PrgEnv-gnu gcc-native/13.2 cudatoolkit/24.11_12.6 craype-accel-nvidia90 craype-accel-nvidia90 cray-hdf5/1.14.3.5 cray-netcdf/4.9.0.17 

# Setup UV venv
uv venv --python 3.11.7 ~/venvs/lammps-mliap
source venvs/lammps-mliap/bin/activate
uv pip install --upgrade pip
uv pip install "numpy==1.26.4" "scipy" "mpi4py" "dask==2023.6.1" "cython"

# Export environment variables
export CRAY_ACCEL_TARGET=nvidia90; export CC=$(which cc); export CXX=$(which CC); export FC=$(which ftn); export NVCC_WRAPPER_DEFAULT_COMPILER=$(which CC)

# Install mace
cd mace
uv pip install .
uv pip install --reinstall torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu126
uv pip install cuequivariance cuequivariance-torch cuequivariance-ops-torch-cu12 cupy-cuda12x
python -c "from mace.calculators import MACECalculator; print('MACECalculator OK')"

# Build LAMMPS binary
cd ../lammps
cmake -B build-mliap -D CMAKE_BUILD_TYPE=Release -D CMAKE_CXX_COMPILER=$(pwd)/lib/kokkos/bin/nvcc_wrapper -D CMAKE_CXX_STANDARD=20 -D CMAKE_CUDA_ARCHITECTURES=90 -D CMAKE_CXX_STANDARD_REQUIRED=ON -D CMAKE_CXX_FLAGS="-ffast-math" -D BUILD_MPI=ON -D BUILD_SHARED_LIBS=ON -D PKG_KOKKOS=ON -D Kokkos_ENABLE_SERIAL=ON -D Kokkos_ENABLE_CUDA=ON  -D BUILD_OMP=ON -D Kokkos_ARCH_HOPPER90=ON -D Kokkos_ENABLE_AGGRESSIVE_VECTORIZATION=ON -D PKG_ML-IAP=ON -D PKG_ML-SNAP=ON -D PKG_PYTHON=ON -D MLIAP_ENABLE_PYTHON=ON -D PKG_EXTRA-PAIR=ON cmake
cmake --build build-mliap -j 48

# Verify LAMMPS binary
cd build-mliap
./lmp -h > /dev/null; echo $?  # This should return 0 if built successfully!

# Create symlink to binary
cd ../bin
ln -s ~/lammps/build-mliap/lmp lmp-mliap
cd ../build-mliap

# Install LAMMPS binary
make install-python
cd
python -c "import lammps; print(lammps.__file__)"
 
```
