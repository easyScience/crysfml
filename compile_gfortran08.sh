@echo off
echo.
echo -------------------------------------------------------
echo ---- Crystallographic Fortran Modules Library 2018 ----
echo ---- GFortran Compiler (7.3 Windows/Linux/Max)     ---- 
echo ---- CrysFML Team                                  ----
echo -------------------------------------------------------
rem
rem ---- INIT ----
   (set _DEBUG=N)
   if [%TARGET_ARCH%]==[] (set TARGET_ARCH=ia32)
   if [%TARGET_ARCH%]==[ia32] (set OPTC=-m32) else (set OPTC=-m64)
rem
rem ---- Arguments ----
rem
:LOOP
    if [%1]==[debug] (set _DEBUG=Y)
    if [%1]==[winter] (set _WINTER=Y)
    shift
    if not [%1]==[] goto LOOP
rem
rem ---- Options
rem
   if [%_DEBUG%]==[Y] (
      if [%TARGET_ARCH%]==[ia32] (set DIRECTORY=GFortran_debug) else (set DIRECTORY=GFortran64_debug)
      (set OPT0=-O0 -std=f2008 -Wall -fdec-math -fbacktrace  -ffree-line-length-0)
      (set OPT1=-O0 -std=f2098 -Wall -fdec-math -fbacktrace  -ffree-line-length-0)
   ) else (
      if [%TARGET_ARCH%]==[ia32] (set DIRECTORY=GFortran) else (set DIRECTORY=GFortran64)
      (set OPT0=-O0 -std=f2008 -ffree-line-length-0 -fdec-math )
      (set OPT1=-O3 -std=f2008 -ffree-line-length-0 -fdec-math )
   )
   (set OPT3=)
   if [%_WINTER%]==[Y] (
      if [%TARGET_ARCH%]==[ia32] (set LIBFOR=lib.gnu32) else (set LIBFOR=lib.gnu64)
      (set OPT3=/I%WINTER%\%LIBFOR%)
   )
rem
   cd %CRYSFML%\Src08
rem
rem
   echo.
   echo ----
   echo ----  Compiler Options 
   echo ----
   echo OPTC:%OPTC%
   echo OPT0:%OPT0%
   echo OPT1:%OPT1%
   echo OPT2:%OPT2%
   echo OPT3:%OPT3%
   echo ----
   echo.
rem
   echo .... Global Dependencies for CFML
rem
   gfortran -c %OPTC% -J.\mod CFML_GlobalDeps_Windows_GFOR.f90       %OPT1% %OPT2%  
rem
   echo .... Mathematics Procedures
rem
   gfortran -c %OPTC%  -J.\mod CFML_math_general.f90                 %OPT1% %OPT2%       
rem 
rem   Submodulos CFML_Math_General   
      cd .\CFML_Math_General
      gfortran -c %OPTC%  -J..\mod AM_Median.f90                     %OPT1% %OPT2% 
      gfortran -c %OPTC%  -J..\mod Co_Linear.f90                     %OPT1% %OPT2% 
      gfortran -c %OPTC%  -J..\mod Co_Prime.f90                      %OPT1% %OPT2% 
      gfortran -c %OPTC%  -J..\mod Debye.f90                         %OPT1% %OPT2% 
      gfortran -c %OPTC%  -J..\mod Determinant.f90                   %OPT1% %OPT2% 
      gfortran -c %OPTC%  -J..\mod Diagonalize_SH.f90                %OPT1% %OPT2% 
      gfortran -c %OPTC%  -J..\mod Equal_Matrix.f90                  %OPT1% %OPT2% 
      gfortran -c %OPTC%  -J..\mod Equal_Vector.f90                  %OPT1% %OPT2% 
      gfortran -c %OPTC%  -J..\mod Erfc_Deriv.f90                    %OPT1% %OPT2% 
      gfortran -c %OPTC%  -J..\mod Factorial.f90                     %OPT1% %OPT2% 
      gfortran -c %OPTC%  -J..\mod Invert_Matrix.f90                 %OPT1% %OPT2% 
      gfortran -c %OPTC%  -J..\mod In_Limits.f90                     %OPT1% %OPT2% 
      gfortran -c %OPTC%  -J..\mod Linear_Dependent.f90              %OPT1% %OPT2% 
      gfortran -c %OPTC%  -J..\mod Locate.f90                        %OPT1% %OPT2% 
      gfortran -c %OPTC%  -J..\mod Lower_Triangular.f90              %OPT1% %OPT2% 
      gfortran -c %OPTC%  -J..\mod Modulo_Lat.f90                    %OPT1% %OPT2% 
      gfortran -c %OPTC%  -J..\mod Negligible.f90                    %OPT1% %OPT2% 
      gfortran -c %OPTC%  -J..\mod Norm.f90                          %OPT1% %OPT2% 
      gfortran -c %OPTC%  -J..\mod Outerprod.f90                     %OPT1% %OPT2% 
      gfortran -c %OPTC%  -J..\mod Pgcd.f90                          %OPT1% %OPT2% 
      gfortran -c %OPTC%  -J..\mod Points_In_Line2D.f90              %OPT1% %OPT2% 
      gfortran -c %OPTC%  -J..\mod Poly_Legendre.f90                 %OPT1% %OPT2% 
      gfortran -c %OPTC%  -J..\mod Ppcm.f90                          %OPT1% %OPT2% 
      gfortran -c %OPTC%  -J..\mod Rank.f90                          %OPT1% %OPT2% 
      gfortran -c %OPTC%  -J..\mod Scalar.f90                        %OPT1% %OPT2% 
      gfortran -c %OPTC%  -J..\mod SmoothingVec.f90                  %OPT1% %OPT2% 
      gfortran -c %OPTC%  -J..\mod Sort.f90                          %OPT1% %OPT2% 
      gfortran -c %OPTC%  -J..\mod Sph_Jn.f90                        %OPT1% %OPT2% 
      gfortran -c %OPTC%  -J..\mod Spline.f90                        %OPT1% %OPT2% 
      gfortran -c %OPTC%  -J..\mod Svdcmp.f90                        %OPT1% %OPT2% 
      gfortran -c %OPTC%  -J..\mod Swap.f90                          %OPT1% %OPT2% 
      gfortran -c %OPTC%  -J..\mod Trace.f90                         %OPT1% %OPT2% 
      gfortran -c %OPTC%  -J..\mod Upper_Triangular.f90              %OPT1% %OPT2% 
      gfortran -c %OPTC%  -J..\mod Zbelong.f90                       %OPT1% %OPT2%   
      move /y *.o .. > nul
      cd ..
