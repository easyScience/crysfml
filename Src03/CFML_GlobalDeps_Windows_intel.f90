!!-------------------------------------------------------
!!---- Crystallographic Fortran Modules Library (CrysFML)
!!-------------------------------------------------------
!!---- The CrysFML project is distributed under LGPL. In agreement with the
!!---- Intergovernmental Convention of the ILL, this software cannot be used
!!---- in military applications.
!!----
!!---- Copyright (C) 1999-2015  Institut Laue-Langevin (ILL), Grenoble, FRANCE
!!----                          Universidad de La Laguna (ULL), Tenerife, SPAIN
!!----                          Laboratoire Leon Brillouin(LLB), Saclay, FRANCE
!!----
!!---- Authors: Juan Rodriguez-Carvajal (ILL)
!!----          Javier Gonzalez-Platas  (ULL)
!!----
!!---- Contributors: Laurent Chapon     (ILL)
!!----               Marc Janoschek     (Los Alamos National Laboratory, USA)
!!----               Oksana Zaharko     (Paul Scherrer Institute, Switzerland)
!!----               Tierry Roisnel     (CDIFX,Rennes France)
!!----               Eric Pellegrini    (ILL)
!!----
!!---- This library is free software; you can redistribute it and/or
!!---- modify it under the terms of the GNU Lesser General Public
!!---- License as published by the Free Software Foundation; either
!!---- version 3.0 of the License, or (at your option) any later version.
!!----
!!---- This library is distributed in the hope that it will be useful,
!!---- but WITHOUT ANY WARRANTY; without even the implied warranty of
!!---- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
!!---- Lesser General Public License for more details.
!!----
!!---- You should have received a copy of the GNU Lesser General Public
!!---- License along with this library; if not, see <http://www.gnu.org/licenses/>.
!!----
!!----
!!---- MODULE: CFML_GlobalDeps (Windows version)
!!----   INFO: Precision for CrysFML library and Operating System information
!!----         All the global variables defined in this module are implicitly public.
!!----
!!---- HISTORY
!!--..    Update: 19/03/2015
!!--..
!!----
!!
Module CFML_GlobalDeps
   !---- Variables ----!
   implicit None

   public

   !--------------------!
   !---- PARAMETERS ----!
   !--------------------!

   !---- Operating System ----!
   character(len=*), parameter :: OPS_NAME = "Windows"           ! O.S. Name
   character(len=*), parameter :: OPS_SEP = "\"                  ! O.S. directory separator character
   integer,          parameter :: OPS = 1                        ! O.S. Flag -> 1:Win 2:Lin 3:Mac

   !---- Precision ----!
   integer, parameter :: DP = selected_real_kind(14,150)         ! Double precision
   integer, parameter :: SP = selected_real_kind(6,30)           ! Simple precision
   integer, parameter :: CP = SP                                 ! Current precision

   !---- Trigonometric ----!
   real(kind=DP), parameter :: PI = 3.141592653589793238463_dp   ! PI value
   real(kind=DP), parameter :: TO_DEG  = 180.0_dp/PI             ! Conversion from Radians to Degrees
   real(kind=DP), parameter :: TO_RAD  = pi/180.0_dp             ! Conversion from Degrees to Radians
   real(kind=DP), parameter :: TPI = 6.283185307179586476925_dp  ! 2*PI

   !---- Numeric ----!
   real(kind=DP), parameter :: DEPS=0.00000001_dp                ! Epsilon value use for comparison of real numbers (DOUBLE)
   real(kind=CP), parameter :: EPS=0.00001_cp                    ! Epsilon value use for comparison of real numbers (SIMPLE)

 Contains

   !-------------------!
   !---- Functions ----!
   !-------------------!

   !!----
   !!---- FUNCTION DIRECTORY_EXISTS
   !!----
   !!----    Generic function dependent of the compiler that return
   !!----    a logical value if a directory exists or not.
   !!----
   !!---- Update: 11/07/2015
   !!
   Function Directory_Exists(DirName) Result(info)
      !---- Argument ----!
      character(len=*), intent(in) :: DirName               ! Directory name
      logical                      :: info                  ! Return Value

      !---- Local Variables ----!
      character(len=1024) :: linea
      integer            :: nlong

      !> Init value
      info=.false.

      linea=trim(dirname)
      nlong=len_trim(linea)
      if (nlong ==0) return

      if (linea(nlong:nlong) /= ops_sep) linea=trim(linea)//ops_sep

      !> All compilers except Intel
      !inquire(file=trim(linea)//'.' , exist=info)

      !> Intel
      inquire(directory=trim(linea), exist=info)

      return
   End Function Directory_Exists

End Module CFML_GlobalDeps
