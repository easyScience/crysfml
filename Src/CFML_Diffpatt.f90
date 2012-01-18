!!----
!!---- Copyleft(C) 1999-2011,              Version: 5.0
!!---- Juan Rodriguez-Carvajal & Javier Gonzalez-Platas
!!----
!!---- MODULE: CFML_Diffraction_Patterns
!!----   INFO: Diffraction Patterns Information
!!----
!!---- HISTORY
!!----    Update: 04/03/2011
!!----
!!---- DEPENDENCIES
!!----    Use CFML_GlobalDeps,       only : cp
!!----    Use CFML_Math_General,     only : spline, splint, locate
!!----    Use CFML_String_Utilities, only : FindFmt,  Init_FindFmt , ierr_fmt, &
!!----                                      get_logunit, u_case, getword
!!----
!!---- VARIABLES
!!----    DIFFRACTION_PATTERN_TYPE
!!----    ERR_DIFFPATT
!!----    ERR_DIFFPATT_MESS
!!----
!!---- PROCEDURES
!!----    Functions:
!!----       CALC_FWHM_PEAK
!!----
!!----    Subroutines:
!!----       ADD_DIFFRACTION_PATTERNS
!!----       ALLOCATE_DIFFRACTION_PATTERN
!!----       CALC_BACKGROUND
!!----       DELETE_NOISY_POINTS
!!----       INIT_ERR_DIFFPATT
!!----       PURGE_DIFFRACTION_PATTERN
!!----       READ_BACKGROUND_FILE
!!----       READ_PATTERN
!!--++       READ_PATTERN_D1A_D2B           [Private]
!!--++       READ_PATTERN_D1A_D2B_OLD       [Private]
!!--++       READ_PATTERN_D1B_D20           [Private]
!!--++       READ_PATTERN_DMC               [Private]
!!--++       READ_PATTERN_FREE              [Private]
!!--++       READ_PATTERN_G41               [Private]
!!--++       READ_PATTERN_GSAS              [Private]
!!--++       READ_PATTERN_ISIS_M            [Private]
!!--++       READ_PATTERN_MULT              [Overloaded]
!!--++       READ_PATTERN_NLS               [Private]
!!--++       READ_PATTERN_ONE               [Overloaded]
!!--++       READ_PATTERN_PANALYTICAL_CSV   [Private]
!!--++       READ_PATTERN_PANALYTICAL_JCP   [Private]
!!--++       READ_PATTERN_PANALYTICAL_UDF   [Private]
!!--++       READ_PATTERN_PANALYTICAL_XRDML [Private]
!!--++       READ_PATTERN_SOCABIM           [Private]
!!--++       READ_PATTERN_TIME_VARIABLE     [Private]
!!--++       READ_PATTERN_XYSIGMA           [Private]
!!--++       SET_BACKGROUND_INTER           [Private]
!!--++       SET_BACKGROUND_POLY            [Private]
!!----       WRITE_PATTERN_FREEFORMAT
!!----       WRITE_PATTERN_INSTRM5
!!----       WRITE_PATTERN_XYSIG
!!----
!!
 Module CFML_Diffraction_Patterns
    !---- Use Modules ----!
    Use CFML_GlobalDeps,       only : cp
    Use CFML_Math_General,     only : spline, splint, locate,second_derivative
    use CFML_String_Utilities, only : FindFmt,  Init_FindFmt , ierr_fmt, &
                                      get_logunit, u_case, getword, getnum

    implicit none

    private

    !---- List of public functions ----!
    public ::  calc_fwhm_peak

    !---- List of public subroutines ----!
    public ::  Init_Err_DiffPatt, Calc_Background, Read_Background_File, Read_Pattern,      &
               Purge_Diffraction_Pattern, Allocate_Diffraction_Pattern, Write_Pattern_XYSig,&
               Write_Pattern_FreeFormat, Add_Diffraction_Patterns, Delete_Noisy_Points,     &
               Write_Pattern_INSTRM5

    !---- List of private subroutines ----!
    private :: Read_Pattern_D1A_D2B, Read_Pattern_D1A_D2B_Old, Read_Pattern_D1B_D20,       &
               Read_Pattern_Dmc, Read_Pattern_Free, Read_Pattern_G41, Read_Pattern_Gsas,   &
               Read_Pattern_Isis_M, Read_Pattern_Mult, Read_Pattern_Nls, Read_Pattern_One, &
               Read_Pattern_Panalytical_Csv, Read_Pattern_Panalytical_Jcp,                 &
               Read_Pattern_Panalytical_Udf, Read_Pattern_Panalytical_Xrdml,               &
               Read_Pattern_Socabim, Read_Pattern_Time_Variable, Read_Pattern_Xysigma,     &
               Set_Background_Inter, Set_Background_Poly

    !---- Definitions ----!

    !!----
    !!---- TYPE :: DIFFRACTION_PATTERN_TYPE
    !!--..
    !!---- Type, public :: Diffraction_Pattern_Type
    !!----    character(len=180)                          :: Title         !Identification of the pattern
    !!----    character(len=20)                           :: diff_kind     !type of radiation
    !!----    character(len=20)                           :: scat_var      !x-space: 2theta, TOF, Q, s, d-spacing, SinT/L, etc
    !!----    character(len=20)                           :: instr         !file type
    !!----    character(len=512)                          :: filename      !file name
    !!----    real(kind=cp)                               :: xmin
    !!----    real(kind=cp)                               :: xmax
    !!----    real(kind=cp)                               :: ymin
    !!----    real(kind=cp)                               :: ymax
    !!----    real(kind=cp)                               :: scal
    !!----    real(kind=cp)                               :: monitor
    !!----    real(kind=cp)                               :: norm_mon      !Normalisation monitor
    !!----    real(kind=cp)                               :: col_time      !Data collection time
    !!----    real(kind=cp)                               :: step
    !!----    real(kind=cp)                               :: Tsamp         !Sample Temperature
    !!----    real(kind=cp)                               :: Tset          !Setting Temperature (wished temperature)
    !!----    integer                                     :: npts          !Number of points
    !!----    logical                                     :: ct_step       !Constant step
    !!----    logical                                     :: gy,gycalc,&
    !!----                                                   gbgr,gsigma   !logicals for graphics
    !!----
    !!----    logical                                     :: al_x,al_y,&
    !!----                                                   al_ycalc, &   !logicals for allocation
    !!----                                                   al_bgr,   &
    !!----                                                   al_sigma, &
    !!----                                                   al_istat
    !!----
    !!----    real(kind=cp), dimension (3)                :: conv          ! Wavelengths or Dtt1, Dtt2 for converting to Q,d, etc
    !!----    real(kind=cp), dimension (:), allocatable   :: x             ! Scattering variable (2theta...)
    !!----    real(kind=cp), dimension (:), allocatable   :: y             ! Experimental intensity
    !!----    real(kind=cp), dimension (:), allocatable   :: sigma         ! observations VARIANCE (it is the square of sigma!)
    !!----    integer,       dimension (:), allocatable   :: istat         ! Information about the point "i"
    !!----    real(kind=cp), dimension (:), allocatable   :: ycalc         ! Calculated intensity
    !!----    real(kind=cp), dimension (:), allocatable   :: bgr           ! Background
    !!----
    !!---- End Type Diffraction_Pattern_Type
    !!----
    !!----    Definition for Diffraction Pattern Type
    !!----
    !!---- Update: April - 2011  !Initialisation values have been included except for allocatables
    !!
    Type, public :: Diffraction_Pattern_Type
       character(len=180)                          :: Title=" "        !Identification of the pattern
       character(len=20)                           :: diff_kind=" "    !type of radiation
       character(len=20)                           :: scat_var=" "     !x-space: 2theta, TOF, Q, s, d-spacing, SinT/L, etc
       character(len=20)                           :: instr=" "        !file type
       character(len=512)                          :: filename=" "     !file name
       real(kind=cp)                               :: xmin=0.0
       real(kind=cp)                               :: xmax=0.0
       real(kind=cp)                               :: ymin=0.0
       real(kind=cp)                               :: ymax=0.0
       real(kind=cp)                               :: scal=0.0
       real(kind=cp)                               :: monitor=0.0
       real(kind=cp)                               :: norm_mon=0.0
       real(kind=cp)                               :: col_time=0.0
       real(kind=cp)                               :: step=0.0
       real(kind=cp)                               :: Tsamp=0.0        !Sample Temperature
       real(kind=cp)                               :: Tset=0.0         !Setting Temperature (wished temperature)
       integer                                     :: npts=0           !Number of points
       logical                                     :: ct_step=.false.  !Constant step
       logical                                     :: gy=.false.,gycalc=.false.,&
                                                      gbgr=.false.,gsigma=.false.   !logicals for graphics

       logical                                     :: al_x=.false.,al_y=.false.,&
                                                      al_ycalc=.false., &   !logicals for allocation
                                                      al_bgr=.false.,   &
                                                      al_sigma=.false., &
                                                      al_istat=.false.

       real(kind=cp), dimension (3)                :: conv=0.0      ! Wavelengths or Dtt1, Dtt2 for converting to Q,d, etc
       real(kind=cp), dimension (:), allocatable   :: x             ! Scattering variable (2theta...)
       real(kind=cp), dimension (:), allocatable   :: y             ! Experimental intensity
       real(kind=cp), dimension (:), allocatable   :: sigma         ! observations VARIANCE (it is the square of sigma!)
       integer,       dimension (:), allocatable   :: istat         ! Information about the point "i"
       real(kind=cp), dimension (:), allocatable   :: ycalc         ! Calculated intensity
       real(kind=cp), dimension (:), allocatable   :: bgr           ! Background
       integer,       dimension (:), allocatable   :: nd            ! Number of detectors contributing to the point "i"
    End Type Diffraction_Pattern_Type

    !!----
    !!---- ERR_DIFFPATT
    !!----    logical, public :: Err_Diffpatt
    !!----
    !!----    Logical Variable to indicate an error on this module.
    !!----
    !!---- Update: February - 2005
    !!
    logical, public :: ERR_Diffpatt=.false.

    !!----
    !!---- ERR_DIFFPATT_MESS
    !!----    character(len=150), public :: ERR_DiffPatt_Mess
    !!----
    !!----    String containing information about the last error
    !!----
    !!---- Update: February - 2005
    !!
    character(len=150), public :: ERR_DiffPatt_Mess=" "

    !---- Interfaces - Overlap ----!
    Interface Read_Pattern
       Module procedure Read_Pattern_Mult
       Module procedure Read_Pattern_One
    End Interface

 Contains
    !-------------------!
    !---- Functions ----!
    !-------------------!

    !!----
    !!---- Function Calc_FWHM_Peak(Pat, Xi, Yi, Ybi, Rlim) Result(v)
    !!----    type(Diffraction_Pattern_Type), intent(in) :: Pat        ! Profile information
    !!----    real(kind=cp),                  intent(in) :: Xi         ! X value on point i (Peak)
    !!----    real(kind=cp),                  intent(in) :: Yi         ! Y Value on point i
    !!----    real(kind=cp),                  intent(in) :: Ybi        ! Y value for Background on point i
    !!----    real(kind=cp),optional          intent(in) :: RLim       ! Limit range in X units to search the point
    !!----    real(kind=cp)                              :: V
    !!----
    !!---- Function that calculate the FHWM of a peak situated on (xi,yi). Then
    !!---- the routine search the Ym value in the range (xi-rlim, xi+rlim) to
    !!---- obtain the FWHM. The function return a negative values if an error
    !!---- is ocurred during calculation.
    !!----
    !!---- Update: April - 2009
    !!
    Function Calc_FWHM_Peak(Pat, Xi, Yi, Ybi, RLim) Result(v)
       !---- Arguments ----!
       type(Diffraction_Pattern_Type), intent(in) :: Pat
       real(kind=cp),                  intent(in) :: Xi
       real(kind=cp),                  intent(in) :: Yi
       real(kind=cp),                  intent(in) :: Ybi
       real(kind=cp),optional,         intent(in) :: RLim
       real(kind=cp)                              :: V

       !---- Local variables ----!
       integer        :: j, i1, j1,n,nlim
       real(kind=cp)  :: xml, xmr, ym, x1, x2, y1, y2
       real(kind=cp)  :: difx


       ! Init value
       call init_err_Diffpatt()
       v=-1.0

       ! Y value for FHWM
       ym=0.5*(yi-ybi) + ybi

       ! Limit to search
       difx=pat%x(2)-pat%x(1)
       if (present(rlim)) then
          nlim=nint(rlim/difx)
       else
          nlim=nint(0.5/difx)     ! 0.5�
       end if

       ! Locating the index that X(i1) <= x < X(i1+1)
       i1=0
       i1=locate(Pat%x,Pat%npts,xi)
       if (i1 <=0 .or. i1 > Pat%npts) then
          ERR_Diffpatt=.true.
          ERR_Diffpatt_Mess='The index for X(i1) <= x < X(i1+1) was zero!'
          return
       end if

       ! Searching on Left side: Y(j1) <= ym < Y(j1+1)
       n=max(1,i1-nlim)
       j1=0
       do j=i1,n,-1
          if (pat%y(j) < ym) then
             j1=j
             exit
          end if
       end do
       if (j1 <= 0) j1=i1

       x1=Pat%x(j1)
       y1=Pat%y(j1)
       x2=Pat%x(j1+1)
       y2=Pat%y(j1+1)
       xml= x1 + ((ym-y1)/(y2-y1) )*(x2-x1)

       ! Searching on Right side: Y(j1) <= yn < Y(j1+1)
       n=min(i1+nlim,pat%npts)
       j1=0
       do j=i1,n
          if (pat%y(j) < ym) then
             j1=j
             exit
          end if
       end do
       if (j1 ==0) j1=i1

       x1=Pat%x(j1-1)
       y1=Pat%y(j1-1)
       x2=Pat%x(j1)
       y2=Pat%y(j1)
       xmr= x1 + ((ym-y1)/(y2-y1) )*(x2-x1)

       v=xmr-xml

       return
    End Function Calc_FWHM_Peak

    !---------------------!
    !---- Subroutines ----!
    !---------------------!

    !!----
    !!---- Subroutine Add_Diffraction_Patterns(PatternsIn,N,Active,Pat,VNorm)
    !!----    type(Diffraction_Pattern_Type),dimension(:), intent(in)  :: PatternsIn
    !!----    integer,                                     intent(in)  :: N
    !!----    logical, dimension(:),                       intent(in)  :: Active
    !!----    type(Diffraction_Pattern_Type),              intent(out) :: Pat
    !!----    real, optional                               intent(in)  :: VNorm
    !!----
    !!---- Add Patterns
    !!----
    !!---- Date: 25/03/2011
    !!
    Subroutine Add_Diffraction_Patterns(Patterns,N,Active, Pat, VNorm)
        !---- Arguments ----!
        type(Diffraction_Pattern_Type),dimension(:), intent(in)  :: Patterns
        integer,                                     intent(in)  :: N
        logical, dimension(:),                       intent(in)  :: Active
        type(Diffraction_Pattern_Type),              intent(out) :: Pat
        real, optional,                              intent(in)  :: VNorm

        !---- Local Variables ----!
        integer                           :: i,j,k,npts,nc,np
        real                              :: xmin,xmax,step,x1,x2,y,cnorm,fac
        real, dimension(:,:), allocatable :: d2y

        ! Init
        call Init_Err_DiffPatt()
        Pat%npts=0

        !> Checking
        if (N <= 0) return
        ! if (all(active) == .false.) return
        if (all(active) .eqv. .false.) return

        !> Initial values
        xmin=minval(Patterns(1:N)%xmin, mask= (active .eqv. .true.) )
        xmax=maxval(Patterns(1:N)%xmax, mask= (active .eqv. .true.) )

        npts=maxval(Patterns(1:N)%npts, mask= (active .eqv. .true.) )
        if (npts <= 0) then
           ERR_DiffPatt=.true.
           ERR_DiffPatt_Mess="Number of Points in the new Pattern was zero! "
           return
        end if

        step=minval(Patterns(1:N)%step, mask= (active .eqv. .true.) )
        if (abs(step) <= 0.00001) then
           ERR_DiffPatt=.true.
           ERR_DiffPatt_Mess="Step size in the new Pattern was close to zero! "
           return
        end if

        !> Second Derivative
        if (allocated(d2y)) deallocate(d2y)
        allocate(d2y(npts,n))
        d2y=0.0
        do i=1,n
           if (.not. active(i)) cycle
           call second_derivative(Patterns(i)%x,Patterns(i)%y,Patterns(i)%npts,d2y(:,i))
        end do

        np=nint((xmax-xmin)/step)+1

        !> Allocating New Pat
        call Allocate_Diffraction_Pattern (Pat, np)

        if (present(vnorm)) then
           cnorm=vnorm
        else
           cnorm=maxval(Patterns(1:N)%ymax, mask= (active .eqv. .true.) )
        end if

        do j=1,np
           Pat%x(j)=xmin + (j-1)*step
           nc=0
           do i=1,N
              if (.not. active(i) ) cycle
              x1=minval(Patterns(i)%x)
              x2=maxval(Patterns(i)%x)
              k=locate(Patterns(i)%x,Patterns(i)%npts,Pat%x(j))
              if (k == 0) cycle
              nc=nc+1
              call splint(Patterns(i)%x,Patterns(i)%y,d2y(:,i),Patterns(i)%npts,Pat%x(j),y)
              fac=cnorm/Patterns(i)%ymax
              Pat%y(j)=Pat%y(j)+ y*fac
              Pat%sigma(j)=Pat%sigma(j)+ Patterns(i)%sigma(k)
           end do

           ! control
           if (nc > 0) then
              Pat%y(i)=Pat%y(i)/real(nc)
              Pat%sigma(i)=abs(Pat%sigma(i))/real(nc*nc)  ! No lo tengo muy claro
              Pat%nd(i)=nc
           else
              Pat%y(i)=0.0
              Pat%sigma(i)=1.0
              Pat%nd(i)=0
           end if
        end do

        Pat%Monitor=cnorm
        Pat%xmin=xmin
        Pat%xmax=xmax
        Pat%step=step
        Pat%ymin=minval(Pat%y)
        Pat%ymax=maxval(Pat%y)

        return
    End Subroutine Add_Diffraction_Patterns

    !!----
    !!---- Subroutine Allocate_Diffraction_Pattern(pat,npts)
    !!----    type(Diffraction_Pattern_Type), intent (in out) :: pat
    !!----    Integer,                        intent (in)     :: npts
    !!----
    !!----    Allocate the object pat of type Diffraction_Pattern_Type
    !!----
    !!---- Update: December - 2005
    !!
    Subroutine Allocate_Diffraction_Pattern(Pat,Npts)
       !---- Arguments ----!
       type(Diffraction_Pattern_Type), intent (in out) :: pat
       Integer, optional,              intent (in)     :: npts

       !---- Local variables ----!
       integer :: n

       if (present(npts)) then
          pat%npts=npts
          n=npts
       else
          n=pat%npts
       end if

       if (n <= 0) then
          err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Attempt to allocate Diffraction_Pattern with 0-dimension "
          return
       end if

       if (allocated(pat%y) ) deallocate(pat%y)
       allocate(pat%y(n))
       pat%y=0.0
       pat%gy=.true.
       pat%al_y=.true.

       if (allocated(pat%ycalc) ) deallocate(pat%ycalc)
       allocate(pat%ycalc(n))
       pat%ycalc=0.0
       pat%gycalc=.true.
       pat%al_ycalc=.true.

       if (allocated(pat%bgr) ) deallocate(pat%bgr)
       allocate(pat%bgr(n))
       pat%bgr=0.0
       pat%gbgr=.true.
       pat%al_bgr=.true.

       if (allocated(pat%x) ) deallocate(pat%x)
       allocate(pat%x(n))
       pat%x=0.0
       pat%al_x=.true.

       if (allocated(pat%sigma) ) deallocate(pat%sigma)
       allocate(pat%sigma(n))
       pat%sigma=0.0
       pat%gsigma=.true.
       pat%al_sigma=.true.

       if (allocated(pat%istat) ) deallocate(pat%istat)
       allocate(pat%istat(n))
       pat%istat=1
       pat%al_istat=.true.

       if (allocated(pat%nd) ) deallocate(pat%nd)
       allocate(pat%nd(n))
       pat%nd=0

       return
    End Subroutine Allocate_Diffraction_Pattern

    !!----
    !!---- Subroutine Calc_BackGround(Pat, Ncyc, Np, Xmin, Xmax)
    !!----    type(Diffraction_Pattern_Type), intent(in out) :: Pat
    !!----    integer,                        intent(in)     :: Ncyc
    !!----    integer,                        intent(in)     :: Np
    !!----    real(kind=cp), optional,        intent(in)     :: Xmin
    !!----    real(kind=cp), optional,        intent(in)     :: Xmax
    !!----
    !!----    Calculate a Background using an iterative process according
    !!----    to Br�ckner, S. (2000). J. Appl. Cryst., 33, 977-979.
    !!----
    !!----
    !!---- Update: December - 2008
    !!
    Subroutine Calc_BackGround(Pat,Ncyc,Np, Xmin, Xmax)
       !---- Arguments ----!
       type(Diffraction_Pattern_Type), intent(in out) :: Pat
       integer,                        intent(in)     :: NCyc
       integer,                        intent(in)     :: Np
       real(kind=cp), optional,        intent(in)     :: Xmin
       real(kind=cp), optional,        intent(in)     :: Xmax

       !---- Variables ----!
       integer                                 :: n,n_ini,n_fin
       integer                                 :: i,j,k,ind1,ind2,nt
       real(kind=cp),dimension(:), allocatable :: yc,yb
       real(kind=cp)                           :: x_ini,x_fin, yc_min, yc_max, yc_ave

       !---- Initializing errors ----!
       call init_err_diffpatt()

       !---- Check Pattern ----!
       if (pat%npts < 1) then
          err_diffpatt=.true.
          err_diffpatt_mess='No Pattern points are defined'
          return
       end if

       !---- Number of points into the range ----!
       x_ini=pat%xmin
       x_fin=pat%xmax
       if (present(xmin)) x_ini=xmin
       if (present(xmax)) x_fin=xmax
       nt=0
       do i=1,pat%npts
          if (pat%x(i) < x_ini) cycle
          if (pat%x(i) > x_fin) cycle
          nt=nt+1
       end do
       if (nt < 1) then
          err_diffpatt=.true.
          err_diffpatt_mess='No background points was determined into the range'
          return
       end if

       !---- Locating index that define the range to study ----!
       ind1=0
       if (abs(x_ini-pat%xmin) <= 0.0001) then
          ind1=1
       else
          ind1=locate(pat%x,pat%npts,x_ini)
          ind1=max(ind1,1)
          ind1=min(ind1,pat%npts)
       end if

       ind2=0
       if (abs(x_fin-pat%xmax) <= 0.0001) then
          ind2=pat%npts
       else
          ind2=locate(pat%x,pat%npts,x_fin)
          ind2=min(ind2,pat%npts)
          ind2=max(ind2,1)
       end if

       if (ind1 == ind2) then
          err_diffpatt=.true.
          err_diffpatt_mess='Lower and Upper index for Xmin and Xmax are the same'
          return
       end if
       if (ind1 > ind2) then
          i=ind1
          ind1=ind2
          ind2=i
       end if

       if (ind2-ind1+1 /= nt) then
          err_diffpatt=.true.
          err_diffpatt_mess='Error in total numbers of points into the defined range'
          return
       end if

       !---- Allocating arrays ----!
       allocate(yc(nt+2*np))
       allocate(yb(nt+2*np))
       yc=0.0

       !---- Load initial values ----!
       n_ini=np+1
       n_fin=np+nt
       yc(1:np)=pat%y(ind1)
       yc(n_ini:n_fin)=pat%y(ind1:ind2)
       yc(n_fin+1:n_fin+np)=pat%y(ind2)

       yc_min=minval(pat%y(ind1:ind2))
       yc_ave=sum(pat%y(ind1:ind2))/real(nt)
       yc_max=yc_ave+2.0*(yc_ave-yc_min)
       where(yc > yc_max) yc=yc_max

       !---- Main cycles ----!
       do n=1,ncyc
          yb=0.0
          do k=n_ini,n_fin ! Points Observed
             do i=-np,np
                if (i == 0) cycle
                j=k+i
                yb(k)=yb(k)+yc(j)
             end do
             yb(k)=yb(k)/real(2*np)
          end do
          do k=n_ini,n_fin
             j=k-np+ind1-1
             if (yb(k) > pat%y(j)) yb(k)=pat%y(j)
          end do
          yb(1:np)=yb(n_ini)
          yb(n_fin+1:n_fin+np)=yb(n_fin)
          yc=yb
       end do

       !---- save the result ----!
       pat%bgr=0.0
       pat%bgr(ind1:ind2)=yc(n_ini:n_fin)

       !---- Deallocating arrays ----!
       if (allocated(yc))deallocate(yc)
       if (allocated(yb))deallocate(yb)

       return
    End Subroutine Calc_BackGround

    !!----
    !!---- Subroutine Delete_Noisy_Points(Pat, NoisyP, FileInfo)
    !!----    type(Diffraction_Pattern_Type), intent(in out) :: Pat
    !!----    integer,                        intent(out)    :: NoisyP
    !!----    logical, optional,              intent(in)     :: FileInfo
    !!----
    !!---- Delete noisy points in a Pattern. If FileInfo is .true. then a
    !!---- file is created containing information about the elimination of
    !!---- noisy points
    !!----
    !!---- Date: 26/03/2011
    !!
    Subroutine Delete_Noisy_Points(Pat, NoisyP, FileInfo)
        !---- Arguments ----!
        type(Diffraction_Pattern_Type), intent(in out) :: Pat
        integer,                        intent(out)    :: NoisyP
        logical, optional,              intent(in)     :: FileInfo

        !---- Local Variables ----!
        logical                         :: info
        integer                         :: i,j,nomo1,nomo2,lun
        real, dimension(5)              :: cc
        real                            :: suma,sc,dif1,dif2
        real                            :: ci2,ci1,c,cd1,cd2,cn
        real, dimension(:), allocatable :: yc

        !> Initializing errors
        call init_err_diffpatt()

        info=.false.
        if (present(FileInfo)) info=FileInfo
        NoisyP=0

        !> Check Pattern
        if (pat%npts < 1) then
           err_diffpatt=.true.
           err_diffpatt_mess='No Pattern points are defined'
           return
        end if

        if (info) then
           call Get_LogUnit(lun)
           open(unit=lun, file='NoisyPoints.inf')
           write(unit=lun,fmt='(a/)')  " => Analysis of Noisy points of Pattern "//trim(Pat%title)
           write(unit=lun,fmt='(/a/)') " => A Noisy point means the following:"
           write(unit=lun,fmt='(a/)')  "        NoMono .and. Iosci = .true. "
           write(unit=lun,fmt='(a/)')  " where:"
           write(unit=lun,fmt='(a)')   "     ci2 : counts at          left-left position"
           write(unit=lun,fmt='(a)')   "     ci1 : counts at               left position"
           write(unit=lun,fmt='(a)')   "     cc  : counts at            current position"
           write(unit=lun,fmt='(a)')   "     cd1 : counts at              right position"
           write(unit=lun,fmt='(a)')   "     cd2 : counts at              right position"
           write(unit=lun,fmt='(a)')   "     sc  : 8.0*sqrt((ci1+ci2+cd1+cd2)/4.0)"
           write(unit=lun,fmt='(a)')   "     dif1: cc -2.0*ci1+ci2"
           write(unit=lun,fmt='(a)')   "     dif2: cc -2.0*cd1+cd2"
           write(unit=lun,fmt='(a)')   "    Iosci: .not.(dif1 < sc .or. dif2 < sc)"
           write(unit=lun,fmt='(a)')   "   NoMono: Non monotonic ci2,ci1,cc,cd1,cd2"
           write(unit=lun,fmt='(a/)')  "  cc(new): 0.5*(ci1+cd1)"
        end if

        !> Copy Y values
        if (allocated(yc)) deallocate(yc)
        allocate(yc(Pat%npts))
        yc=Pat%y

        cyc_1: do j=3,Pat%npts-2
           suma=0.0
           do i=1,5
              cc(i)=yc(i+j-3)
              if (cc(i) <= 0.0) cycle cyc_1
              if (i /= 3) suma=suma+cc(i)
           end do
           nomo1=0
           nomo2=0
           do i=2,5
              if (cc(i) > cc(i-1)) nomo1=nomo1+1
              if (cc(i) < cc(i-1)) nomo2=nomo2+1
           end do
           if (nomo1 == 4 .or. nomo2 == 4) cycle cyc_1
           sc=4.0*sqrt(suma)
           dif1=cc(3)-2.0*cc(1)+cc(2)
           dif2=cc(3)-2.0*cc(4)+cc(5)
           if (.not. (dif1 <= sc .or. dif2 <= sc) ) then
              if (info) then
                 ci2=cc(1)
                 ci1=cc(2)
                 c=cc(3)
                 cd1=cc(4)
                 cd2=cc(5)
                 cn=0.5*(ci1+cd1)
                 write(unit=lun,fmt='(a,2i6,2(a,i6),a,a,2i6)') "   Counts-left: ",nint(ci2),nint(ci1), &
                                                               " Counts: ",nint(c)," (",nint(cn),")",  &
                                                               " Counts-right: ",nint(cd1),nint(cd2)
              end if
              noisyp=noisyp+1
              yc(j)=0.5*(yc(j-1)+yc(j+1))
           end if
        end do cyc_1

        if (info) then
           select case (noisyP)
              case (0)
                 write(unit=lun,fmt='(/a)')  " => No noisy points were found for this Pattern!"
              case (1)
                 write(unit=lun,fmt='(/a)')  " => Only one noisy point was found for this Pattern!"
              case (2:)
                 write(unit=lun,fmt='(/a,i3,a)')  " => A ",noisyP," noisy points were found for this Pattern!"
           end select
           close(unit=lun)
        end if

        Pat%y=yc

        return
    End Subroutine Delete_Noisy_Points

    !!----
    !!---- Subroutine Init_Err_DiffPatt()
    !!----
    !!----    Initialize the errors flags in DiffPatt
    !!----
    !!---- Update: February - 2005
    !!
    Subroutine Init_Err_DiffPatt()

       ERR_DiffPatt=.false.
       ERR_DiffPatt_Mess=" "

       return
    End Subroutine Init_Err_Diffpatt

    !!----
    !!---- Subroutine Purge_Diffraction_Pattern(Pat,Mode)
    !!----    type(Diffraction_Pattern_Type), intent (in out) :: Pat
    !!----    Character(len=*),               intent (in)     :: Mode
    !!----
    !!----    De-Allocate components of the object "pat", of type Diffraction_Pattern_Type
    !!----    depending on the value of the MODE string. At present the following MODE
    !!----    values are available:
    !!----      "DATA " -> x,y remain allocated                  (purge sigma,ycalc,bgr,istat)
    !!----      "DATAS" -> x,y,sigma remain allocated            (purge ycalc,bgr,istat)
    !!----      "RIETV" -> x,y,sigma,ycalc,bgr remain allocated  (purge istat)
    !!----      "GRAPH" -> x,y,sigma,istat remain allocated      (purge ycalc, bgr)
    !!----      "PRF  " -> x,y,ycalc,bgr,istat, remain allocated (purge sigma)
    !!----
    !!----
    !!---- Update: December - 2005
    !!
    Subroutine Purge_Diffraction_Pattern(Pat,Mode)
       !---- Arguments ----!
       type(Diffraction_Pattern_Type), intent (in out) :: Pat
       character(len=*),               intent (in)     :: Mode

       Select Case (u_case(Mode))

         Case("DATA")    !Mode: "DATA " -> only x,y remain allocated

            if (allocated(pat%ycalc)) deallocate(pat%ycalc)
            pat%gycalc=.false.
            pat%al_ycalc=.false.

            if (allocated(pat%bgr)) deallocate(pat%bgr)
            pat%gbgr=.false.
            pat%al_bgr=.false.

            if (allocated(pat%sigma)) deallocate(pat%sigma)
            pat%gsigma=.false.
            pat%al_sigma=.false.

            if(allocated(pat%istat)) deallocate(pat%istat)

         Case("DATAS")    !Mode: "DATAS" -> only x,y, sigma remain allocated

            if (allocated(pat%ycalc)) deallocate(pat%ycalc)
            pat%gycalc=.false.
            pat%al_ycalc=.false.

            if (allocated(pat%bgr)) deallocate(pat%bgr)
            pat%gbgr=.false.
            pat%al_bgr=.false.

            if(allocated(pat%istat)) deallocate(pat%istat)

         Case("RIETV")   !Mode: "RIETV" -> x,y,sigma,ycalc,bgr remain allocated

            if (allocated(pat%istat)) deallocate(pat%istat)

         Case("GRAPH")   !Mode: "GRAPH" -> x,y,sigma,istat remain allocated

            if (allocated(pat%ycalc)) deallocate(pat%ycalc)
            pat%gycalc=.false.
            pat%al_ycalc=.false.

            if (allocated(pat%bgr)) deallocate(pat%bgr)
            pat%gbgr=.false.
            pat%al_bgr=.false.

         Case("PRF")

            if (allocated(pat%sigma)) deallocate(pat%sigma)
            pat%gsigma=.false.
            pat%al_sigma=.false.

       End Select

       return
    End Subroutine Purge_Diffraction_Pattern

    !!----
    !!---- Subroutine Read_Backgound_File(bck_file, bck_mode, dif_pat)
    !!----    character (len=*),               intent(in   )    :: bck_file
    !!----    character (len=*),               intent(in   )    :: bck_mode
    !!----    type (diffraction_pattern_type), intent(in out)   :: dif_Pat
    !!----
    !!----    Read background from a file
    !!----
    !!---- Update: February - 2005
    !!
    Subroutine Read_Background_File( Bck_File, Bck_Mode, Dif_Pat)
       !---- Arguments ----!
       character (len=*),               intent(in   )    :: bck_file
       character (len=*),               intent(in   )    :: bck_mode
       type (diffraction_pattern_type), intent(in out)   :: dif_pat

       !---- local variables ----!
       logical                                       :: esta
       character (len=132)                           :: line
       integer                                       :: bck_points
       integer                                       :: i,j,i_bck
       integer                                       :: ier, alloc_error
       real(kind=cp), dimension (:), allocatable     :: bck_v
       real(kind=cp), dimension (:), allocatable     :: bck_p

       call init_err_diffpatt()

       inquire(file=bck_file, exist =esta)
       if (.not. esta) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" The file "//trim(bck_file)//" doesn't exist"
          return
       else
          call get_logunit(i_bck)
          open(unit=i_bck,file=trim(bck_file),status="old",action="read",position="rewind",iostat=ier)
          if (ier /= 0) then
             Err_diffpatt=.true.
             ERR_DiffPatt_Mess=" Error opening the file: "//trim(bck_file)
             return
          end if
       end if

       i=0
       do
          read(unit=i_bck,fmt="(a)",iostat=ier) line
          if (ier /= 0) exit
          if (len_trim(line) == 0) cycle
          if (index(line,"!") /= 0) cycle
          i=i+1
       end do
       bck_points=i
       rewind(unit = i_bck)

       if (allocated(bck_v)) deallocate(bck_v)
       allocate(bck_v(bck_points+1),stat= alloc_error)
       if (alloc_error /= 0) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Allocation error reading background points"
          return
       end if

       if (allocated(bck_p)) deallocate(bck_p)
       allocate(bck_p(bck_points+1), stat= alloc_error)
       if (alloc_error /= 0) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Allocation error reading background points"
          return
       end if

       read(unit=i_bck,fmt="(a)",iostat=ier) line
       read(unit=i_bck,fmt="(a)",iostat=ier) line

       do j=1, bck_points
          read(unit=i_bck,fmt="(a)",iostat=ier) line
          if (ier /= 0) exit
          if (len_trim(line) == 0) cycle
          read(unit=line, fmt=*, iostat=ier)  bck_p(j), bck_v(j)
          if (ier /= 0) then
             Err_diffpatt=.true.
             ERR_DiffPatt_Mess=" Error reading background file!"
             return
          end if
       end do

       select case (u_case(bck_mode(1:3)))
          case ("POL") ! Polynomial
             call set_background_poly (dif_pat,50.0_cp, bck_p,bck_points )

          case ("INT") ! Interpolation
             call  set_background_inter (dif_pat, bck_v,bck_p, bck_points )

          case default
             Err_diffpatt=.true.
             ERR_DiffPatt_Mess=" Not a valid mode"
             return
       end select

       close(unit=i_bck,iostat=ier)
       if (ier/=0) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Problems closing data file"
          return
       end if

       return
    End Subroutine Read_Background_File

    !!----
    !!---- Subroutine Read_Pattern(Filename, Dif_Pat, Mode)
    !!--<<                   or   (Filename, Dif_Pat, NumPat, Mode)
    !!----    character(len=*),                              intent (in)    :: Filename
    !!----    type (diffraction_pattern_type),               intent (in out):: Dif_Pat
    !!----    character(len=*), optional,                    intent (in)    :: mode
    !!----
    !!----    character(len=*),                              intent (in)    :: Filename
    !!----    type (diffraction_pattern_type), dimension(:), intent (in out):: Dif_Pat
    !!----    integer,                                       intent (out)   :: numpat
    !!----    character(len=*), optional,                    intent (in)    :: mode
    !!-->>
    !!----    Read one pattern from a Filename
    !!----
    !!---- Update: February - 2005
    !!

    !!--++
    !!--++ Subroutine Read_Pattern_D1A_D2B(i_dat,Pat)
    !!--++    integer,                         intent(in)     :: i_dat
    !!--++    type (diffraction_pattern_type), intent(in out) :: pat
    !!--++
    !!--++    (PRIVATE)
    !!--++    Read a pattern for D1A, D2B
    !!--++
    !!--++ Update: February - 2005
    !!
    Subroutine Read_Pattern_D1A_D2B(i_dat,Pat)
       !---- Arguments ----!
       integer,                         intent(in)     :: i_dat
       type (diffraction_pattern_type), intent(in out) :: Pat

       !---- Local Variables ----!
       character(len=180)                           :: txt1
       integer                                      :: i, nlines, j, no, ier
       integer, dimension(:), allocatable           :: iww
       real(kind=cp)                                :: rmoni, rmoniold, cnorm

       call init_err_diffpatt()

       read(unit=i_dat,fmt="(a)",iostat=ier) txt1
       if (ier /= 0) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error in Intensity file, check your instr parameter!"
          return
       end if
       pat%title=txt1
       pat%Tsamp=0.0
       pat%Tset=0.0
       pat%scal=0.0
       pat%monitor=0.0

       read(unit=i_dat,fmt="(tr16,F8.3)",iostat=ier) pat%step
       if (ier /= 0) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error in Intensity file, check your instr parameter!"
          return
       end if

       read(unit=i_dat,fmt="(F8.3)",iostat=ier)pat%xmin
       if (ier /= 0)then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error in Intensity file, check your instr parameter!"
          return
       end if

       read(unit=i_dat,fmt="(2f8.0)",iostat=ier) rmoni,rmoniold
       if (ier /= 0) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error in Intensity file, check your instr parameter!"
          return
       end if
       pat%monitor=rmoni

       if (rmoniold < 1.0) then
          cnorm=1.00
          rmoniold=rmoni
       else
          cnorm=rmoni/rmoniold
       end if

       nlines = nint(18.0/pat%step)
       pat%npts  = 10*nlines
       if (pat%npts <= 0) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error in Intensity file, Number of points negative or zero!"
          return
       end if

       call Allocate_Diffraction_Pattern(pat)

       if(allocated(iww) ) deallocate(iww)
       allocate(iww(pat%npts))

       j=0
       do i=1,nlines
          read(unit=i_dat,fmt="(10(i2,f6.0))",iostat=ier)(iww(j+no),pat%y(j+no),no=1,10)
          if (ier /= 0) then
             Err_diffpatt=.true.
             ERR_DiffPatt_Mess=" Error in Intensity file, check your instr parameter!"
             return
          end if
          if(abs(pat%y(j+1)+1000.0) < 1.0e-03) exit
          j = j+10
       end do
       j=j-10
       pat%npts=j
       pat%xmax = pat%xmin+(pat%npts-1)*pat%step
       do i=1,pat%npts
          if (pat%y(i) <= 0.00001) pat%y(i) = 1.0
          if (iww(i) == 0) iww(i) = 1
          pat%sigma(i) = cnorm*pat%y(i)/real(iww(i))
          pat%x(i)= pat%xmin+(i-1)*pat%step
       end do
       pat%ymin=minval(pat%y(1:pat%npts))
       pat%ymax=maxval(pat%y(1:pat%npts))
       return
    End Subroutine Read_Pattern_D1A_D2B

    !!--++
    !!--++ Subroutine Read_Pattern_D1A_D2B_OLD(i_dat,Pat)
    !!--++    integer,                         intent(in)     :: i_dat
    !!--++    type (diffraction_pattern_type), intent(in out) :: Pat
    !!--++
    !!--++    Read a pattern for D1A, D2B (Old Format)
    !!--++
    !!--++ Update: February - 2005
    !!
    Subroutine Read_Pattern_D1A_D2B_OLD(i_dat,Pat)
       !---- Arguments ----!
       integer,                         intent(in)     :: i_dat
       type (diffraction_pattern_type), intent(in out) :: Pat

       !---- Local Variables ----!
       integer                                      :: ier,i
       integer, dimension(:), allocatable           :: iww

       call init_err_diffpatt()

       read(unit=i_dat,fmt=*,iostat=ier)pat%xmin,pat%step,pat%xmax
       if (ier /= 0) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error in Intensity file, check your instr parameter!"
          return
       end if
       pat%title=" No title: data format -> old D1A"
       pat%Tsamp=0.0
       pat%Tset=0.0
       pat%scal=0.0
       pat%monitor=0.0

       pat%npts = (pat%xmax-pat%xmin)/pat%step+1.5
       if (pat%npts <= 0) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error in Intensity file, Number of points negative or zero!"
          return
       end if

       call Allocate_Diffraction_Pattern(pat)

       if(allocated(iww) ) deallocate(iww)
       allocate(iww(pat%npts))

       read(unit=i_dat,fmt="(10(i2,f6.0))",iostat=ier)(iww(i),pat%y(i),i=1,pat%npts)
       if (ier /= 0) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error in Intensity file, check your instr parameter!"
          return
       end if

       do i=1,pat%npts
          if (pat%y(i) <= 0.00001) pat%y(i) = 1.0
          if (iww(i) == 0) iww(i) = 1
          pat%sigma(i) = pat%y(i)/real(iww(i))
          pat%x(i)= pat%xmin+(i-1)*pat%step
       end do
       pat%ymin=minval(pat%y(1:pat%npts))
       pat%ymax=maxval(pat%y(1:pat%npts))

       return
    End Subroutine Read_Pattern_D1A_D2B_Old

    !!--++
    !!--++ Subroutine Read_Pattern_D1B_D20(i_dat,Pat)
    !!--++    integer,                         intent(in)     :: i_dat
    !!--++    type (diffraction_pattern_type), intent(in out) :: Pat
    !!--++
    !!--++    Read a pattern for D1B or D20
    !!--++
    !!--++ Update: February - 2005
    !!
    Subroutine Read_Pattern_D1B_D20(i_dat,Pat)
       !---- Arguments ----!
       integer,                         intent(in)     :: i_dat
       type (diffraction_pattern_type), intent(in out) :: pat

       !---- Local Variables ----!
       character(len=180)                           :: line
       integer                                      :: i,j,ier
       integer, dimension(:), allocatable           :: iww
       real(kind=cp)                                :: aux

       call init_err_diffpatt()

       do i=1,3
          read(unit=i_dat,fmt="(a)", iostat=ier)line
          if (ier /= 0 )then
             Err_diffpatt=.true.
             ERR_DiffPatt_Mess=" Error in  Intensity file, check your instr parameter!"
             return
          end if
          if( i == 2) pat%title=line
       end do
       pat%title=trim(pat%title)//" "//trim(line)

       read(unit=i_dat,fmt="(f13.0,tr10,f8.3,tr45,4f9.3)  ",iostat=ier) pat%monitor,pat%xmin,pat%step,pat%tset,aux,pat%tsamp
       if (ier /= 0 ) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error in Intensity file, check your instr parameter!"
          return
       end if

       read(unit=i_dat,fmt="(i4)",iostat=ier) pat%npts
       if (ier /= 0 )then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error in Intensity file, check your instr parameter!"
          return
       end if

       if (pat%npts <= 0) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error in Intensity file, Number of points negative or zero!"
          return
       end if

       call Allocate_Diffraction_Pattern(pat)

       if(allocated(iww)) deallocate(iww)
       allocate(iww(pat%npts))

       read(unit=i_dat,fmt="(10(i2,f8.0))",iostat=ier) (iww(j),pat%y(j),j=1,pat%npts)

       if (ier /= 0 )then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error in  Intensity file, check your instr parameter!"
          return
       end if

       pat%xmax = pat%xmin+(pat%npts-1)*pat%step

       read(unit=i_dat,fmt=*,iostat=ier)line
       if (ier /= 0 )then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error in Intensity file, check your instr parameter!"
          return
      end if

       do i=1,pat%npts
          if (pat%y(i) <= 0.00001) pat%y(i) = 1.0
          if (iww(i) <= 0) iww(i) = 1
          pat%sigma(i) = pat%y(i)/REAL(iww(i))
          pat%x(i)= pat%xmin+(i-1)*pat%step
       end do
       pat%ymin=minval(pat%y(1:pat%npts))
       pat%ymax=maxval(pat%y(1:pat%npts))
       return
    End Subroutine Read_Pattern_D1B_D20

    !!--++
    !!--++ Subroutine Read_Pattern_Dmc(i_dat,Pat)
    !!--++    integer,                         intent(in)     :: i_dat
    !!--++    type (diffraction_pattern_type), intent(in out) :: Pat
    !!--++
    !!--++    Read a pattern for DMC
    !!--++
    !!--++ Update: February - 2005
    !!
    Subroutine Read_Pattern_Dmc(i_dat,Pat)
       !---- Arguments ----!
       integer,                         intent(in)     :: i_dat
       type (diffraction_pattern_type), intent(in out) :: Pat

       !---- Local Variables ----!
       character(len=180)                           :: txt1
       integer                                      :: ier, i

       call init_err_diffpatt()

       read(unit=i_dat,fmt="(A)",iostat=ier)txt1
       if (ier /= 0) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error in Intensity file (first line), check your instr parameter!"
          return
       end if
       pat%title=txt1
       pat%tsamp=0.0
       pat%tset=0.0
       pat%scal=0.0
       pat%monitor=0.0

       read(unit=i_dat,fmt="(A)",iostat=ier)txt1
       if (ier /= 0) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error in Intensity file (second line), check your instr parameter!"
          return
       end if

       read(unit=i_dat,fmt=*,iostat=ier) pat%xmin,pat%step,pat%xmax
       if (ier /= 0) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error reading 2theta_min,step,2theta_max (third line), check your instr parameter!"
          return
       end if
       pat%npts = (pat%xmax - pat%xmin)/pat%step + 1.005
       if (pat%npts < 20)then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Number of points too low! check your instr parameter!"
          return
       end if

       call Allocate_Diffraction_Pattern(pat)

       read(unit=i_dat,fmt="(10f8.0)",iostat=ier)(pat%y(i),i=1,pat%npts)
       if (ier > 0) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error in Intensity file (intensities), check your instr parameter!"
          return
       end if

       read(unit=i_dat,fmt="(10f8.0)",iostat=ier)(pat%sigma(i),i=1,10)
       if (ier /= 0) then      !Sigmas are not provided, assume sigma=sqrt(Y)
         pat%sigma(1:pat%npts) =sqrt(pat%y(1:pat%npts))
       else
         backspace (unit=i_dat)
         read(unit=i_dat,fmt="(10f8.0)",iostat=ier)(pat%sigma(i),i=1,pat%npts)
         if (ier /= 0) then
            Err_diffpatt=.true.
            ERR_DiffPatt_Mess=" Error in Intensity file (sigmas), check your instr parameter!"
            return
         end if
       end if

       do i=1,pat%npts
         pat%sigma(i) = pat%sigma(i)*pat%sigma(i)
         pat%x(i)= pat%xmin+(i-1)*pat%step
       end do
       pat%ymin=minval(pat%y(1:pat%npts))
       pat%ymax=maxval(pat%y(1:pat%npts))
       return
    End Subroutine Read_Pattern_Dmc

    !!--++
    !!--++ Subroutine Read_Pattern_Free(i_dat,Pat)
    !!--++    integer,                         intent(in)     :: i_dat
    !!--++    type (diffraction_pattern_type), intent(in out) :: Pat
    !!--++
    !!--++    Read a pattern for Free
    !!--++
    !!--++ Update: February - 2005
    !!
    Subroutine Read_Pattern_Free(i_dat,Pat)
       !---- Arguments ----!
       integer,                         intent(in)     :: i_dat
       type (diffraction_pattern_type), intent(in out) :: Pat

       !---- Local Variables ----!
       integer                                      :: i,no,ier,inum,nc,iv
       integer, dimension(3)                        :: ivet
       character(len=180)                           :: aline
       character(len=20), dimension(10)             :: dire
       real, dimension(3)                           :: vet
       logical                                      :: title_given

       call init_err_diffpatt()
       title_given=.false.
       no=0
       pat%tsamp=0.0
       pat%tset=0.0
       pat%scal=0.0
       pat%monitor=0.0
       pat%xmin=0.0
       pat%xmax=0.0
       pat%step=0.0

       do
          read(unit=i_dat,fmt="(a)",iostat=ier) aline
          if (ier /= 0) then
             Err_diffpatt=.true.
             ERR_DiffPatt_Mess=" End of file *.dat"
             return
          end if
          aline=adjustl(aline)

          ! Comment lines using ! or #
          if (aline(1:1) == "!" .or. aline(1:1) == "#") cycle

          ! BANK Information
          if (aline(1:4) == "BANK") then
             read(unit=aline(5:41),fmt=*) inum,pat%npts
             read(unit=aline(47:90),fmt=*) pat%xmin,pat%step
             pat%xmax=pat%xmin+(pat%npts-1)*pat%step
             exit
          end if

          ! Reading Xmin, Step, Xmax, Title (optional)
          call getword(aline,dire,nc)
          if (nc > 2) then
             call getnum(trim(dire(1))//' '//trim(dire(2))//' '//trim(dire(3)),vet,ivet,iv)
             if (iv == 3) then
                pat%xmin=vet(1)
                pat%step=vet(2)
                pat%xmax=vet(3)

                if (pat%step <= 1.0e-6 ) then
                   Err_diffpatt=.true.
                   ERR_DiffPatt_Mess=" Error in Intensity file, Step value was zero!"
                   return
                end if

                !pat%npts = (pat%xmax-pat%xmin)/pat%step+1.5
                pat%npts = nint((pat%xmax-pat%xmin)/pat%step+1.0)

                ! Title?
                i=index(aline,trim(dire(3)))
                nc=len_trim(dire(3))

                if (len_trim(aline(i+nc+1:)) > 0) then
                   Pat%title=trim(aline(i+nc+1:))
                   title_given=.true.
                end if

                exit  ! Salida del Bucle
             end if

             ! TSAMP
             i=index(aline,"TSAMP")
             if (i /= 0) then
                read(unit=aline(i+5:),fmt=*,iostat=ier) pat%tsamp
                if (ier /= 0) pat%tsamp = 0.0
             end if
          end if

          ! Probably Coment line or Title
          if(.not. title_given) then
            Pat%title=trim(aline)
            title_given=.true.
          end if

          no=no+1
          if (no > 7)then
             Err_diffpatt=.true.
             ERR_DiffPatt_Mess=" Error on Intensity file, Number of Comment lines was exceeded ( > 7) !"
             return
          else
             cycle
          end if
       end do

       ! Aditional checks
       if (pat%npts <= 10 .or. pat%xmax <  pat%xmin  .or. pat%step > pat%xmax) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error in Intensity file, Problems reading 2Theta_ini, Step, 2Theta_end !"
          return
       end if

       ! Allocating memory
       call Allocate_Diffraction_Pattern(pat)

       ! Reading intensities values
       read(unit=i_dat,fmt=*,iostat=ier)(pat%y(i),i=1,pat%npts)
       if (ier /= 0) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error in Intensity file, Number of intensities values is wrong!!"
          return
       end if

       do i=1,pat%npts
          pat%sigma(i) = pat%y(i)
          pat%x(i)= pat%xmin+(i-1)*pat%step
       end do
       pat%ymin=minval(pat%y(1:pat%npts))
       pat%ymax=maxval(pat%y(1:pat%npts))

       return
    End Subroutine Read_Pattern_Free

    !!--++
    !!--++ Subroutine Read_Pattern_G41(i_dat,Pat)
    !!--++    integer,                         intent(in)     :: i_dat
    !!--++    type (diffraction_pattern_type), intent(in out) :: Pat
    !!--++
    !!--++    Read a pattern for G41
    !!--++
    !!--++ Update: February - 2005
    !!
    Subroutine Read_Pattern_G41(i_dat,Pat)
       !---- Arguments ----!
       integer,                         intent(in)     :: i_dat
       type (diffraction_pattern_type), intent(in out) :: Pat

       !---- Local Variables ----!
       character(len=180)                           :: txt1, txt2, txt3
       integer                                      :: i, ier, ivari
       real(kind=cp)                                :: cnorm
       real(kind=cp)                                :: rmon1, rmon2


       call init_err_diffpatt()

       read(unit=i_dat,fmt="(A)",iostat=ier)txt1                  !1
       pat%title=txt1
       if (ier /= 0 ) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error in Intensity file, check your instr parameter! "
          return
       end if

       read(unit=i_dat,fmt="(A)",iostat=ier)txt2                  !2
       if (ier /= 0 ) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error in Intensity file, check your instr parameter! "
          return
       end if

       read(unit=i_dat,fmt="(A)",iostat=ier)txt3                  !3
       if (ier /= 0 ) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error in Intensity file, check your instr parameter! "
          return
       end if
       do
         read(unit=i_dat,fmt="(A)",iostat=ier)txt3
         txt3=adjustl(txt3)
         if(txt3(1:1) /= "!") exit
       end do

       !read(unit=i_dat,fmt="(I6,tr1,2F10.3,i5,2f10.1)",iostat=ier)  pat%npts,pat%tsamp,pat%tset,ivari,rmon1,rmon2
       read(unit=txt3,fmt=*,iostat=ier)  pat%npts,pat%tsamp,pat%tset,ivari,rmon1,rmon2
       if (ier /= 0 )then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error in Intensity file, check your instr parameter! "
          return
       end if
       pat%monitor=rmon1

       if (pat%npts <= 0) then
         Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error in Intensity file, Number of points negative or zero!"
          return
       end if

       call Allocate_Diffraction_Pattern(pat)


       read(unit=i_dat,fmt=*,iostat=ier)pat%xmin,pat%step,pat%xmax              !5
       if (ier /= 0 ) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error in Intensity file, check your instr parameter! "
          return
       end if

       read(unit=i_dat,fmt=*,iostat=ier)(pat%y(i),i=1, pat%npts)
       if (ier /= 0 )then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error in Intensity file, check your instr parameter! "
          return
       end if

       if (ivari /= 0) then          !IVARI
          read(unit=i_dat,fmt=*,iostat=ier)(pat%sigma(i),i=1, pat%npts)
          if (ier /= 0 ) then
             Err_diffpatt=.true.
             ERR_DiffPatt_Mess=" Error in Intensity file, check your instr parameter! "
             return
          end if
          cnorm=0.0
          do i=1,pat%npts
             IF (pat%y(i) < 0.0001) pat%y(i)=0.0001
             pat%sigma(i)=pat%sigma(i)*pat%sigma(i)
             IF (pat%sigma(i) < 0.000001) pat%sigma(i)=1.0
             pat%x(i)= pat%xmin+(i-1)*pat%step
             cnorm=cnorm+pat%sigma(i)/pat%y(i)
          end do
          cnorm=cnorm/REAL(pat%npts)
       else                         !ivari
          if (rmon1 > 1.0 .and. rmon2 > 1.0) then
             cnorm=rmon1/rmon2
          else
             cnorm=1.0
          end if
          do i=1,pat%npts
             pat%sigma(i)=pat%y(i)*cnorm
             pat%x(i)= pat%xmin+(i-1)*pat%step
          end do
       end if                        !IVARI
       pat%ymin=minval(pat%y(1:pat%npts))
       pat%ymax=maxval(pat%y(1:pat%npts))
       return
    End Subroutine Read_Pattern_G41

    !!--++
    !!--++ Subroutine Read_Pattern_Gsas(i_dat,Pat,mode)
    !!--++    integer,                         intent(in)     :: i_dat
    !!--++    type (diffraction_pattern_type), intent(in out) :: Pat
    !!--++    character(len=*), optional       intent(in)     :: mode
    !!--++
    !!--++    Read a pattern for GSAS
    !!--++
    !!--++ Update: February - 2005
    !!
    Subroutine Read_Pattern_Gsas(i_dat,Pat,mode)
       !---- Arguments ----!
       integer,                         intent(in)     :: i_dat
       type (diffraction_pattern_type), intent(in out) :: Pat
       character(len=*), optional,      intent(in)     :: mode

       !---- Local Variables ----!
       logical                                      :: previous, bank_missed
       logical, save                                :: keep_open=.false.
       character (len=80)                           :: line
       character (len=8 )                           :: bintyp,datyp
       integer                                      :: items,i, nbank
       integer                                      :: ibank,nchan,nrec, ier !, jobtyp
       integer,          dimension(:), allocatable  :: iww
       integer,          dimension(40)              :: pointi, pointf
       real(kind=cp),    dimension(4)               :: bcoef
       real(kind=cp)                                :: divi
       real(kind=cp)                                :: cnorm
       logical                                      :: ok
       logical                                      :: tof !used only for some type of formats

       call init_err_diffpatt()
       ok=.false.
       pat%tsamp=0.0
       pat%tset=0.0
       pat%scal=0.0
       pat%monitor=0.0
       if(present(mode)) then
         divi=1.0
         tof=.true.
         i=len_trim(mode)
         if(i == 3) then
            nbank=1
         else
            read(unit=mode(4:),fmt=*,iostat=ier) nbank       !tofn
            if(ier /= 0) nbank=1
         end if
       else
         nbank=1
         divi=100.0
         tof=.false.
       end if
       if ( .not. keep_open) then
          bank_missed=.true.

          do i=1,7
             read(unit=i_dat,fmt="(a)") line
             if(i == 1) pat%title=line
             if (line(1:4) == "BANK") then
                bank_missed=.false.
                exit
             end if
          end do

          if (bank_missed) then
             Err_diffpatt=.true.
             ERR_DiffPatt_Mess=" => Error in the input GSAS-file: BANK not found!"
             return
          end if
       else
          read(unit=i_dat,fmt="(a)") line
       end if

       look_bank: do
         items=0
         previous=.false.
         do i=5,80   !This is the line with BANK
            if (line(i:i) /= " ") then
               if (.not. previous) then
                  items=items+1
                  pointi(items)=i
                  previous=.true.
               end if
            else
               if (items > 0 .and. previous) pointf(items)=i-1
               previous=.false.
            end if
         end do
         IF (items > 0) read(unit=line(pointi(1):pointf(1)),fmt=*) ibank

         if( ibank /= nbank) then  !Verify that we have the proper bank
            do
             read(unit=i_dat,fmt="(a)",iostat=ier) line  !continue reading the file up to finding
             if(ier /= 0) then
               Err_diffpatt=.true.
               write(unit=ERR_DiffPatt_Mess,fmt="(a,i2,a)") " Error in Intensity file, BANK number: ",nbank," not found!"
               return
             end if
             if (line(1:4) == "BANK") then               !the good bank
                cycle look_bank
             end if
            end do
         end if

         IF (items > 1) read(unit=line(pointi(2):pointf(2)),fmt=*) nchan
         IF (items > 2) read(unit=line(pointi(3):pointf(3)),fmt=*) nrec
         IF (items > 3) read(unit=line(pointi(4):pointf(4)),fmt="(a)") bintyp
         IF (items > 4) read(unit=line(pointi(5):pointf(5)),fmt=*) bcoef(1)
         IF (items > 5) read(unit=line(pointi(6):pointf(6)),fmt=*) bcoef(2)
         IF (items > 6) read(unit=line(pointi(7):pointf(7)),fmt=*) bcoef(3)
         IF (items > 7) read(unit=line(pointi(8):pointf(8)),fmt=*) bcoef(4)
         datyp="STD"
         IF (items > 8) read(unit=line(pointi(9):pointf(9)),fmt="(a)") datyp
         pat%npts=nchan
         if (pat%npts <= 0)then
            Err_diffpatt=.true.
            ERR_DiffPatt_Mess=" Error in Intensity file, check your instr parameter!"
            return
         end if

         call Allocate_Diffraction_Pattern(pat)

         if(allocated(iww) ) deallocate(iww)
         allocate(iww(pat%npts))

         if (datyp == "STD") then
            pat%ct_step  = .true.
            if (bintyp == "CONST") then
               pat%xmin=bcoef(1)/divi !divide by 100 for CW
               pat%step=bcoef(2)/divi  !divide by 100 for CW
               pat%xmax=pat%xmin+(pat%npts-1)*pat%step
            else
               Err_diffpatt=.true.
               ERR_DiffPatt_Mess=" => Only BINTYP=CONST is allowed for ESD data"
               return
            end if
            if(tof) then
              read(unit=i_dat,fmt="(10f8.0)", iostat=ier) (pat%y(i),i=1,pat%npts)
              if (ier /= 0) then
                 backspace (unit=i_dat)
              end if
              iww(1:pat%npts)=1
            else
              read(unit=i_dat,fmt="(10(i2,f6.0))", iostat=ier) (iww(i),pat%y(i),i=1,pat%npts)
              if (ier /= 0) then
                 backspace (unit=i_dat)
              end if
            end if
            do i=1,pat%npts
               if (pat%y(i) <= 0.00001) pat%y(i) = 1.0
               if (iww(i) == 0) iww(i) = 1
               pat%sigma(i) = pat%y(i)/real(iww(i))
               pat%x(i)=pat%xmin+(i-1)*pat%step
            end do
            cnorm=1.0

         else if(datyp == "ESD") then
            if (bintyp == "CONST") then
               pat%ct_step  = .true.
               pat%xmin=bcoef(1)/divi !divide by 100 for CW
               pat%step=bcoef(2)/divi  !divide by 100 for CW
               pat%xmax=pat%xmin+(pat%npts-1)*pat%step
               read(unit=i_dat,fmt="(10f8.0)",iostat=ier) (pat%y(i),pat%sigma(i),i=1,pat%npts)
               if (ier /= 0) then
                  backspace (unit=i_dat)
               end if
               cnorm=0.0
               do i=1,pat%npts
                  pat%x(i)=pat%xmin+(i-1)*pat%step
                  pat%sigma(i)=pat%sigma(i)*pat%sigma(i)
                  cnorm=cnorm+pat%sigma(i)/max(pat%y(i),0.001_cp)
               end do
               cnorm=cnorm/real(pat%npts)
            else
               Err_diffpatt=.true.
               ERR_DiffPatt_Mess=" => Only BINTYP=CONST is allowed for ESD data"
               return
            end if

         else if(datyp == "ALT") then
            if (bintyp == "RALF") then
               pat%ct_step  = .false.
               read(unit=i_dat,fmt="(4(f8.0,f7.0,f5.0))",iostat=ier)(pat%x(i),pat%y(i),pat%sigma(i),i=1,pat%npts)
               if (ier /= 0) then
                  backspace (unit=i_dat)
               end if
               pat%x=pat%x/32.0
               cnorm=0.0
               do i=1,pat%npts-1
                  divi=pat%x(i+1)-pat%x(i)
                  pat%y(i)=1000.0*pat%y(i)/divi
                  pat%sigma(i)=1000.0*pat%sigma(i)/divi
                  pat%sigma(i)=pat%sigma(i)*pat%sigma(i)
                  cnorm=cnorm+pat%sigma(i)/max(pat%y(i),0.001_cp)
               end do
               cnorm=cnorm/real(pat%npts)
               pat%npts=pat%npts-1
               pat%xmin=bcoef(1)/32.0
               pat%step=bcoef(2)/32.0
               pat%xmax=pat%x(pat%npts)

            else if(bintyp == "CONST") then
               pat%ct_step  = .true.
               read(unit=i_dat,fmt="(4(f8.0,f7.0,f5.0))", iostat=ier)(pat%x(i),pat%y(i),pat%sigma(i),i=1,pat%npts)
               if (ier /= 0) then
                  backspace (unit=i_dat)
               end if
              pat%x=pat%x/32.0
               cnorm=0.0
               do i=1,pat%npts
                  pat%sigma(i)=pat%sigma(i)*pat%sigma(i)
                  cnorm=cnorm+pat%sigma(i)/max(pat%y(i),0.001_cp)
               end do
               cnorm=cnorm/real(pat%npts)
               pat%xmin=bcoef(1)
               pat%step=bcoef(2)
               pat%xmax=pat%x(pat%npts)
            else
               Err_diffpatt=.true.
               ERR_DiffPatt_Mess=" =>  Only BINTYP=RALF or CONST is allowed for ALT data"
            end if
         end if
         exit !we have finished reading the good bank
       end do look_bank

       pat%ymin=minval(pat%y(1:pat%npts))
       pat%ymax=maxval(pat%y(1:pat%npts))
       !---- Checking range and re-select the usable diffraction pattern

       return
    End Subroutine Read_Pattern_Gsas

    !!--++
    !!--++ Subroutine Read_Pattern_Isis_M(i_dat,Pat,NPat)
    !!--++    integer,                                                    intent(in    ) :: i_dat
    !!--++    type (diffraction_pattern_type),  dimension(:),             intent(in out) :: pat
    !!--++    integer,                                                    intent(in out) :: npat
    !!--++
    !!--++    Read a pattern for ISIS
    !!--++
    !!--++ Update: February - 2005
    !!
    Subroutine Read_Pattern_Isis_m(i_dat,Pat,NPat)
       !---- Arguments ----!
       integer,                                                    intent(in    ) :: i_dat
       type (diffraction_pattern_type),  dimension(:),             intent(in out) :: pat
       integer,                                                    intent(in out) :: npat

       !---- Local Variables ----!
       real(kind=cp)                                   :: fac_y
       real(kind=cp)                                   :: cnorm
       real(kind=cp)                                   :: sumavar
       integer                                         :: ntt, i, j, ier
       integer                                         :: n_pat      !index of current pattern
       integer, dimension(npat)                        :: npp        !number of points per pattern
       character(len=120)                              :: txt1
       character(len=132)                              :: aline
       real(kind=cp)                                   :: divi
       real(kind=cp), parameter                        :: eps1=1.0e-1
       logical                                         :: bankfound
       logical, save                                   :: ralf_type, title_given

       call init_err_diffpatt()
       fac_y=1000.0
       npp(:)=0
       n_pat=0
       bankfound=.false.
       title_given=.false.

       do
          read(unit=i_dat,fmt="(a)", iostat = ier) txt1
          if (ier /= 0) exit
          txt1=adjustl(txt1)
          if (txt1(1:4) == "BANK") then
             n_pat=n_pat+1
             npp(n_pat)=0
             bankfound=.true.
             cycle
          end if
          if (bankfound) npp(n_pat)=npp(n_pat)+1
       end do
       rewind(unit=i_dat)

       pat%ct_step = .false.
       pat%tsamp=0.0
       pat%tset=0.0
       pat%scal=0.0
       pat%monitor=0.0

       if (npat <= 0 .or. n_pat > npat) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error in Intensity file, wrong number of patterns !"
          return
       end if

       npat=n_pat !Update the number of patterns

       do n_pat=1,npat
          call Allocate_Diffraction_Pattern(pat(n_pat),npp(n_pat))
       end do

       do
          read(unit=i_dat,fmt="(a)") txt1
          if(.not. title_given) then
            Pat(1)%title=txt1
            title_given=.true.
          end if
          if (txt1(1:4) == "BANK") then
             IF (index(txt1,"RALF") /= 0) ralf_type =.true.
             exit
          end if
          i=index(txt1,"fac_y")
          if (i /= 0) then
             read(unit=txt1(i+5:),fmt=*) fac_y
          end if
       end do

       do n_pat=1,npat
          i=0
          ntt=0
          sumavar=0.0
          cnorm=0.0
          Pat(n_pat)%title=Pat(1)%title

          if (ralf_type) then
             do j=1,npp(n_pat)+1
                read(unit=i_dat,fmt="(a)",iostat=ier) aline
                if (ier /= 0)  exit
                if (aline(1:1) == "!" .or. aline(1:1) == "#") cycle
                if (aline(1:4) == "BANK") exit
                if (len_trim(aline)==0)exit
                i=i+1
                read(unit=aline,fmt=*,iostat=ier) pat(n_pat)%x(i),pat(n_pat)%y(i),pat(n_pat)%sigma(i)
                if (ier /= 0) then
                   Err_diffpatt=.true.
                   ERR_DiffPatt_Mess=" Error reading an ISIS profile DATA file"
                   return
                end if
                if (abs(pat(n_pat)%x(i)) < eps1 .and. pat(n_pat)%y(i) < eps1 .and. pat(n_pat)%sigma(i) < eps1) exit
                pat(n_pat)%y(i)=pat(n_pat)%y(i)*fac_y
                pat(n_pat)%sigma(i)=pat(n_pat)%sigma(i)*fac_y
                pat(n_pat)%sigma(i)=pat(n_pat)%sigma(i)*pat(n_pat)%sigma(i)
                sumavar=sumavar+pat(n_pat)%sigma(i)
                if (pat(n_pat)%sigma(i) < eps1) pat(n_pat)%sigma(i) =fac_y
                if (pat(n_pat)%y(i) < eps1) then
                   pat(n_pat)%y(i)   = eps1
                   pat(n_pat)%sigma(i) = fac_y
                end if
                cnorm=cnorm+pat(n_pat)%sigma(i)/max(pat(n_pat)%y(i),0.001_cp)
                if (i > 1) then
                   pat(n_pat)%step=pat(n_pat)%step+pat(n_pat)%x(i)-pat(n_pat)%x(i-1)
                   ntt=ntt+1
                end if
             end do
             do i=1,ntt
                divi=pat(n_pat)%x(i+1)-pat(n_pat)%x(i)
                pat(n_pat)%y(i)=pat(n_pat)%y(i)/divi
                pat(n_pat)%sigma(i)=pat(n_pat)%sigma(i)/divi/divi
             end do
             ntt=ntt-1

          else

             do j=1,npp(n_pat)
                read(unit=i_dat,fmt="(a)",iostat=ier) aline
                if (ier /= 0) exit
                if (aline(1:1) == "!" .or. aline(1:1) == "#") cycle
                if (aline(1:4) == "BANK") exit
                i=i+1
                read(unit=aline,fmt=*,iostat=ier) pat(n_pat)%x(i),pat(n_pat)%y(i),pat(n_pat)%sigma(i)
                if (ier /= 0) then
                   Err_diffpatt=.true.
                   ERR_DiffPatt_Mess=" Error reading an ISIS profile DATA file"
                   return
                end if
                if(abs(pat(n_pat)%x(i)) < eps1 .and. pat(n_pat)%y(i) < eps1 .and. pat(n_pat)%sigma(i) < eps1) exit
                pat(n_pat)%y(i)=pat(n_pat)%y(i)*fac_y
                pat(n_pat)%sigma(i)=pat(n_pat)%sigma(i)*fac_y
                pat(n_pat)%sigma(i)=pat(n_pat)%sigma(i)*pat(n_pat)%sigma(i)
                sumavar=sumavar+pat(n_pat)%sigma(i)
                if (pat(n_pat)%sigma(i) < eps1) pat(n_pat)%sigma(i) =fac_y
                if (pat(n_pat)%y(i) < eps1) then
                   pat(n_pat)%y(i)   = eps1
                   pat(n_pat)%sigma(i) = fac_y
                end if
                cnorm=cnorm+pat(n_pat)%sigma(i)/max(pat(n_pat)%y(i),0.001_cp)
                if (i > 1) then
                   pat(n_pat)%step=pat(n_pat)%step+pat(n_pat)%x(i)-pat(n_pat)%x(i-1)
                   ntt=ntt+1
                end if
             end do
          end if  !RALF question

          pat(n_pat)%npts=ntt+1
          pat(n_pat)%xmin=pat(n_pat)%x(1)
          pat(n_pat)%xmax=pat(n_pat)%x(pat(n_pat)%npts)
          cnorm=cnorm/real(pat(n_pat)%npts)
          pat(n_pat)%step=pat(n_pat)%step/real(ntt)
          if (sumavar < eps1) then
             do i=1,pat(n_pat)%npts
                pat(n_pat)%sigma(i)=pat(n_pat)%y(i)
             end do
             cnorm=1.0
          end if

        pat(n_pat)%ymin=minval(pat(n_pat)%y(1:pat(n_pat)%npts))
        pat(n_pat)%ymax=maxval(pat(n_pat)%y(1:pat(n_pat)%npts))
      end do !n_pat
      return
    End Subroutine Read_Pattern_Isis_M

    !!--++
    !!--++ Subroutine Read_Pattern_Mult(Filename,Dif_Pat, NumPat, Mode)
    !!--++    character(len=*),                                          intent (in)      :: filename
    !!--++    type (diffraction_pattern_type), dimension(:),             intent (in out)  :: dif_pat
    !!--++    integer,                                                   intent (out)     :: numpat
    !!--++    character(len=*), optional,                                intent (in)      :: mode
    !!--++
    !!--++    (OVERLOADED)
    !!--++    Read one pattern from a Filename
    !!--++
    !!--++ Update: February - 2005
    !!
    Subroutine Read_Pattern_Mult(filename, dif_pat, numpat, mode)
       !---- Arguments ----!
       character(len=*),                                          intent (in)      :: filename
       type (diffraction_pattern_type), dimension(:),             intent (in out)  :: dif_pat
       integer,                                                   intent (in out)  :: numpat
       character(len=*), optional,                                intent (in)      :: mode

       !---- Local variables ----!
       logical :: esta
       integer :: i_dat, ier

       call init_err_diffpatt()

       inquire(file=filename,exist=esta)
       if ( .not. esta) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" The file "//trim(filename)//" doesn't exist"
          return
       else
          call get_logunit(i_dat)
          open(unit=i_dat,file=trim(filename),status="old",action="read",position="rewind",iostat=ier)
          if (ier /= 0) then
             Err_diffpatt=.true.
             ERR_DiffPatt_Mess=" Error opening the file "//trim(filename)
             return
          end if
          dif_pat%filename=trim(filename)
       end if

       if (present(mode)) then
          select case (u_case(mode))
              case ("XYSIGMA")
                 !   call  Read_Pattern_xysigma_m(dif_pat,npat)

              case ("ISIS")
                 call Read_Pattern_isis_m(i_dat,dif_pat,numpat)
                 dif_pat%diff_kind = "neutrons_tof"
                 dif_pat%scat_var =  "TOF"
                 dif_pat%instr  = " 14  - "//mode

              case ("GSAS")
                 !   call Read_Pattern_gsas_m(dif_pat,npat)      ! GSAS file

              case default
                 Err_diffpatt=.true.
                 ERR_DiffPatt_Mess="Invalid Mode"
                 return
          end select
          return
       end if
       close(unit=i_dat,iostat=ier)

       if (ier/=0) then
           Err_diffpatt=.true.
           ERR_DiffPatt_Mess=" Problems closing data file"
       end if

       return
    End Subroutine Read_Pattern_Mult

    !!--++
    !!--++ Subroutine Read_Pattern_Nls(i_dat,Pat)
    !!--++    integer,                         intent(in)     :: i_dat
    !!--++    type (diffraction_pattern_type), intent(in out) :: Pat
    !!--++
    !!--++    Read a pattern for NLS
    !!--++
    !!--++ Update: February - 2005
    !!
    Subroutine Read_Pattern_Nls(i_dat,Pat)
       !---- Arguments ----!
       integer,                         intent(in)     :: i_dat
       type (diffraction_pattern_type), intent(in out) ::  pat

       !---- Local Variables ----!
       character(len=132)                           :: aline
       integer                                      :: nlines,j,i,ier, no
       logical                                      :: title_given

       call init_err_diffpatt()
       title_given=.false.
       pat%tsamp=0.0
       pat%tset=0.0
       pat%scal=0.0
       pat%monitor=0.0

       do
          read(unit=i_dat,fmt="(a)") aline
          aline=adjustl(aline)
          if(.not. title_given) then
            Pat%title=aline
            title_given=.true.
          end if
          if (aline(1:1) == "!") cycle
          read(unit=aline,fmt=*,iostat=ier) pat%xmin,pat%step,pat%xmax
          if (ier /= 0 ) then
             Err_diffpatt=.true.
             ERR_DiffPatt_Mess=" Error in  Intensity file, check your instr parameter!"
             return
          end if
          exit
       end do

       pat%npts = (pat%xmax-pat%xmin)/pat%step+1.5
       if (pat%npts <= 0) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error in Intensity file, Number of points negative or zero!"
          return
       end if

       nlines = pat%npts/10-1

       call Allocate_Diffraction_Pattern(pat)

       j = 0
       do i=1,nlines
          read(unit=i_dat,fmt="(10F8.0)",iostat=ier)(pat%y(j+no),no=1,10)
          if (ier /= 0 ) then
             Err_diffpatt=.true.
             ERR_DiffPatt_Mess=" Error in (NLS) Intensity file, check your instr parameter!1"
             return
          end if
          read(unit=i_dat,fmt="(10F8.0)",iostat=ier)(pat%sigma(j+no),no=1,10)
          if (ier /= 0 ) then
             Err_diffpatt=.true.
             ERR_DiffPatt_Mess=" Error in (NLS) Intensity file, check your instr parameter!2"
             return
          end if
          j = j+10
       end do

       pat%sigma(1) = pat%sigma(1)**2
       pat%x(1)=pat%xmin

       do i=2,pat%npts
          if (  pat%y(i) < 0.00001) pat%y(i) = pat%y(i-1)
          if (pat%sigma(i) < 0.00001) pat%sigma(i) = 1.0
          pat%sigma(i) = pat%sigma(i)**2
          pat%x(i)= pat%xmin+(i-1)*pat%step
       end do
       pat%ymin=minval(pat%y(1:pat%npts))
       pat%ymax=maxval(pat%y(1:pat%npts))
       return
    End Subroutine Read_Pattern_Nls

    !!--++
    !!--++ Subroutine Read_Pattern_One(Filename,Dif_Pat, Mode)
    !!--++    character(len=*),                intent (in)    :: filename
    !!--++    type (diffraction_pattern_type), intent(in out) :: Dif_Pat
    !!--++    character(len=*), optional,      intent (in)    :: mode
    !!--++
    !!--++    Read one pattern from a Filename
    !!--++
    !!--++ Update: February - 2005
    !!
    Subroutine Read_Pattern_One(Filename,Dif_Pat, Mode)
       !---- Arguments ----!
       character(len=*),                intent (in)      :: filename
       type (diffraction_pattern_type), intent (in out)  :: dif_pat
       character(len=*), optional,      intent (in)      :: mode

       !---- Local Variables ----!
       character(len=6)                               :: extdat !extension of panalytical file
       character(len=4)                               :: tofn
       character(len=12)                              :: modem !extension of panalytical file
       logical                                        :: esta
       integer                                        :: i, i_dat,ier

       call init_err_diffpatt()

       inquire(file=filename,exist=esta)
       if (.not. esta) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" The file "//trim(filename)//" doesn't exist"
          return
       else
          call get_logunit(i_dat)
          open(unit=i_dat,file=trim(filename),status="old",action="read",position="rewind",iostat=ier)
          if (ier /= 0) then
             Err_diffpatt=.true.
             ERR_DiffPatt_Mess=" Error opening the file: "//trim(filename)
             return
          end if
          dif_pat%filename=trim(filename)
       end if

       if (present(mode)) then
          modem=u_case(mode)
          if(modem(1:7) == "GSASTOF") then
            if(len_trim(modem) > 7) then
               tofn="TOF"//modem(8:8)
               modem="GSASTOF"
            else
               tofn="TOF"
            end if
          end if
       else
          modem="DEFAULT"
       end if

       select case (modem)
          case ("D1B" , "D20")
             call Read_Pattern_d1b_d20(i_dat,dif_pat)
             dif_pat%diff_kind = "neutrons_cw"
             dif_pat%scat_var =  "2theta"
             dif_pat%instr  = "  3  - "//mode
             dif_pat%ct_step = .true.

          case ("NLS")                   ! Data from N.L.S (Brookhaven) Synchrotron Radiation  ,data from synchrotron source and correct data for dead time
             call Read_Pattern_nls(i_dat,dif_pat)
             dif_pat%diff_kind = "xrays_cw"
             dif_pat%scat_var =  "2theta"
             dif_pat%instr  = "  4  - "//mode
             dif_pat%ct_step = .true.

          case ("G41")                   ! Data from general format of two axis instruments with fixed step in twotheta
             call Read_Pattern_g41(i_dat,dif_pat)
             dif_pat%diff_kind = "neutrons_cw"
             dif_pat%scat_var =  "2theta"
             dif_pat%instr  = "  5  - "//mode
             dif_pat%ct_step = .true.

          case ("D1A","D2B","3T2","G42")
             call Read_Pattern_d1a_d2b(i_dat,dif_pat)     ! Data from D1A,D2B  (Files *.sum, renamed *.dat, as prepared by D1ASUM or D2BSUM programs)
             dif_pat%diff_kind = "neutrons_cw"
             dif_pat%scat_var =  "2theta"
             dif_pat%instr  = "  6  - "//mode
             dif_pat%ct_step = .true.

          case ("D1AOLD", "D2BOLD","OLDD1A", "OLDD2B")
             call Read_Pattern_d1a_d2b_old(i_dat,dif_pat)
             dif_pat%diff_kind = "neutrons_cw"
             dif_pat%scat_var =  "2theta"
             dif_pat%instr  = "  1  - "//mode
             dif_pat%ct_step = .true.

          case ("DMC","HRPT")                   ! Data from DMC,HRPT
             call Read_Pattern_dmc(i_dat,dif_pat)
             dif_pat%diff_kind = "neutrons_cw"
             dif_pat%scat_var =  "2theta"
             dif_pat%instr  = "  8  - "//mode
             dif_pat%ct_step = .true.

          case ("SOCABIM")
             call  Read_Pattern_socabim(i_dat,dif_pat)
             dif_pat%diff_kind = "xrays_cw"
             dif_pat%scat_var =  "2theta"
             dif_pat%instr  = "  9  - "//mode
             dif_pat%ct_step = .true.

          case ("XYSIGMA")            !XYSIGMA  data file
             call  Read_Pattern_xysigma(i_dat, dif_pat)
             if(Err_diffpatt) return
             dif_pat%diff_kind = "unknown"
             dif_pat%instr  = " 10  - "//mode
             if(dif_pat%x(dif_pat%npts) > 180.0 ) then
                 dif_pat%scat_var =  "TOF"
             else
                 dif_pat%scat_var =  "2theta"
             end if

          case ("GSAS")
             call Read_Pattern_gsas(i_dat,dif_pat)         ! GSAS file
             dif_pat%diff_kind = "constant_wavelength"
             dif_pat%scat_var =  "2theta"
             dif_pat%instr  = " 12  - "//mode

          case ("GSASTOF")
             call Read_Pattern_gsas(i_dat,dif_pat,tofn)         ! GSAS file for TOF
             dif_pat%diff_kind = "neutrons_tof"
             dif_pat%scat_var =  "TOF"
             dif_pat%instr  = " 12  - "//mode

          case ("PANALYTICAL")
             i=index(filename,".",back=.true.)
             extdat=u_case(filename(i:))
             dif_pat%diff_kind = "xrays_cw"
             dif_pat%scat_var =  "2theta"
             dif_pat%instr  = " 13  - "//mode

             select case (extdat)
                case(".CSV")
                   CALL Read_Pattern_PANalytical_CSV(i_dat,dif_pat)

                case(".UDF")
                   CALL Read_Pattern_PANalytical_UDF(i_dat,dif_pat)

                case(".JCP")
                   CALL Read_Pattern_PANalytical_JCP(i_dat,dif_pat)

                case(".XRDML")
                   CALL Read_Pattern_PANalytical_XRDML(i_dat,dif_pat)
             end select

          case ("TIMEVARIABLE")
             call Read_Pattern_time_variable(i_dat,dif_pat)
             dif_pat%diff_kind = "xrays_cw"
             dif_pat%scat_var =  "2theta"
             dif_pat%instr  = " 11  - "//mode

          case default
             call Read_Pattern_free(i_dat,dif_pat)
             if(Err_diffpatt) return
             dif_pat%diff_kind = "unknown"
             dif_pat%instr  = "  0  - "//"Free format"
             dif_pat%ct_step = .true.
             if(dif_pat%x(dif_pat%npts) > 180.0 ) then
                 dif_pat%scat_var =  "TOF"
             else
                 dif_pat%scat_var =  "2theta"
             end if
       end select

       close(unit=i_dat,iostat=ier)
       if (ier/=0) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Problems closing the data file: "//trim(filename)
       end if

       return
    End Subroutine Read_Pattern_One

    !!--++
    !!--++ Subroutine Read_Pattern_Panalytical_CSV(i_dat,Pat)
    !!--++    integer,                         intent(in)     :: i_dat
    !!--++    type (diffraction_pattern_type), intent(in out) :: Pat
    !!--++
    !!--++    Read a pattern for Panalitical Format CSV
    !!--++
    !!--++ Update: February - 2005
    !!
    Subroutine Read_Pattern_Panalytical_Csv(i_dat,Pat)
       !---- Arguments ----!
       integer,                         intent(in)     :: i_dat
       type (diffraction_pattern_type), intent(in out) :: pat

       !---- Local Variables ----!
       character (len=180)                          :: line
       integer                                      :: i, j, long, ier
       real(kind=cp)                                :: alpha1, alpha2, ratio_I


       call init_err_diffpatt()

       !---- lecture fichier Philips X"celerator
       pat%ct_step = .false.
       pat%tsamp=0.0
       pat%tset=0.0
       pat%scal=0.0
       pat%monitor=0.0

       do
          read(unit=i_dat,fmt="(a)",IOSTAT=ier) line
          if (ier /= 0) then
             Err_diffpatt=.true.
             ERR_DiffPatt_Mess=" Error reading a profile CSV-DATA file: end of file"
             return
          end if
          long=LEN_TRIM(line)

          if (line(1:7) == "Title 1") then
             pat%title=line(8:)
          else if(line(1:19) =="K-Alpha1 wavelength") then
             read(unit=line(21:long),fmt=*, IOSTAT=ier) alpha1
               pat%conv(1) = alpha1
          else if(line(1:19) =="K-Alpha2 wavelength") then
             read(unit=line(21:long),fmt=*, IOSTAT=ier) alpha2
               pat%conv(2) = alpha2
          else if(line(1:23) =="Ratio K-Alpha2/K-Alpha1") then
             read(unit=line(25:long),fmt=*, IOSTAT=ier) ratio_I
               pat%conv(3) = ratio_I
          else if(line(1:16) =="Data angle range") then
             read(unit=line(18:long),fmt=*)  pat%xmin  , pat%xmax

          else if(line(1:14) =="Scan step size") then
             read(unit=line(16:long),fmt=*, IOSTAT=ier) pat%step

          else if(line(1:13) =="No. of points") then
             read(unit=line(15:long),fmt=*, IOSTAT=ier) pat%npts

          else if(line(1:13) =="[Scan points]") then
             read(unit=i_dat,fmt="(a)",IOSTAT=ier) line     ! lecture de la ligne Angle,Intensity
             if (ier/=0) return
             exit
          end if
       end do

       if (pat%npts <= 0) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error in (Csv)Intensity file, Number of points negative or zero!"
          return
       end if

       call Allocate_Diffraction_Pattern(pat)

       i=0
       do
          i=i+1
          if (i > pat%npts) then
             i=i-1
             exit
          end if
          read(unit=i_dat,fmt="(a)",IOSTAT=ier) line
          j=index(line,",")
          if (j == 0) then
             read(unit=line,fmt=*,IOSTAT=ier) pat%x(i),pat%y(i)
          else
             read(unit=line(1:j-1),fmt=*,IOSTAT=ier) pat%x(i)
             read(unit=line(j+1:),fmt=*,IOSTAT=ier) pat%y(i)
          end if
          if (ier /=0) exit
          pat%sigma(i) = pat%y(i)
          if (pat%sigma(i)   <= 0.00001) pat%sigma(i) = 1.0
       end do

       pat%npts = i
       pat%ymin=minval(pat%y(1:pat%npts))
       pat%ymax=maxval(pat%y(1:pat%npts))

       return
    End Subroutine Read_Pattern_Panalytical_Csv

    !!--++
    !!--++ Subroutine Read_Pattern_Panalytical_JCP(i_dat,Pat)
    !!--++    integer,                         intent(in)     :: i_dat
    !!--++    type (diffraction_pattern_type), intent(in out) :: Pat
    !!--++
    !!--++    Read a pattern for Panalitical Format JCP
    !!--++
    !!--++ Update: February - 2005
    !!
    Subroutine Read_Pattern_Panalytical_Jcp(i_dat,Pat)
       !---- Arguments ----!
       integer,                         intent(in)     :: i_dat
       type (diffraction_pattern_type), intent(in out) :: pat

       !---- Local Variables ----!
       character (len=132)                          :: line
       integer                                      :: i, j, long , k, ier
       real(kind=cp)                                :: alpha1, alpha2, ratio_I

       call init_err_diffpatt()

       !---- lecture fichier JCP
       pat%ct_step = .false.
       pat%tsamp=0.0
       pat%tset=0.0
       pat%scal=0.0
       pat%monitor=0.0

       k=0
       do
          k=k+1
          read(unit=i_dat,fmt="(a)",IOSTAT=ier) line
          if (ier /= 0) then
             Err_diffpatt=.true.
             ERR_DiffPatt_Mess=" Error reading a profile JCP-DATA file: end of file"
             return
          end if
          if( k == 1) pat%title=line
          long=LEN_TRIM(line)

          if (line(1:7) == "## END=") exit

          if (line(1:21) =="##$WAVELENGTH ALPHA1=") then
             read(unit=line(22:long),fmt=*, IOSTAT=ier) alpha1
             if (ier /= 0) then
                Err_diffpatt=.true.
                ERR_DiffPatt_Mess=" Error reading a profile  file: end of file"
                return
             end if
             pat%conv(1)= alpha1

          else if(line(1:21) =="##$WAVELENGTH ALPHA2=") then
             read(unit=line(22:long),fmt=*, IOSTAT=ier) alpha2
             if (ier /= 0) then
                Err_diffpatt=.true.
                ERR_DiffPatt_Mess=" Error reading a profile XRDML-DATA file: end of file"
                return
             end if
              pat%conv(2)= alpha2

          else if(line(1:33) =="##$INTENSITY RATIO ALPHA2/ALPHA1=") then
             read(unit=line(34:long),fmt=*, IOSTAT=ier) ratio_I
             if (ier /= 0) then
                Err_diffpatt=.true.
                ERR_DiffPatt_Mess=" Error reading a profile XRDML-DATA file: end of file"
                return
             end if
             pat%conv(3)= ratio_I

          else if(line(1:10) =="## FIRSTX=") then
             read(unit=line(11:long),fmt=*, IOSTAT=ier) pat%xmin
             if (ier /= 0) then
                Err_diffpatt=.true.
                ERR_DiffPatt_Mess=" Error reading a profile XRDML-DATA file: end of file"
                return
             end if

          else if(line(1:10) =="## LASTX=") then
             read(unit=line(11:long),fmt=*, IOSTAT=ier) pat%xmax
             if (ier /= 0) then
                Err_diffpatt=.true.
                ERR_DiffPatt_Mess=" Error reading a profile XRDML-DATA file: end of file"
                return
             end if

          else if(line(1:10) =="## DELTAX=") then
             read(unit=line(11:long),fmt=*, IOSTAT=ier) pat%step
             if (ier /= 0) then
                Err_diffpatt=.true.
                ERR_DiffPatt_Mess=" Error reading a profile XRDML-DATA file: end of file"
                return
             end if

          else if(line(1:11) =="## NPOINTS=") then
             read(unit=line(12:long),fmt=*, IOSTAT=ier) pat%npts
             if (ier /= 0 .or. pat%npts <=0) then
                Err_diffpatt=.true.
                ERR_DiffPatt_Mess=" Error reading a profile XRDML-DATA file: end of file"
                return
             end if

          else if(line(1:20) =="## XYDATA= X++<Y..Y>") then

             call Allocate_Diffraction_Pattern(pat)

             i=1
             do
                read(unit=i_dat,fmt="(f9.3,tr1,5f11.3)",iostat=ier) pat%x(i),(pat%y(i+j),j=0,4)
                if (ier /= 0) then
                   Err_diffpatt=.true.
                   ERR_DiffPatt_Mess=" Error reading a profile XRDML-DATA file: end of file"
                   return
                end if

                do j=1,4
                   pat%x(i+j) = pat%x(i) + real(j)*pat%step
                end do
                if (i+5 > pat%npts ) exit
                i=i+5
             end do
             pat%npts = i

          end if
       end do ! File

       do i=1,pat%npts
          pat%sigma(i) = pat%y(i)
          if (pat%sigma(i)   <= 0.00001) pat%sigma(i) = 1.0
       end do
       pat%ymin=minval(pat%y(1:pat%npts))
       pat%ymax=maxval(pat%y(1:pat%npts))

       return
    End Subroutine Read_Pattern_Panalytical_Jcp

    !!--++
    !!--++ Subroutine Read_Pattern_Panalytical_UDF(i_dat,Pat)
    !!--++    integer,                         intent(in)     :: i_dat
    !!--++    type (diffraction_pattern_type), intent(in out) :: Pat
    !!--++
    !!--++    Read a pattern for Panalitical Format UDF
    !!--++
    !!--++ Update: February - 2005
    !!
    Subroutine Read_Pattern_Panalytical_Udf(i_dat,Pat)
       !---- Arguments ----!
       integer,                         intent(in)     :: i_dat
       type (diffraction_pattern_type), intent(in out) :: pat

       !---- Local Variables ----!
       character (len=132)                            :: line, newline
       integer                                        :: i, j, long, ier, n, nb_lignes, np
       real(kind=cp)                                  :: alpha1, alpha2, ratio !, ratio_I
       logical                                        :: title_given

       call init_err_diffpatt()

       !---- lecture fichier UDF
       pat%ct_step = .true.
       title_given = .false.
       pat%tsamp=0.0
       pat%tset=0.0
       pat%scal=0.0
       pat%monitor=0.0

       do
          read(unit=i_dat,fmt="(a)",IOSTAT=ier) line
          if (ier /= 0) then
             Err_diffpatt=.true.
             ERR_DiffPatt_Mess=" Error reading a profile UDF-DATA file: end of file"
             return
          end if
          if(.not. title_given) then
            pat%title=line
            title_given=.true.
          end if
          long=LEN_TRIM(line)

          if (line(1:12) =="LabdaAlpha1,") then
             read(unit=line(23:long-2),fmt=*, IOSTAT=ier) alpha1
             pat%conv(1)=  alpha1
          else if(line(1:12) =="LabdaAlpha2,") then
             read(unit=line(23:long-2),fmt=*, IOSTAT=ier) alpha2
             pat%conv(2)=  alpha2

          else if(line(1:13) =="RatioAlpha21,") then
             read(unit=line(14:long-2),fmt=*, IOSTAT=ier) ratio
             pat%conv(3)= ratio

          else if(line(1:15) =="DataAngleRange,") then
             write(unit=newline,fmt="(a)")  line(16:long-2)
             i = INDEX(NewLine,",")
             long=LEN_TRIM(NewLine)
             read(unit=NewLine(1:i-1),fmt=*, IOSTAT=ier)   pat%xmin
             read(unit=NewLine(i+1:long),fmt=*,IOSTAT=ier) pat%xmax

          else if(line(1:13) =="ScanStepSize,") then
             read(unit=line(14:long-2),fmt=*, IOSTAT=ier) pat%step
             pat%npts=(pat%xmax-pat%xmin)/pat%step+1.2
             if (pat%npts <= 0) then
                Err_diffpatt=.true.
                ERR_DiffPatt_Mess=" Error reading a profile UDF-DATA file: end of file"
                return
             end if

          else if(line(1:7) =="RawScan") then

             call Allocate_Diffraction_Pattern(pat)

             nb_lignes = int(pat%npts/8)
             n = 0
             do j=1, nb_lignes
                read(unit=i_dat,fmt= "(7(f8.0,tr1),F8.0)", IOSTAT=ier) (pat%y(i+n),i=1,7), pat%y(n+8)
                if (ier /= 0) then
                   Err_diffpatt=.true.
                   ERR_DiffPatt_Mess=" Error reading a profile UDF-DATA file: end of file"
                   return
                end if
                n = n + 8
             end do
             np = pat%npts - n

             if (np /= 0) then
                read(unit=i_dat, fmt = "(7(f8.0,tr1),F8.0)") (pat%y(i), i=n+1, pat%npts)
             endif
             exit

          end if
       end do ! file

       do i=1,pat%npts
          pat%x(i)=pat%xmin+real(i-1)*pat%step
          pat%sigma(i) = pat%y(i)
          if (pat%sigma(i)   <= 0.00001) pat%sigma(i) = 1.0
       end do
       pat%ymin=minval(pat%y(1:pat%npts))
       pat%ymax=maxval(pat%y(1:pat%npts))

       return
    End Subroutine Read_Pattern_Panalytical_Udf

    !!--++
    !!--++ Subroutine Read_Pattern_Panalytical_XRDML(i_dat,Pat)
    !!--++    integer,                         intent(in)     :: i_dat
    !!--++    type (diffraction_pattern_type), intent(in out) :: Pat
    !!--++
    !!--++    Read a pattern for Panalitical Format XRDML
    !!--++
    !!--++ Update: January - 2005
    !!
    Subroutine Read_Pattern_Panalytical_Xrdml(i_dat,Pat)
       !---- Arguments ----!
       integer,                         intent(in)     :: i_dat
       type (diffraction_pattern_type), intent(in out) :: pat

       !---- Local Variables ----!
       character (len=256000), allocatable, dimension(:)  :: XRDML_line, XRDML_intensities_line
       integer                                            :: i, i1, i2, nl, ier

       call init_err_diffpatt()
       pat%tsamp=0.0
       pat%tset=0.0
       pat%scal=0.0
       pat%monitor=0.0

       if (allocated(XRDML_line))             deallocate(XRDML_line)
       if (allocated(XRDML_intensities_line)) deallocate(XRDML_intensities_line)

       allocate(XRDML_line(1))
       allocate(XRDML_intensities_line(1))

       !---- Wavelengths (by JGP)
       do
          ! Kalpha1
          read(unit=i_dat, fmt="(a)", iostat=ier) XRDML_line(1)
          if (ier /= 0) then
             Err_diffpatt=.true.
             ERR_DiffPatt_Mess=" Error reading a profile XRDML-DATA file: end of file"
             return
          end if
          i1= index(XRDML_line(1), '<kAlpha1 unit="Angstrom">')
          if (i1==0) cycle
          i2= index(XRDML_line(1), "</kAlpha1>")
          read(unit=XRDML_line(1)(i1+25:i2-1), fmt=*) pat%conv(1)

          !Kalpha2
          read(unit=i_dat, fmt="(a)", iostat=ier) XRDML_line(1)
          i1= index(XRDML_line(1), '<kAlpha2 unit="Angstrom">')
          if (i1==0) cycle
          i2= index(XRDML_line(1), "</kAlpha2>")
          read(unit=XRDML_line(1)(i1+25:i2-1), fmt=*) pat%conv(2)

          !Kbeta
          read(unit=i_dat, fmt="(a)", iostat=ier) XRDML_line(1)

          !Kratio
          read(unit=i_dat, fmt="(a)", iostat=ier) XRDML_line(1)
          i1= index(XRDML_line(1), '<ratioKAlpha2KAlpha1>')
          if (i1==0) cycle
          i2= index(XRDML_line(1), "</ratioKAlpha2KAlpha1>")
          read(unit=XRDML_line(1)(i1+21:i2-1), fmt=*) pat%conv(3)

          exit
       end do

       !---- recherche de "<positions axis="2Theta" unit="deg">"
       do
          read(unit=i_dat, fmt="(a)", iostat=ier) XRDML_line(1)
          if (ier /= 0) then
             Err_diffpatt=.true.
             ERR_DiffPatt_Mess=" Error reading a profile XRDML-DATA file: end of file"
             return
          end if
          i1= index(XRDML_line(1), "<positions axis=""2Theta"" unit=""deg"">")
          if (i1/=0) exit
       end do

       !---- recherche de 2theta_min
       do
          read(unit=i_dat, fmt="(a)", iostat=ier) XRDML_line(1)
          if (ier /= 0) then
             Err_diffpatt=.true.
             ERR_DiffPatt_Mess=" Error reading a profile XRDML-DATA file: end of file"
             return
          end if
          i1= index(XRDML_line(1), "<startPosition>")
          if (i1==0) cycle
          i2= index(XRDML_line(1), "</startPosition>")
          read(unit=XRDML_line(1)(i1+15:i2-1), fmt=*) pat%xmin
          exit
       end do

       !---- recherche de 2theta_max
       do
          read(unit=i_dat, fmt="(a)", iostat=ier) XRDML_line(1)
          if (ier /= 0) then
             Err_diffpatt=.true.
             ERR_DiffPatt_Mess=" Error reading a profile XRDML-DATA file: end of file"
             return
          end if
          i1= index(XRDML_line(1), "<endPosition>")
          if (i1==0) cycle
          i2= index(XRDML_line(1), "</endPosition>")
          read(unit=XRDML_line(1)(i1+13:i2-1), fmt=*) pat%xmax
          exit
       end do

       do
          read(unit=i_dat, fmt="(a)", iostat=ier) XRDML_line(1)
          if (ier /= 0) then
             Err_diffpatt=.true.
             ERR_DiffPatt_Mess=" Error reading a profile XRDML-DATA file: end of file"
             return
          end if
          i1= index(XRDML_line(1), "<intensities unit=""counts"">")
          if (i1==0) cycle
          i2= index(XRDML_line(1), "</intensities>")
          XRDML_intensities_line(1) = XRDML_line(1)(i1+27:i2-1)
          exit
       end do
       XRDML_intensities_line(1)=adjustl(XRDML_intensities_line(1))
       nl=LEN_TRIM(XRDML_intensities_line(1))
       i1=1
       do i=2,nl
          if (XRDML_intensities_line(1)(i:i) /= " ") then
             if (XRDML_intensities_line(1)(i-1:i-1) == " ") then
                i1=i1+1
             end if
          end if
       end do
       pat%npts=i1
       if (pat%npts <= 0) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error reading a profile XRDML-DATA file: end of file"
          return
       end if

       call Allocate_Diffraction_Pattern(pat)

       pat%step = (pat%xmax - pat%xmin) / real(pat%npts-1)
       read(unit=XRDML_intensities_line(1), fmt=*, iostat=ier) (pat%y(i),i=1,pat%npts)
       if (ier /= 0) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error reading a profile XRDML-DATA file: end of file"
          return
       end if
       do i=1,pat%npts
          pat%x(i)=pat%xmin+real(i-1)*pat%step
          pat%sigma(i) = pat%y(i)
          IF (pat%sigma(i)   <= 0.00001) pat%sigma(i) = 1.0
       end do
       pat%ymin=minval(pat%y(1:pat%npts))
       pat%ymax=maxval(pat%y(1:pat%npts))

       if (allocated(XRDML_line))             deallocate(XRDML_line)
       if (allocated(XRDML_intensities_line)) deallocate(XRDML_intensities_line)

       return
    End Subroutine Read_Pattern_Panalytical_Xrdml

    !!--++
    !!--++ Subroutine Read_Pattern_Socabim(i_dat,Pat)
    !!--++    integer,                         intent(in)     :: i_dat
    !!--++    type (diffraction_pattern_type), intent(in out) :: Pat
    !!--++
    !!--++    Read a pattern for Socabim
    !!--++
    !!--++ Update: February - 2005
    !!
    Subroutine Read_Pattern_Socabim(i_dat,Pat)
       !---- Arguments ----!
       integer,                         intent(in)     :: i_dat
       type (diffraction_pattern_type), intent(in out) :: pat

       !---- Local Variables ----!
       logical                                      :: string_counts, string_2thetacounts, string_2thetacps ,free_format
       character (len=132)                          :: line
       character(len=20),dimension(30)              :: dire
       character(len=1)                             :: separateur
       integer                                      :: i, j, i1, long, nb_sep, nb_col, n, ier
       real(kind=cp)                                :: step_time


       call init_err_diffpatt()

       pat%tsamp=0.0
       pat%tset=0.0
       pat%scal=0.0
       pat%monitor=0.0
       string_COUNTS       = .false.
       string_2THETACOUNTS = .false.
       string_2THETACPS    = .false.
       free_format         = .false.

       nb_sep = 0    ! nombre de separateurs
       nb_col = 0    ! nombre de colonnes

       !---- recherche du type de donnees et de divers parametres (step, 2theta_min ...) ----!

        DO
           read(unit=i_dat,fmt="(a)",IOSTAT=ier) line
           if (ier/=0) then
              Err_diffpatt=.true.
              ERR_DiffPatt_Mess=" Error on Socabim UXD Intensity file, check your mode parameter!"
              return
           end if
           IF (line(1:7) == "_COUNTS") THEN
              string_COUNTS    = .true.
              EXIT
           ELSE IF (line(1:13) =="_2THETACOUNTS") then
              string_2THETACOUNTS = .true.
              exit
           ELSE IF (line(1:10) == "_2THETACPS") THEN
              string_2THETACPS = .true.
              EXIT
           ELSE IF (line(1:8) == "_2THETA=") THEN
              i = INDEX(line,"=")
              j = LEN_TRIM(line)
              if (LEN_TRIM(line(i+1:j)) /=0) then
                 read(unit=line(i+1:j),fmt=*)  pat%xmin
              end if
           ELSE IF (line(1:10) == "_STEPSIZE=") THEN
              i=INDEX(line,"=")
              j = LEN_TRIM(line)
              if (LEN_TRIM(line(i+1:j)) /=0) then
                 read(unit=line(i+1:j),fmt=*)  pat%step
              end if
           ELSE IF (line(1:9) == "_STEPTIME") then
              i=INDEX(line,"=")
              j = LEN_TRIM(line)
              if (LEN_TRIM(line(i+1:j)) /=0) then
                 read(unit=line(i+1:j),fmt=*)  step_time
              end if
           ELSE IF (line(1:11) == "_STEPCOUNT=") THEN
              i=INDEX(line,"=")
              j = LEN_TRIM(line)
              if (LEN_TRIM(line(i+1:j)) /=0) then
                 read(unit=line(i+1:j),fmt=*)  pat%npts
              end if
           ELSE IF (line(1:5) == "_WL1=") THEN
              i=INDEX(line,"=")
              j = LEN_TRIM(line)
              if (LEN_TRIM(line(i+1:j)) /=0) then
                 read(unit=line(i+1:j),fmt=*)  pat%conv(1)
              end if
           ELSE IF (line(1:5) == "_WL2=") THEN
              i=INDEX(line,"=")
              j = LEN_TRIM(line)
              if (LEN_TRIM(line(i+1:j)) /=0) then
                 read(unit=line(i+1:j),fmt=*)  pat%conv(2)
              end if
           ELSE IF (line(1:9) == "_WLRATIO=") THEN
              i=INDEX(line,"=")
              j = LEN_TRIM(line)
              if (LEN_TRIM(line(i+1:j)) /=0) then
                 read(unit=line(i+1:j),fmt=*)  pat%conv(3)
              end if
           END IF
        END DO

        if (pat%npts <= 0) then
           ! _STEPCOUNT not given ... estimate the number of points for allocating the diffraction
           ! pattern by supposing the maximum angle equal to 160 degrees
           if(pat%step > 0.000001) then
             pat%npts= nint((160.0-pat%xmin)/pat%step+1.0)
           else
             Err_diffpatt=.true.
             ERR_DiffPatt_Mess=" Error in Intensity file, Number of points negative or zero!"
             return
           end if
        end if

        call Allocate_Diffraction_Pattern(pat)

        !---- lecture de la premiere ligne de donnees pour determiner le
        !---- format: format libre, type de separateur
        read(unit=i_dat,fmt= "(a)", IOSTAT=ier) line
        if (ier/=0) then
           Err_diffpatt=.true.
           ERR_DiffPatt_Mess=" Error on Socabim UXD Intensity file, check your instr parameter!"
           return
        end if
        i1 = INDEX(line, CHAR(9))      ! "TAB" ?
        if (i1/=0) then
           separateur=CHAR(9)
        else
           i1 = INDEX(line, ";")         ! ";" ?
           if (i1/=0) then
              separateur=";"
           else
              i1 = INDEX(line,",")         ! ","
              if (i1/=0) separateur = ","
          end if
        end if

        if (i1==0) then   ! format libre  (separateur= caractere blanc)
           call getword(line,dire,nb_col)
           if (nb_col ==0) then
              Err_diffpatt=.true.
              ERR_DiffPatt_Mess=" Error on Socabim UXD Intensity file, check your instr parameter!"
              return
           end if
           free_format = .true.
        else
           !---- determination du nombre de tabulations
           do
              nb_sep = nb_sep + 1
              long=LEN_TRIM(line)
              line = line(i1+1:long)
              i1=INDEX(line,separateur)
              if (i1==0) exit
           end do
           nb_col = nb_sep + 1
        end if

        if (string_2THETACOUNTS  .or. string_2THETACPS) nb_col = nb_col -1
        BACKSPACE(unit=i_dat)   ! on remonte d"une ligne

        !---- lecture des donnees
        j = 0       ! indice de la ligne
        n = 0       ! indice du comptage

        do
           j = j+1
           read(unit=i_dat,fmt= "(a)", IOSTAT=ier) line
           if (ier /= 0) exit
           IF (free_format) then
              call getword(line,dire,nb_col)
              if (nb_col==0) then
                 Err_diffpatt=.true.
                 ERR_DiffPatt_Mess=" Error on Socabim UXD Intensity file, check your instr parameter!"
                 return
              end if
              if (string_2THETACOUNTS  .or. string_2THETACPS)then
                 nb_col = nb_col - 1           !  << corrected 14.03.02
                 read(unit=line,fmt=*,IOSTAT=ier) pat%x(n+1), (pat%Y(n+i),i=1,nb_col)
                 if (ier/=0) then
                    n=n-1
                    exit
                 end if
              else
                 read(unit=line,fmt=*, IOSTAT=ier) (pat%Y(n + i),i=1,nb_col)
                 if (ier/=0) then
                    n=n-1
                    exit
                 end if
              end if
              n = n + nb_col

           else
              if (string_2THETACOUNTS  .or. string_2THETACPS)then
                 i1=INDEX(line,separateur)
                 long=LEN_TRIM(line)
                 read(unit=line(1:i1-1),fmt=*, IOSTAT=ier)pat%x(1+nb_col*(j-1))
                 if (ier/=0)  exit
                 line = line(i1+1:long)
              end if

              !---- lecture des comptages d'une ligne
              if (nb_sep > 1) then
                 do i =1, nb_sep
                    n=n+1
                    i1=INDEX(line, separateur)
                    long=LEN_TRIM(line)
                    if (i1==0) then
                       n=n-1
                       exit
                    end if
                    read(unit=line(1:i1-1), fmt=*, IOSTAT=ier) pat%Y(n)

                    if (ier/=0) then
                       n=n-1
                       exit
                    end if
                    j=j+1
                    line= line(i1+1:long)
                 end do
              end if

              !---- lecture du dernier point de la ligne
              n =n + 1
              read(unit=line, fmt=*, IOSTAT=ier) pat%Y(n)
              if (ier/=0) exit
           end if
        end do

        pat%npts = n
        pat%xmax = pat%xmin + pat%step*(pat%npts-1)  !! TR 28.11.02

        !---- creation des abcisses
        !---- modif. des comptages si necessaire et calculs sigmas_comptages

        if (string_COUNTS .or. string_2THETACOUNTS ) then
           pat%sigma(1:n ) = pat%Y(1:n )
        else  ! data in CPS
           pat%sigma(1:n ) = pat%Y(1:n )/ step_time
        endif

        where (pat%sigma(:) <= 0.00001) pat%sigma(:) = 1.0

        do i=1,pat%npts
           pat%x(i)= pat%xmin+(i-1)*pat%step
        end do
        pat%ymin=minval(pat%y(1:pat%npts))
        pat%ymax=maxval(pat%y(1:pat%npts))

        return
     End subroutine Read_Pattern_Socabim

    !!--++
    !!--++ Subroutine Read_Pattern_Time_Variable(i_dat,Pat)
    !!--++    integer,                         intent(in)     :: i_dat
    !!--++    type (diffraction_pattern_type), intent(in out) :: Pat
    !!--++
    !!--++    Read a pattern for Time Variable
    !!--++
    !!--++ Update: January - 2005
    !!
    Subroutine Read_Pattern_Time_Variable(i_dat,Pat)
       !---- Arguments ----!
       integer,                         intent(in)     :: i_dat
       type (diffraction_pattern_type), intent(in out) :: pat

       !---- Local Variables ----!
       character(len=180)                           :: txt1
       character(len=132)                           :: txt2
       character(len=132)                           :: txt3
       real(kind=cp), dimension(:), allocatable     :: bk
       real(kind=cp)                                :: cnorma
       integer                                      :: i,ier

       call init_err_diffpatt()
       pat%tsamp=0.0
       pat%tset=0.0
       pat%scal=0.0
       pat%monitor=0.0

       read(unit=i_dat,fmt="(A)",iostat=ier)txt1   !1
       pat%title=txt1
       if (ier /= 0) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error in  Intensity file, check your instr parameter!"
          return
       end if

       read(unit=i_dat,fmt="(A)",iostat=ier)txt2   !2
       if (ier /= 0) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error in  Intensity file, check your instr parameter!"
          return
       end if

       read(unit=i_dat,fmt="(A)",iostat=ier)txt3   !3
       if (ier /= 0) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error in  Intensity file, check your instr parameter!"
          return
       end if

       read(unit=i_dat,fmt="(A)",iostat=ier)txt3                  !4
       if (ier /= 0)then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error in  Intensity file, check your instr parameter!"
          return
       end if

       read(unit=i_dat,fmt=*,iostat=ier)pat%xmin,pat%step,pat%xmax
       if (ier /= 0)then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error in  Intensity file, check your instr parameter!"
          return
       end if

       pat%npts = (pat%xmax-pat%xmin)/pat%step+1.5
       if (pat%npts <=0) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error in  Intensity file, check your instr parameter!"
          return
       end if

       call Allocate_Diffraction_Pattern(pat)

       if(allocated(bk) ) deallocate(bk)
       allocate(bk(pat%npts))

       read(unit=i_dat,fmt="(5(F6.0,F10.0))",iostat=ier)(bk(i),pat%y(i),i=1,pat%npts)
       if (ier /= 0) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error in  Intensity file, check your instr parameter!"
          return
       end if

       !---- Normalize data to constant time
       cnorma=0.0
       DO i=1,pat%npts
          IF (bk(i) < 1.0E-06) then
             Err_diffpatt=.true.
             ERR_DiffPatt_Mess=" Zero time in *.DAT "
             return
          end if
          cnorma=cnorma+bk(i)
          pat%x(i)= pat%xmin+(i-1)*pat%step
       end do
       cnorma=cnorma/real(pat%npts)
       do i=1,pat%npts
          pat%y(i)=pat%y(i)*cnorma/bk(i)
          pat%sigma(i)=pat%y(i)
          bk(i)=0.0
       end do
       pat%ymin=minval(pat%y(1:pat%npts))
       pat%ymax=maxval(pat%y(1:pat%npts))

       return
    End subroutine Read_Pattern_Time_Variable

    !!--++
    !!--++ Subroutine Read_Pattern_XYSigma(i_dat,Pat)
    !!--++    integer,                         intent(in)     :: i_dat
    !!--++    type (diffraction_pattern_type), intent(in out) :: pat
    !!--++
    !!--++    Read a pattern for X,Y,Sigma
    !!--++
    !!--++ Update: February - 2005
    !!
    Subroutine Read_Pattern_XYSigma(i_dat,Pat)
       !---- Arguments ----!
       integer,                         intent(in)     :: i_dat
       type (diffraction_pattern_type), intent(in out) :: pat

       !---- Local Variables ----!
       character(len=180)                           :: txt1, aline, fmtfields, fmtformat
       character (len=5)                            :: date1
       integer                                      :: line_da, ntt, interpol, i, j,ier,npp
       real(kind=cp)                                :: fac_x, fac_y,  yp1, sumavar, cnorm
       real(kind=cp)                                :: ycor, xt, stepin, ypn
       real(kind=cp), parameter                     :: eps1=1.0E-6
       real(kind=cp), dimension(:), allocatable     :: yc, bk

       call init_err_diffpatt()

       !---- Or X,Y sigma data ----!
       fac_x=1.0
       fac_y=1.0
       interpol=0
       line_da=1
       npp=0
       ntt=0
       pat%tsamp=0.0
       pat%tset=0.0
       pat%scal=0.0
       pat%monitor=0.0

       do
          read(unit=i_dat,fmt="(a)", iostat=ier) txt1
          if (ier /= 0)   exit
          npp=npp+1
       end do

       pat%npts  =   npp
       if (pat%npts <= 0) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error in Intensity file, Number of points negative or zero!"
          return
       end if
       rewind(unit=i_dat)

       read(unit=i_dat,fmt="(a)") txt1

       IF(txt1(1:6) /= "XYDATA") THEN
           pat%title=txt1
           do
              read(unit=i_dat,fmt="(a)", iostat=ier) txt1
              if (ier /= 0) then
                 Err_diffpatt=.true.
                 ERR_DiffPatt_Mess=" Error reading a profile DATA file of XYSigma format"
                 return
              end if
              txt1=adjustl(txt1)
              if(txt1(1:1) == "!" .or. txt1(1:1) == "#") cycle
              read(unit=txt1, fmt=*, iostat=ier) yp1,ypn
              if( ier /= 0) cycle
              backspace (unit=i_dat)
              call init_findfmt(line_da)
              exit
           end do
       else
           pat%title=txt1
           do i=1,5
              read(unit=i_dat,fmt="(a)", iostat=ier) txt1
              if (ier /= 0) then
                 Err_diffpatt=.true.
                 ERR_DiffPatt_Mess=" Error reading a profile DATA file of XYSigma format"
                 return
              end if

              line_da=line_da+1
              if (txt1(1:5) == "TITLE") then !Title given
                pat%title=txt1(7:)
              end if
              if (txt1(1:5) == "INTER") then !Interpolation possible!
                 backspace (unit=i_dat)
                 line_da=line_da-2
                 call init_findfmt(line_da)
                 fmtfields = "5ffif"
                 call findfmt(i_dat,aline,fmtfields,fmtformat)
                 if (ierr_fmt /= 0) then
                    Err_diffpatt=.true.
                    ERR_DiffPatt_Mess=" Error reading"
                    return
                 end if

                 read(unit=aline,fmt=fmtformat) date1,fac_x,fac_y,interpol,stepin
                 if (fac_x <= 0.0) fac_x=1.0
                 if (fac_y <= 0.0) fac_y=1.0
              end if

              if (txt1(1:4) == "TEMP") then
                 read(unit=txt1(5:80),fmt=*, iostat=ier) pat%tsamp
                 if(ier == 0) then
                   pat%tset=pat%tsamp
                 else
                   pat%tsamp=0.0
                   pat%tset=0.0
                 end if
              end if
           end do
       end if

       if (interpol == 0) then
          pat%ct_step = .false.
       else if(interpol == 1) then
          pat%ct_step = .true.
       else if(interpol == 2) then
          pat%ct_step = .true.
       end if

       call Allocate_Diffraction_Pattern(pat)


       fmtfields = "fff"
       sumavar=0.0
       cnorm=0.0
       i=0
       do j=1,pat%npts
          call findfmt(i_dat,aline,fmtfields,fmtformat)
          if (ierr_fmt == -1) exit
          if (ierr_fmt /= 0) then
             Err_diffpatt=.true.
             ERR_DiffPatt_Mess=" Error reading X,Y, Sigma in profile DATA file"
             return
          end if
          if(aline(1:1) == "!" .or. aline(1:1) == "#") cycle
          i=i+1
          read(unit=aline,fmt = fmtformat, iostat=ier ) pat%x(i),pat%y(i),pat%sigma(i)
          if (ier /=0) then
             Err_diffpatt=.true.
             ERR_DiffPatt_Mess=" Error in Intensity file, check your instr parameter!"
             return
          end if
          IF (i > 10 .and. ABS(pat%x(i)) < eps1 .AND. pat%y(i) < eps1 .AND.  pat%sigma(i) < eps1) exit
          pat%x(i)=pat%x(i)*fac_x
          pat%y(i)=pat%y(i)*fac_y
          pat%sigma(i)=pat%sigma(i)*fac_y
          pat%sigma(i)=pat%sigma(i)*pat%sigma(i)
          sumavar=sumavar+pat%sigma(i)
          if(pat%sigma(i) < eps1) pat%sigma(i) =1.0_cp
          if(pat%y(i) < eps1) then
             pat%y(i)   = eps1
             pat%sigma(i) =1.0
          end if
          cnorm=cnorm+pat%sigma(i)/MAX(pat%y(i),0.001_cp)
          if(i > 1) then
            pat%step=pat%step+pat%x(i)-pat%x(i-1)
          end if
       end do

       ntt=i-1
       pat%xmin=pat%x(1)
       pat%xmax=pat%x(ntt)
       cnorm=cnorm/REAL(ntt)
       if (sumavar < eps1) then
          do i=1,ntt
             pat%sigma(i)=pat%y(i)
          end do
          cnorm=1.0
       end if

       if (interpol == 0 .or. interpol == 2) then      !if interpol

          pat%step=pat%step/real(ntt-1)
          pat%npts=ntt

       else                        !else interpol

          pat%step=stepin
          j=(pat%x(ntt)-pat%x(1))/pat%step+1.05
          if( j > pat%npts) then
             pat%step=(pat%x(ntt)-pat%x(1))/(ntt-1)
             pat%npts=ntt
          else
             pat%npts=j
          end if
          if(allocated(bk) ) deallocate(bk)
          allocate(bk(pat%npts))
          if(allocated(yc) ) deallocate(yc)
          allocate(yc(pat%npts))


          !---- First interpolate the raw intensities ----!
          yp1=9.9E+32
          ypn=9.9E+32
          call spline(pat%x(:),pat%y(:),ntt,yp1,ypn,bk(:))
          do i=1,pat%npts
             xt=pat%x(1)+(i-1)*pat%step
             call splint(pat%x(:),pat%y(:),bk(:),ntt,xt,ycor)
             yc(i)=max(1.0_cp,ycor)
          end do
          do i=1,pat%npts
             pat%y(i)=yc(i)
             yc(i)=0.0
             bk(i)=0.0
          end do

          !---- Second interpolate the sigmas ----!
          call spline(pat%x(:),pat%sigma(:),ntt,yp1,ypn,bk(:))
          do i=1,pat%npts
             xt=pat%x(1)+(i-1)*pat%step
             call splint(pat%x(:),pat%sigma(:),bk(:),ntt,xt,ycor)
             yc(i)=max(1.0_cp,ycor)
          end do
          do i=1,pat%npts
             pat%sigma(i)=yc(i)
             yc(i)=0.0
             bk(i)=0.0
          end do
          pat%xmax=pat%xmin+pat%step*(pat%npts-1)
       end if                       !End If interpol
       pat%ymin=minval(pat%y(1:pat%npts))
       pat%ymax=maxval(pat%y(1:pat%npts))

       return
    End Subroutine Read_Pattern_XYSigma

    !!--++
    !!--++ Subroutine Set_Background_Inter(Difpat,Bcky,Bckx,N)
    !!--++    type (diffraction_pattern_type), intent(in out)  :: difPat
    !!--++    real (kind=cp), dimension(:),    intent(in out ) :: bcky
    !!--++    real (kind=cp), dimension(:),    intent(in out ) :: bckx
    !!--++    integer,                         intent(in    )  :: n
    !!--++
    !!--++    (PRIVATE)
    !!--++    Define a Background
    !!--++
    !!--++ Update: February - 2005
    !!
    Subroutine Set_Background_Inter(Difpat,Bcky,Bckx,N)
       !---- Arguments ----!
       type (diffraction_pattern_type),intent(in out) :: difpat
       real (kind=cp), dimension(:),   intent(in out) :: bcky
       real (kind=cp), dimension(:),   intent(in out) :: bckx
       integer,                        intent(in    ) :: n

       !---- Local variables ----!
       integer                                        :: nbx, nbac1 , i , j  , nxx
       real                                           :: difl, difr , thx , delt, slope, bstep,p

       nbx=1
       nbac1=n

       difl=bckx(1)-difpat%xmin
       difr=bckx(n)-difpat%xmax

       if (difl >= 0) then
          if (difpat%ct_step) then
             nbx=difl/difpat%step+1.5
          else
             nbx=locate(difpat%x(:),difpat%npts,bckx(1))
             if (nbx <= 0) nbx=1
          end if
          do i=1,nbx
             difpat%bgr(i)=bcky(1)
          end do
       end if

       if (difr <= 0) then
          nbac1=n+1
          bckx(nbac1)=difpat%xmax
          bcky(nbac1)=bcky(n)
       end if

       nxx=2
       do_i: do i=nbx,difpat%npts
          thx=difpat%x(i)
          do j=nxx,nbac1
             delt=bckx(j)-thx
             if (delt > 0.0) then
                p=bckx(j)-bckx(j-1)
                if (abs(p) > 0.0001) then
                   slope=(bcky(j)-bcky(j-1))/p
                else
                   slope=0.0
                end if
                bstep=(thx-bckx(j-1))*slope
                difpat%bgr(i)=bcky(j-1)+bstep
                nxx=j-1
                cycle do_i
             end if
          end do
       end do  do_i

       return
    End Subroutine Set_Background_Inter

    !!--++
    !!--++ Subroutine Set_Background_Poly( Difpat,Bkpos,Bckx,N)
    !!--++    type (diffraction_pattern_type), intent(in out) :: difPat
    !!--++    real (kind=cp),                  intent(in    ) :: bkpos
    !!--++    real (kind=cp), dimension(:),    intent(in    ) :: bckx
    !!--++    integer,                         intent(in    ) :: n
    !!--++
    !!--++    (PRIVATE)
    !!--++    Define a Background
    !!--++
    !!--++ Update: February - 2005
    !!
    Subroutine Set_Background_Poly( Difpat,Bkpos,Bckx,N)
       !---- Arguments ----!
       type (diffraction_pattern_type), intent(in out) :: difpat
       real (kind=cp),                  intent(in    ) :: bkpos
       real (kind=cp), dimension(:),    intent(in    ) :: bckx
       integer,                         intent(in    ) :: n

       !---- Local Variables ----!
       integer                                         :: i,j

       if (allocated(difpat%bgr) ) deallocate(difpat%bgr)
       allocate(difpat%bgr(difpat%npts))

       do i=1, difpat%npts
          difpat%bgr(i)=0
          do j=1,n
             difpat%bgr(i)= difpat%bgr(i)+ bckx(j)*((difpat%x(i)/bkpos-1.0)**(j-1))
          end do
       end do

       return
    End Subroutine Set_Background_Poly

    !!----
    !!---- Subroutine Write_Pattern_FreeFormat(Filename,Pat)
    !!----    character (len=*),               intent(in) :: Filename
    !!----    type (diffraction_pattern_type), intent(in) :: Pat
    !!----
    !!----    Write a pattern in Free Format (Instrm=0)
    !!----
    !!---- Update: 21/03/2011
    !!
    Subroutine Write_Pattern_FreeFormat(Filename,Pat)
       !---- Arguments ----!
       character (len=*),               intent(in) :: filename
       type (diffraction_pattern_type), intent(in) :: Pat

       !---- Local Variables ----!
       integer                                      :: i,j,k,nl,ier,i_dat

       call init_err_diffpatt()
       call get_logunit(i_dat)
       open(unit=i_dat,file=trim(filename),status="replace",action="write",iostat=ier)
       if (ier /= 0 ) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error opening the file: "//trim(filename)//" for writing!"
          return
       end if

       write(unit=i_dat,fmt='(3(1x,f14.6),2x,a)') pat%xmin, pat%step, pat%xmax, trim(pat%Title)
       nl=pat%npts/10
       if (mod(pat%npts,10) /= 0) nl=nl+1
       j=1
       do i=1,nl
          if (i /= nl) then
             write(unit=i_dat,fmt='(10i8)') nint(pat%y(j:j+9))
          else
             k=pat%npts - 10*(i-1)
             write(unit=i_dat,fmt='(10i8)') nint(pat%y(j:j+k-1))
          end if
          j=j+10
       end do

       close(unit=i_dat)
       return
    End Subroutine Write_Pattern_FreeFormat

    !!----
    !!---- Subroutine Write_Pattern_INSTRM5(Filename,Pat)
    !!----    character (len=*),               intent(in) :: Filename
    !!----    type (diffraction_pattern_type), intent(in) :: Pat
    !!----
    !!----    Write a pattern in 2-axis format with fixed step (Instrm=5)
    !!----
    !!---- Update: 29/04/2011
    !!
    Subroutine Write_Pattern_INSTRM5(Filename,Pat)
       !---- Arguments ----!
       character (len=*),               intent(in) :: Filename
       type (diffraction_pattern_type), intent(in) :: Pat

       !---- Local Variables ----!
       integer   :: np,ier,i_dat

       call init_err_diffpatt()
       call get_logunit(i_dat)
       open(unit=i_dat,file=trim(filename),status="replace",action="write",iostat=ier)
       if (ier /= 0 ) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error opening the file: "//trim(filename)//" for writing!"
          return
       end if
       np=Pat%npts

       Write(unit=i_dat,fmt='(a)') trim(Pat%Title)
       Write(unit=i_dat,fmt="(a,f10.5)") trim(pat%diff_kind)//" "//trim(pat%scat_var)//", Wavelength (angstroms): ",pat%conv(1)
       Write(unit=i_dat,fmt="(a)")  "! Npoints TSample  TSetting Variance    Norm-Monitor           Monitor"
       if(Pat%ymax > 999999999.0) then
         write(unit=i_dat,fmt="(a,f16.1)") "!  Warning! Maximum number of counts above the allowed format ",Pat%ymax
         Err_diffpatt=.true.
         ERR_DiffPatt_Mess=" Too high counts ... format error in the file: "//trim(filename)//" at writing!"
       end if
       Write(unit=i_dat,fmt="(i6,tr1,2F10.3,i5,2f18.1)")  Pat%npts, Pat%tsamp,Pat%tset, 0,&
                                                          Pat%Norm_Mon, Pat%Monitor
       Write(unit=i_dat,fmt="(3F12.5)")  Pat%xmin,Pat%step,Pat%xmax
       Write(unit=i_dat,fmt="(8F14.2)")  Pat%y(1:np)
       close(unit=i_dat)
       return
    End Subroutine Write_Pattern_INSTRM5

    !!----
    !!---- Subroutine Write_Pattern_XYSig(Filename,Pat)
    !!----    character (len=*),               intent(in) :: Filename
    !!----    type (diffraction_pattern_type), intent(in) :: Pat
    !!----
    !!----    Write a pattern in X,Y,Sigma format
    !!----
    !!---- Update: March - 2007
    !!
    Subroutine Write_Pattern_XYSig(Filename,Pat)
       !---- Arguments ----!
       character (len=*),               intent(in) :: filename
       type (diffraction_pattern_type), intent(in) :: Pat

       !---- Local Variables ----!
       integer                                      :: i, ier, i_dat

       call init_err_diffpatt()
       call get_logunit(i_dat)
       open(unit=i_dat,file=trim(filename),status="replace",action="write",iostat=ier)
       if (ier /= 0 ) then
          Err_diffpatt=.true.
          ERR_DiffPatt_Mess=" Error opening the file: "//trim(filename)//" for writing!"
          return
       end if
       write(unit=i_dat,fmt="(a)")"XYDATA"
       write(unit=i_dat,fmt="(a)")"TITLE "//trim(pat%title)
       write(unit=i_dat,fmt="(a)")"COND: "//trim(pat%diff_kind)//"-"//trim(pat%scat_var)//"-"//trim(pat%instr)
       write(unit=i_dat,fmt="(a)")"FILE: "//trim(filename)
       write(unit=i_dat,fmt="(a,2f10.3)") "TEMP", pat%tsamp,pat%tset
       if (pat%ct_step) then
          write(unit=i_dat,fmt="(a,2f8.4,i3,f8.5,a)") &
          "INTER ", 1.0,1.0,2,0.0," <- internal multipliers for X, Y-Sigma, Interpol, StepIn"
       else
          write(unit=i_dat,fmt="(a,2f8.4,i3,f8.5,a)") &
          "INTER ", 1.0,1.0,0,0.0," <- internal multipliers for X, Y-Sigma, Interpol, StepIn"
       end if
       write(unit=i_dat,fmt="(a,f12.2,i8)") "! MONITOR & N POINTS ", pat%monitor, pat%npts
       write(unit=i_dat,fmt="(a)") "! Scatt. Var., Profile Intensity, Standard Deviation "
       write(unit=i_dat,fmt="(a,a10,a)") "!     ",pat%scat_var,"        Y          Sigma "
       do i=1,pat%npts
          write(unit=i_dat,fmt="(3f14.5)") pat%x(i),pat%y(i),sqrt(pat%sigma(i))
       end do
       close(unit=i_dat)

       return
    End Subroutine Write_Pattern_XYSig

 End Module CFML_Diffraction_Patterns