rem
   gfortran -c %OPTC% -J.\mod CFML_math_3D.f90                       %OPT1% %OPT2%
rem 
rem   Submodulos CFML_Math_3D   
      cd .\CFML_Math_3D
      gfortran -c %OPTC%  -J..\mod Cross_Product.f90                 %OPT1% %OPT2%
      gfortran -c %OPTC%  -J..\mod Determ_3x3.f90                    %OPT1% %OPT2%
      gfortran -c %OPTC%  -J..\mod Determ_Vec.f90                    %OPT1% %OPT2%
      gfortran -c %OPTC%  -J..\mod Get_Cart_from_Cylin.f90           %OPT1% %OPT2%
      gfortran -c %OPTC%  -J..\mod Get_Cart_from_Spher.f90           %OPT1% %OPT2%
      gfortran -c %OPTC%  -J..\mod Get_Cylin_from_Cart.f90           %OPT1% %OPT2%
      gfortran -c %OPTC%  -J..\mod Get_Spher_from_Cart.f90           %OPT1% %OPT2%
      gfortran -c %OPTC%  -J..\mod Invert_Array3x3.f90               %OPT1% %OPT2%
      gfortran -c %OPTC%  -J..\mod Matrix_DiagEigen.f90              %OPT1% %OPT2%
      gfortran -c %OPTC%  -J..\mod Mat_Cross.f90                     %OPT1% %OPT2%
      gfortran -c %OPTC%  -J..\mod Resolv_Sistem.f90                 %OPT1% %OPT2%
      gfortran -c %OPTC%  -J..\mod Rotation_Axes.f90                 %OPT1% %OPT2%
      gfortran -c %OPTC%  -J..\mod Tensor_Product.f90                %OPT1% %OPT2%
      gfortran -c %OPTC%  -J..\mod Vec_Length.f90                    %OPT1% %OPT2%
      move /y *.o .. > nul
      cd .. 
rem
   gfortran -c %OPTC% -J.\mod CFML_spher_harm.f90                    %OPT1% %OPT2%  
   gfortran -c %OPTC% -J.\mod CFML_random.f90                        %OPT1% %OPT2%
   gfortran -c %OPTC% -J.\mod CFML_ffts.f90                          %OPT1% %OPT2%
rem 
   echo .... Profiles Functions
rem
   gfortran -c %OPTC% -J.\mod CFML_Profile_Functs.f90                %OPT1% %OPT2%
   gfortran -c %OPTC% -J.\mod CFML_Profile_Finger.f90                %OPT1% %OPT2%
   gfortran -c %OPTC% -J.\mod CFML_Profile_TOF.f90                   %OPT1% %OPT2%
rem   
   echo .... IO Messages /String Utilities
