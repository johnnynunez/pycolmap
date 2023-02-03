@echo off

setlocal enabledelayedexpansion

rem Author: Johnny Nunez (johnnynunez)

rem Set the location of the Python interpreter
set PYTHON=python.exe

rem Declare the array for the Python version
set PYTHON_VERSION=(%1)

rem Install necessary packages
choco install wget cmake %PYTHON_VERSION%
choco install git cmake boost eigen freeimage flann glog gflags metis suite-sparse ceres-solver qt5 glew cgal sqlite3 libomp llvm lz4

rem Upgrade GCC if necessary
choco upgrade gcc

rem Get the Python version numbers only by splitting the string
set PYBIN="%ProgramFiles%\Python\%PYTHON_VERSION%\Scripts"
set INTERPRETER="%ProgramFiles%\Python\%PYTHON_VERSION%\python.exe"

rem Add the Python bin path to the PATH environment variable
set PATH=%PYBIN%;%PATH%

rem Save the current working directory
set CURRDIR=%CD%

rem Build Boost statically
mkdir boost_build
cd boost_build
wget boost_1_81_0-msvc-14.3-64.exe
tar xzf boost_1_81_0.tar.gz
cd boost_1_81_0
bootstrap.bat --prefix=%CURRDIR%\boost_install --with-libraries=serialization,filesystem,thread,system,atomic,date_time,timer,chrono,program_options,regex
b2 -j%NUMBER_OF_PROCESSORS% cxxflags="-fPIC" runtime-link=static variant=release link=static install

cd %CURRDIR%
mkdir wheelhouse_unrepaired
mkdir wheelhouse

rem Clone the colmap repository
git clone https://github.com/colmap/colmap.git

cd colmap
git checkout dev
mkdir build
cd build
cmake .. -DGUI_ENABLED=OFF

rem Compile and install colmap
call "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64
msbuild /m /p:Configuration=Release INSTALL.vcxproj

cd %CURRDIR%
%PYTHON% -m pip install -U delocate
%PYTHON% -m pip install -U pip setuptools wheel cffi

cd %CURRDIR%\colmap
set CC=clang.exe
set CXX=clang++.exe
set LDFLAGS=-L%ProgramFiles%\Libomp\lib
%PYTHON% setup.py bdist_wheel
copy .\dist\*.whl %CURRDIR%\wheelhouse_unrepaired