rem   
   if [%_WINTER%]==[Y] (
     gfortran -c %OPTC% -J.\mod CFML_io_messwin.f90                  %OPT1% %OPT2% %OPT3%
   ) else (
     gfortran -c %OPTC% -J.\mod CFML_io_mess.f90                     %OPT1% %OPT2%
   )
rem 
   gfortran -c %OPTC% -J.\mod CFML_string_util.f90                   %OPT1% %OPT2%
rem  
rem   Submodulos CFML_String_Utilities
      cd  CFML_String_Utilities
      gfortran -c %OPTC% -J..\mod StringFullp.f90                    %OPT1% %OPT2%
      gfortran -c %OPTC% -J..\mod StringTools.f90                    %OPT1% %OPT2%
      gfortran -c %OPTC% -J..\mod StringNum.f90                      %OPT1% %OPT2%
      gfortran -c %OPTC% -J..\mod StringReadKey.f90                  %OPT1% %OPT2%
      move /y *.o .. > nul
      cd ..
rem
   echo .... Tables definitions
   gfortran -c %OPTC% -J.\mod CFML_BVSpar.f90                        %OPT0% %OPT2%
   gfortran -c %OPTC% -J.\mod CFML_chem_scatt.f90                    %OPT0% %OPT2%
   gfortran -c %OPTC% -J.\mod CFML_bonds_table.f90                   %OPT0% %OPT2%
   gfortran -c %OPTC% -J.\mod CFML_sym_table.f90                     %OPT0% %OPT2%
rem  
rem 
   echo .... Rational Arithmetic
rem
   gfortran -C %OPTC% -J.\mod CFML_Rational_Arithmetic.f90           %OPT1% %OPT2% 
rem  
rem   Submodulos CFML_Rational_Arithmetic
      cd CFML_Rational_Arithmetic   
      gfortran -c %OPTC% -J..\mod  assignment.f90                    %OPT1% %OPT2% 
      gfortran -c %OPTC% -J..\mod  constructor.f90                   %OPT1% %OPT2% 
      gfortran -c %OPTC% -J..\mod  matmul.f90                        %OPT1% %OPT2% 
      gfortran -c %OPTC% -J..\mod  maxloc.f90                        %OPT1% %OPT2% 
      gfortran -c %OPTC% -J..\mod  maxval.f90                        %OPT1% %OPT2% 
      gfortran -c %OPTC% -J..\mod  minloc.f90                        %OPT1% %OPT2% 
      gfortran -c %OPTC% -J..\mod  minval.f90                        %OPT1% %OPT2% 
      gfortran -c %OPTC% -J..\mod  mod.f90                           %OPT1% %OPT2% 
      gfortran -c %OPTC% -J..\mod  modulo.f90                        %OPT1% %OPT2% 
      gfortran -c %OPTC% -J..\mod  operator_add.f90                  %OPT1% %OPT2% 
      gfortran -c %OPTC% -J..\mod  operator_division.f90             %OPT1% %OPT2% 
      gfortran -c %OPTC% -J..\mod  operator_eq.f90                   %OPT1% %OPT2% 
      gfortran -c %OPTC% -J..\mod  operator_ge.f90                   %OPT1% %OPT2% 
      gfortran -c %OPTC% -J..\mod  operator_gt.f90                   %OPT1% %OPT2% 
      gfortran -c %OPTC% -J..\mod  operator_le.f90                   %OPT1% %OPT2% 
      gfortran -c %OPTC% -J..\mod  operator_lt.f90                   %OPT1% %OPT2% 
      gfortran -c %OPTC% -J..\mod  operator_minus.f90                %OPT1% %OPT2% 
      gfortran -c %OPTC% -J..\mod  operator_multiply.f90             %OPT1% %OPT2% 
      gfortran -c %OPTC% -J..\mod  operator_ne.f90                   %OPT1% %OPT2% 
      gfortran -c %OPTC% -J..\mod  overloads.f90                     %OPT1% %OPT2% 
      move /y *.o .. > nul
      cd ..
rem
   echo .... Crystal Metrics
rem
   gfortran -C %OPTC% -J.\mod CFML_crystal_metrics.f90               %OPT1% %OPT2% 
rem  
rem   Submodulos CFML_Crystal_Metrics
      cd CFML_Crystal_Metrics
      gfortran -c %OPTC% -J..\mod genmetrics.f90                     %OPT1% %OPT2% 
      goto FIN
      gfortran -c %OPTC% -J..\mod ioroutines.f90                     %OPT1% %OPT2% 
      gfortran -c %OPTC% -J..\mod ThConver.f90                       %OPT1% %OPT2% 
      gfortran -c %OPTC% -J..\mod Nigglicell.f90                     %OPT1% %OPT2% 
      move /y *.o .. > nul
      cd ..  
   goto FIN
   goto TTT
   echo .... Patterns Information
rem        
   goto FIN
rem   
   gfortran -c %OPTC% CFML_LSQ_TypeDef.f90                      %OPT1% %OPT2%
   
rem
   echo **---- Level 1 ----**
   echo .... Mathematical(II), Optimization, Tables, Patterns
rem
   gfortran -c %OPTC% CFML_optimization.f90                     %OPT1% %OPT2%
   gfortran -c %OPTC% CFML_optimization_lsq.f90                 %OPT1% %OPT2%
   gfortran -c %OPTC% CFML_diffpatt.f90                         %OPT1% %OPT2%
rem
   echo **---- Level 2 ----**
   echo .... Bonds, Crystal Metrics, Symmetry, ILL_Instr
rem
   gfortran -c %OPTC% CFML_cryst_types.f90                      %OPT1% %OPT2%
   gfortran -c %OPTC% CFML_symmetry.f90                         %OPT1% %OPT2%
   gfortran -c %OPTC% CFML_ILL_Instrm_data.f90                  %OPT1% %OPT2%
rem
   echo **---- Level 3 ----**
   echo .... EoS, Reflections, Atoms
rem
   gfortran -c %OPTC% CFML_Eos_Mod.f90                          %OPT1% %OPT2%
   gfortran -c %OPTC% CFML_reflct_util.f90                      %OPT1% %OPT2%
   gfortran -c %OPTC% CFML_atom_mod.f90                         %OPT1% %OPT2%
rem
   echo **---- Level 4 ----**
   echo .... Formats, Geometry Calculations, Molecules
rem
   gfortran -c %OPTC% CFML_geom_calc.f90                       %OPT1% %OPT2%
   gfortran -c %OPTC% CFML_molecules.f90                       %OPT1% %OPT2%
   gfortran -c %OPTC% CFML_form_cif.f90                        %OPT1% %OPT2%
rem
   echo **---- Level 5 ----**
   echo .... Extinction, Structure Factors, SXTAL geometry, Propag Vectors
rem
   gfortran -c %OPTC% CFML_sfac.f90                            %OPT1% %OPT2%
   gfortran -c %OPTC% CFML_sxtal_Geom.f90                      %OPT1% %OPT2%
   gfortran -c %OPTC% CFML_propagk.f90                         %OPT1% %OPT2%
rem
   echo **---- Level 6 ----**
   echo .... Maps, BVS, Energy Configurations
rem
   gfortran -c %OPTC% CFML_Export_Vtk.f90                      %OPT1% %OPT2%
   gfortran -c %OPTC% CFML_maps.f90                            %OPT1% %OPT2%
   gfortran -c %OPTC% CFML_conf_calc.f90                       %OPT1% %OPT2%
rem
   echo **---- Level 7 ----**
   echo .... Magnetic Symmetry, Simulated Annealing, Keywords Parser
rem
   gfortran -c %OPTC% CFML_magsymm.f90                         %OPT1% %OPT2%
   gfortran -c %OPTC% CFML_optimization_san.f90                %OPT1% %OPT2% %OPT3%
   gfortran -c %OPTC% CFML_refcodes.f90                        %OPT1% %OPT2%
rem
   echo **---- Level 8 ----**
   echo .... Magnetic Structure Factors, Polarimetry
rem
   gfortran -c %OPTC% CFML_msfac.f90                           %OPT1% %OPT2%
   gfortran -c %OPTC% CFML_polar.f90                           %OPT1% %OPT2%
rem
rem
:TTT
   echo **---- Crysfml Library ----**
rem
   if [%_WINTER%]==[Y] (
     ar cr libwcrysfml.a *.o
   ) else (
     ar cr libcrysfml.a *.o
   )
rem
   echo **---- GFortran Directory ----**
rem
   if not exist ..\%DIRECTORY% mkdir ..\%DIRECTORY%
   if [%_WINTER%]==[Y] (
     if exist ..\%DIRECTORY%\LibW08 rmdir ..\%DIRECTORY%\LibW08 /S /Q
     mkdir ..\%DIRECTORY%\LibW08
     copy *.mod ..\%DIRECTORY%\LibW08 > nul
     move *.lib ..\%DIRECTORY%\LibW08 > nul
   ) else (
     if exist ..\%DIRECTORY%\LibC08 rmdir ..\%DIRECTORY%\LibC08 /S /Q
     mkdir ..\%DIRECTORY%\LibC08
     copy *.mod ..\%DIRECTORY%\LibC08 > nul
     move *.a ..\%DIRECTORY%\LibC08 > nul
   )
   del *.o  *.lst *.bak > nul
rem
rem   cd %CRYSFML%\Scripts\Windows
:FIN
rem   del *.o *.obj *.mod > nul
   cd ..   