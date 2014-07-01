!!-------------------------------------------------------
!!---- Crystallographic Fortran Modules Library (CrysFML)
!!-------------------------------------------------------
!!---- The CrysFML project is distributed under LGPL. In agreement with the
!!---- Intergovernmental Convention of the ILL, this software cannot be used
!!---- in military applications.
!!----
!!---- Copyright (C) 1999-2012  Institut Laue-Langevin (ILL), Grenoble, FRANCE
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
!!---- MODULE: CFML_Magnetic_Symmetry
!!----   INFO: Series of procedures handling operations with Magnetic Symmetry
!!----         and Magnetic Structures
!!----
!!---- HISTORY
!!----
!!----    Update: 07/03/2011
!!----
!!----
!!---- DEPENDENCIES
!!--++    Use CFML_GlobalDeps,                only: cp, tpi
!!--++    Use CFML_Math_General,              only: Modulo_Lat
!!--++    Use CFML_Math_3D,                   only: Get_Cart_From_Spher, matrix_inverse, Veclength
!!--++    Use CFML_Symmetry_Tables,           only: ltr_a,ltr_b,ltr_c,ltr_i,ltr_r,ltr_f
!!--++    Use CFML_Crystallographic_Symmetry, only: Space_Group_Type, Read_Xsym, Get_SymSymb, axes_rotation, &
!!--++                                              Sym_Oper_Type, Set_SpaceGroup,read_msymm, symmetry_symbol, &
!!--++                                              err_symm,err_symm_mess, set_SpG_Mult_Table,ApplySO,   &
!!--++                                              Lattice_Trans, Get_SO_from_Gener,Get_Centring_Vectors
!!--++    Use CFML_String_Utilities,          only: u_case, l_case, Frac_Trans_1Dig, Get_Separator_Pos,Pack_String, &
!!--++                                              Frac_Trans_2Dig, Get_Mat_From_Symb, getnum_std, Err_String,     &
!!--++                                              Err_String_Mess,setnum_std, getword
!!--++    Use CFML_IO_Formats,                only: file_list_type, File_To_FileList
!!--++    Use CFML_Atom_TypeDef,              only: Allocate_mAtom_list, mAtom_List_Type, Get_Atom_2nd_Tensor_Ctr
!!--++    Use CFML_Scattering_Chemical_Tables,only: Set_Magnetic_Form, Remove_Magnetic_Form, num_mag_form, &
!!--++                                              Magnetic_Form
!!--++    Use CFML_Propagation_Vectors,       only: K_Equiv_Minus_K
!!--++    Use CFML_Crystal_Metrics,           only: Crystal_Cell_Type, Set_Crystal_Cell
!!----
!!---- VARIABLES
!!--..    Types
!!----    MSYM_OPER_TYPE
!!----    MAGNETIC_DOMAIN_TYPE
!!----    MAGNETIC_GROUP_TYPE
!!----    MAGSYMM_K_TYPE
!!--..
!!----    ERR_MAGSYM
!!----    ERR_MAGSYM_MESS
!!----
!!---- PROCEDURES
!!----    Functions:
!!----       APPLYMSO
!!----
!!----    Subroutines:
!!----       CALC_INDUCED_SK
!!----       INIT_ERR_MAGSYM
!!----       INIT_MAGSYMM_K_TYPE             !OZ made it public to use in Read_Refcodes_Magnetic_Structure
!!----       READN_SET_MAGNETIC_STRUCTURE
!!--++       READN_SET_MAGNETIC_STRUCTURE_CFL    [Overloaded]
!!--++       READN_SET_MAGNETIC_STRUCTURE_MCIF   [Overloaded]
!!----       SET_SHUBNIKOV_GROUP
!!----       WRITE_MAGNETIC_STRUCTURE
!!----       WRITE_SHUBNIKOV_GROUP
!!----
!!
 Module CFML_Magnetic_Symmetry

    !---- Use Modules ----!
    Use CFML_GlobalDeps,                only: cp, tpi,Write_Date_Time
    Use CFML_Math_General,              only: Trace, Zbelong, Modulo_Lat, equal_matrix,             &
                                              Equal_Vector,Sort
    Use CFML_Math_3D,                   only: Get_Cart_From_Spher,Determ_A, matrix_inverse, Veclength
    Use CFML_Symmetry_Tables,           only: ltr_a,ltr_b,ltr_c,ltr_i,ltr_r,ltr_f,Sys_cry,LATT
    Use CFML_Crystallographic_Symmetry, only: Space_Group_Type, Read_Xsym, Get_SymSymb,axes_rotation, &
                                              Sym_Oper_Type, Set_SpaceGroup,read_msymm, symmetry_symbol, &
                                              err_symm,err_symm_mess, set_SpG_Mult_Table,ApplySO,   &
                                              Lattice_Trans, Get_SO_from_Gener, Get_Centring_Vectors, &
                                              Get_Shubnikov_Operator_Symbol
    Use CFML_String_Utilities,          only: u_case, l_case, Frac_Trans_1Dig, Get_Separator_Pos,Pack_String, &
                                              Frac_Trans_2Dig, Get_Mat_From_Symb, getnum_std, Err_String,     &
                                              Err_String_Mess,setnum_std, getword, Get_Transf,ucase
    Use CFML_IO_Formats,                only: file_list_type, File_To_FileList
    Use CFML_Atom_TypeDef,              only: Allocate_mAtom_list, mAtom_List_Type, Get_Atom_2nd_Tensor_Ctr
    Use CFML_Scattering_Chemical_Tables,only: Set_Magnetic_Form, Remove_Magnetic_Form, num_mag_form, &
                                              Magnetic_Form
    Use CFML_Propagation_Vectors,       only: K_Equiv_Minus_K
    Use CFML_Crystal_Metrics,           only: Crystal_Cell_Type, Set_Crystal_Cell

    !---- Variables ----!
    implicit none

    private

    !---- List of public functions ----!
    public :: ApplyMSO

    !---- List of public subroutines ----!
    public :: Readn_Set_Magnetic_Structure, Write_Magnetic_Structure, Set_Shubnikov_Group, &
              Write_Shubnikov_Group, Init_MagSymm_k_Type, Write_MCIF, get_magnetic_form_factor, &
              Calc_Induced_Sk


    !---- Definitions ----!

    !!----
    !!---- TYPE :: MSYM_OPER_TYPE
    !!--..
    !!---- Type, public :: MSym_Oper_Type
    !!----    integer, dimension(3,3) :: Rot     !  Rotational Part of Symmetry Operator
    !!----    real(kind=cp)           :: Phas    !  Phase in fraction of 2pi
    !!---- End Type  MSym_Oper_Type
    !!----
    !!----  Definition of Magnetic symmetry operator type
    !!----
    !!---- Update: April - 2005
    !!
    Type, public :: MSym_Oper_Type
       integer, dimension(3,3) :: Rot
       real(kind=cp)           :: Phas
    End Type MSym_Oper_Type

    !!----
    !!---- TYPE :: MAGNETIC_DOMAIN_TYPE
    !!--..
    !!---- Type, public :: Magnetic_Domain_type
    !!----    integer                           :: nd=0          !Number of rotational domains (not counting chiral domains)
    !!----    logical                           :: Chir=.false.  !True if chirality domains exist
    !!----    logical                           :: trans=.false. !True if translations are associated to matrix domains
    !!----    logical                           :: Twin=.false.  !True if domains are to be interpreted as twins
    !!----    integer,dimension(3,3,24)         :: DMat=0        !Domain matrices to be applied to Fourier Coefficients
    !!----    real(kind=cp), dimension (2,24)   :: Dt=0.0        !Translations associated to rotation matrices
    !!----    real(kind=cp), dimension (2,24)   :: pop=0.0       !Populations of domains (sum=1,
    !!----                                                       !the second value is /=0 for chir=.true.)
    !!----    real(kind=cp), dimension (2,24)   :: pop_std=0.0   !Standard deviations of Populations of domains
    !!----    integer,dimension (2,24)          :: Lpop=0        !Number of the refined parameter
    !!----    real(kind=cp), dimension (2,24)   :: Mpop=0.0      !Refinement codes for populations
    !!----    character(len=10),dimension (2,24):: Lab           !Label of domain
    !!---- End type Magnetic_Domain_type
    !!----
    !!----
    !!--<<
    !!----  Magnetic S-domains corresponds to a different magnetic structure obtained from
    !!----  the domain 1 (actual model) by applying a rotational operator to the Fourier
    !!----  coefficients of magnetic moments. This rotational operator corresponds to a
    !!----  symmetry operator of the paramagnetic group that is lost in the ordered state.
    !!----  Chirality domains are simply obtained by changing the sign of the imaginary
    !!----  components of the Fourier coefficients. For each rotational domain two chiralities
    !!----  domains exist.
    !!-->>
    !!----
    !!---- Updated: October - 2006, July-2012 (JRC, more type of domains), November 2013 (standard deviations)
    !!
    Type, public :: Magnetic_Domain_type
       integer                           :: nd=0          !Number of rotational domains (not counting chiral domains)
       logical                           :: Chir=.false.  !True if chirality domains exist
       logical                           :: trans=.false. !True if translations are associated to matrix domains
       logical                           :: Twin=.false.  !True if domains are to be interpreted as twins
       integer,dimension(3,3,24)         :: DMat=0        !Domain matrices to be applied to Fourier Coefficients
       real(kind=cp), dimension (3,24)   :: Dt=0.0        !Translations associated to rotation matrices
       real(kind=cp), dimension (2,24)   :: pop=0.0       !Populations of domains (sum=1,
                                                          !the second value is /=0 for chir=.true.)
       integer      , dimension (2,24)   :: Lpop=0        !Number of the refined parameter
       real(kind=cp), dimension (2,24)   :: Mpop=0.0      !Multipliers for population
       real(kind=cp), dimension (2,24)   :: pop_std=0.0   !Standard deviations of Populations of domains
       character(len=10),dimension (2,24):: Lab           !Label of domain
    End type Magnetic_Domain_type

    !!----
    !!---- TYPE :: MAGNETIC_SPACE_GROUP_TYPE
    !!----
    !!---- Type, Public :: Magnetic_Space_Group_Type
    !!----   Integer                                        :: Sh_number
    !!----   character(len=15)                              :: BNS_number
    !!----   character(len=15)                              :: OG_number
    !!----   Character(len=34)                              :: BNS_symbol
    !!----   Character(len=34)                              :: OG_symbol
    !!----   Integer                                        :: MagType
    !!----   Integer                                        :: Parent_num
    !!----   Character(len=20)                              :: Parent_spg
    !!----   logical                                        :: standard_setting  !true or false
    !!----   logical                                        :: mcif !true if mx,my,mz notation is used , false is u,v,w notation is used
    !!----   logical                                        :: m_cell !true if magnetic cell is used for symmetry operators
    !!----   logical                                        :: m_constr !true if constraints have been provided
    !!----   Character(len=40)                              :: trn_from_parent
    !!----   Character(len=40)                              :: trn_to_standard
    !!----   character(len=12)                              :: CrystalSys       ! Crystal system
    !!----   character(len= 1)                              :: SPG_lat          ! Lattice type
    !!----   character(len= 2)                              :: SPG_latsy        ! Lattice type Symbol
    !!----   integer                                        :: Num_Lat           ! Number of lattice points in a cell
    !!----   real(kind=cp), allocatable,dimension(:,:)      :: Latt_trans       ! Lattice translations (3,12)
    !!----   character(len=80)                              :: Centre           ! Alphanumeric information about the center of symmetry
    !!----   integer                                        :: Centred          ! Centric or Acentric [ =0 Centric(-1 no at origin),=1 Acentric,=2 Centric(-1 at origin)]
    !!----   real(kind=cp), dimension(3)                    :: Centre_coord     ! Fractional coordinates of the inversion centre
    !!----   integer                                        :: NumOps           ! Number of reduced set of S.O.
    !!----   Integer                                        :: Multip
    !!----   integer                                        :: Num_gen          ! Minimum number of operators to generate the Group
    !!----   Integer                                        :: n_wyck   !Number of Wyckoff positions of the magnetic group
    !!----   Integer                                        :: n_kv
    !!----   Integer                                        :: n_irreps
    !!----   Integer,             dimension(:),allocatable  :: irrep_dim       !Dimension of the irreps
    !!----   Integer,             dimension(:),allocatable  :: small_irrep_dim !Dimension of the small irrep
    !!----   Integer,             dimension(:),allocatable  :: irrep_modes_number !Number of the mode of the irrep
    !!----   Character(len=15),   dimension(:),allocatable  :: irrep_id        !Labels for the irreps
    !!----   Character(len=20),   dimension(:),allocatable  :: irrep_direction !Irrep direction in representation space
    !!----   Character(len=20),   dimension(:),allocatable  :: irrep_action    !Irrep character primary or secondary
    !!----   Character(len=15),   dimension(:),allocatable  :: kv_label
    !!----   real(kind=cp),     dimension(:,:),allocatable  :: kv
    !!----   character(len=40),   dimension(:),allocatable  :: Wyck_Symb  ! Alphanumeric Symbols for first representant of Wyckoff positions
    !!----   character(len=40),   dimension(:),allocatable  :: SymopSymb  ! Alphanumeric Symbols for SYMM
    !!----   type(Sym_Oper_Type), dimension(:),allocatable  :: SymOp      ! Crystallographic symmetry operators
    !!----   character(len=40),   dimension(:),allocatable  :: MSymopSymb ! Alphanumeric Symbols for MSYMM
    !!----   type(MSym_Oper_Type),dimension(:),allocatable  :: MSymOp     ! Magnetic symmetry operators
    !!---- End Type Magnetic_Space_Group_Type
    !!----
    !!--<<
    !!----    The magnetic group type defined here satisfy all the needs for working with
    !!----    standard data bases for BNS and OG notations and also for working with
    !!----    simplified methods with the crystallographic cell and propagation vectors
    !!----    The component Phas in MSym_Oper_Type is used for time inversion Phas=+1 no time inversion
    !!----    and Phas=-1 if time inversion is associated with the operator (Not needed for real calculations).
    !!-->>
    !!----
    !!----  Created: January - 2014
    !!
    Type, Public :: Magnetic_Space_Group_Type
       Integer                                        :: Sh_number
       character(len=15)                              :: BNS_number
       character(len=15)                              :: OG_number
       Character(len=34)                              :: BNS_symbol
       Character(len=34)                              :: OG_symbol
       Integer                                        :: MagType
       Integer                                        :: Parent_num
       Character(len=20)                              :: Parent_spg
       logical                                        :: standard_setting  !true or false
       logical                                        :: mcif     !true if mx,my,mz notation is used , false is u,v,w notation is used
       logical                                        :: m_cell   !true if magnetic cell is used for symmetry operators
       logical                                        :: m_constr !true if constraints have been provided
       Character(len=40)                              :: trn_from_parent
       Character(len=40)                              :: trn_to_standard
       character(len=12)                              :: CrystalSys       ! Crystal system
       character(len= 1)                              :: SPG_lat          ! Lattice type
       character(len= 2)                              :: SPG_latsy        ! Lattice type Symbol
       integer                                        :: Num_Lat          ! Number of lattice points in a cell
       integer                                        :: Num_aLat         ! Number of anti-lattice points in a cell
       real(kind=cp), allocatable,dimension(:,:)      :: Latt_trans       ! Lattice translations
       real(kind=cp), allocatable,dimension(:,:)      :: aLatt_trans      ! Lattice anti-translations
       character(len=80)                              :: Centre           ! Alphanumeric information about the center of symmetry
       integer                                        :: Centred          ! Centric or Acentric [ =0 Centric(-1 no at origin),=1 Acentric,=2 Centric(-1 at origin)]
       real(kind=cp), dimension(3)                    :: Centre_coord     ! Fractional coordinates of the inversion centre
       integer                                        :: NumOps           ! Number of reduced set of S.O. (removing lattice centring and anticentrings and centre of symmetry)
       Integer                                        :: Multip
       integer                                        :: Num_gen          ! Minimum number of operators to generate the Group
       Integer                                        :: n_wyck           ! Number of Wyckoff positions of the magnetic group
       Integer                                        :: n_kv
       Integer                                        :: n_irreps
       Integer,             dimension(:),allocatable  :: irrep_dim          ! Dimension of the irreps
       Integer,             dimension(:),allocatable  :: small_irrep_dim    ! Dimension of the small irrep
       Integer,             dimension(:),allocatable  :: irrep_modes_number ! Number of the mode of the irrep
       Character(len=15),   dimension(:),allocatable  :: irrep_id           ! Labels for the irreps
       Character(len=20),   dimension(:),allocatable  :: irrep_direction    ! Irrep direction in representation space
       Character(len=20),   dimension(:),allocatable  :: irrep_action       ! Irrep character primary or secondary
       Character(len=15),   dimension(:),allocatable  :: kv_label
       real(kind=cp),     dimension(:,:),allocatable  :: kv
       character(len=40),   dimension(:),allocatable  :: Wyck_Symb  ! Alphanumeric Symbols for first representant of Wyckoff positions
       character(len=40),   dimension(:),allocatable  :: SymopSymb  ! Alphanumeric Symbols for SYMM
       type(Sym_Oper_Type), dimension(:),allocatable  :: SymOp      ! Crystallographic symmetry operators
       character(len=40),   dimension(:),allocatable  :: MSymopSymb ! Alphanumeric Symbols for MSYMM
       type(MSym_Oper_Type),dimension(:),allocatable  :: MSymOp     ! Magnetic symmetry operators
    End Type Magnetic_Space_Group_Type

    !!----
    !!---- TYPE :: MAGNETIC_GROUP_TYPE
    !!--..
    !!---- Type, Public :: Magnetic_Group_Type
    !!----    Character(len=30)           :: Shubnikov !Shubnikov symbol (Hermman-Mauguin + primes)
    !!----    type(Space_Group_Type)      :: SpG       !Crystallographic space group
    !!----    integer, dimension(192)     :: tinv      !When a component is +1 no time inversion is associated
    !!---- End Type Magnetic_Group_Type                !If tinv(i)=-1, the time inversion is associated to operator "i"
    !!----
    !!--<<
    !!----    A magnetic group type is adequate when k=(0,0,0). It contains as the second
    !!----    component the crystallographic space group. The first component is
    !!----    the Shubnikov Group symbol and the third component is an integer vector with
    !!----    values -1 or 1 when time inversion is associated (-1) with the corresponding
    !!----    crystallographic symmetry operator o not (1).
    !!-->>
    !!----
    !!---- Update: April - 2005
    !!
    Type, Public :: Magnetic_Group_Type
       Character(len=30)           :: Shubnikov
       type(Space_Group_Type)      :: SpG
       integer, dimension(192)     :: tinv
    End Type Magnetic_Group_Type
    !!----
    !!---- TYPE :: MAGSYMM_K_TYPE
    !!--..
    !!---- Type, Public :: MagSymm_k_Type
    !!----    character(len=31)                        :: MagModel   ! Name to characterize the magnetic symmetry
    !!----    character(len=10)                        :: Sk_type    ! If Sk_type="Spherical_Frame" the input Fourier coefficients are in spherical components
    !!----    character(len=15)                        :: BNS_number ! Added for keeping the same information
    !!----    character(len=15)                        :: OG_number  ! as in Magnetic_Space_Group_Type
    !!----    Character(len=34)                        :: BNS_symbol !             "
    !!----    Character(len=34)                        :: OG_symbol  !             "
    !!----    Integer                                  :: MagType    !             "
    !!----    Integer                                  :: Parent_num !             "
    !!----    Character(len=20)                        :: Parent_spg !             "
    !!----    character(len=1)                         :: Latt       ! Symbol of the crystallographic lattice
    !!----    integer                                  :: nirreps    ! Number of irreducible representations (max=4, if nirreps /= 0 => nmsym=0)
    !!----    Integer,             dimension(4)        :: irrep_dim       !Dimension of the irreps
    !!----    Integer,             dimension(4)        :: small_irrep_dim !Dimension of the small irrep
    !!----    Integer,             dimension(4)        :: irrep_modes_number !Number of the mode of the irrep
    !!----    Character(len=15),   dimension(4)        :: irrep_id        !Labels for the irreps
    !!----    Character(len=20),   dimension(4)        :: irrep_direction !Irrep direction in representation space
    !!----    Character(len=20),   dimension(4)        :: irrep_action    !Irrep character primary or secondary
    !!----    integer                                  :: nmsym      ! Number of magnetic operators per crystallographic operator (max=8)
    !!----    integer                                  :: centred    ! =0 centric centre not at origin, =1 acentric, =2 centric (-1 at origin)
    !!----    integer                                  :: mcentred   ! =1 Anti/a-centric Magnetic symmetry, = 2 centric magnetic symmetry
    !!----    integer                                  :: nkv        ! Number of independent propagation vectors
    !!----    real(kind=cp),       dimension(3,12)     :: kvec       ! Propagation vectors
    !!----    Character(len=15),   dimension(12)       :: kv_label
    !!----    integer                                  :: Num_Lat    ! Number of centring lattice vectors
    !!----    real(kind=cp), dimension(3,4)            :: Ltr        ! Centring translations
    !!----    integer                                  :: Numops     ! Reduced number of crystallographic Symm. Op.
    !!----    integer                                  :: Multip     ! General multiplicity of the space group
    !!----    integer,             dimension(4)        :: nbas       ! Number of basis functions per irrep (if nbas < 0, the corresponding basis is complex).
    !!----    integer,             dimension(12,4)     :: icomp      ! Indicator (0 pure real/ 1 pure imaginary) for coefficients of basis fucntions
    !!----    Complex(kind=cp),    dimension(3,12,48,4):: basf       ! Basis functions of the irreps of Gk
    !!----    character(len=40),   dimension(:),   allocatable :: SymopSymb  ! Alphanumeric Symbols for SYMM
    !!----    type(Sym_Oper_Type), dimension(:),   allocatable :: SymOp      ! Crystallographic symmetry operators (48)
    !!----    character(len=40),   dimension(:,:), allocatable :: MSymopSymb ! Alphanumeric Symbols for MSYMM (48,8)
    !!----    type(MSym_Oper_Type),dimension(:,:), allocatable :: MSymOp     ! Magnetic symmetry operators (48,8)
    !!---- End Type MagSymm_k_Type
    !!----
    !!----  Definition of the MagSymm_k_type derived type, encapsulating the information
    !!----  concerning the crystallographic symmetry, propagation vectors and magnetic matrices.
    !!----  Needed for calculating magnetic structure factors.
    !!----
    !!---- Created: April   - 2005
    !!---- Updated: January - 2014
    !!
    Type, Public :: MagSymm_k_Type
       character(len=31)                        :: MagModel
       character(len=15)                        :: Sk_type
       character(len=15)                        :: BNS_number ! Added for keeping the same information
       character(len=15)                        :: OG_number  ! as in Magnetic_Space_Group_Type
       Character(len=34)                        :: BNS_symbol !             "
       Character(len=34)                        :: OG_symbol  !             "
       Integer                                  :: MagType    !             "
       Integer                                  :: Parent_num !             "
       Character(len=20)                        :: Parent_spg !             "
       character(len=1)                         :: Latt
       integer                                  :: nirreps
       Integer,             dimension(4)        :: irrep_dim          !Dimension of the irreps
       Integer,             dimension(4)        :: small_irrep_dim    !Dimension of the small irrep
       Integer,             dimension(4)        :: irrep_modes_number !Number of the mode of the irrep
       Character(len=15),   dimension(4)        :: irrep_id           !Labels for the irreps
       Character(len=20),   dimension(4)        :: irrep_direction    !Irrep direction in representation space
       Character(len=20),   dimension(4)        :: irrep_action       !Irrep character primary or secondary
       integer                                  :: nmsym
       integer                                  :: centred
       integer                                  :: mcentred
       integer                                  :: nkv
       real(kind=cp),dimension(3,12)            :: kvec
       integer                                  :: Num_Lat
       real(kind=cp), dimension(3,4)            :: Ltr
       integer                                  :: Numops
       integer                                  :: Multip
       integer,             dimension(4)        :: nbas
       integer,             dimension(12,4)     :: icomp
       Complex(kind=cp),    dimension(3,12,48,4):: basf
       character(len=40),   dimension(:),   allocatable :: SymopSymb  ! Alphanumeric Symbols for SYMM
       type(Sym_Oper_Type), dimension(:),   allocatable :: SymOp      ! Crystallographic symmetry operators (48)
       character(len=40),   dimension(:,:), allocatable :: MSymopSymb ! Alphanumeric Symbols for MSYMM (48,8)
       type(MSym_Oper_Type),dimension(:,:), allocatable :: MSymOp     ! Magnetic symmetry operators (48,8)
    End Type MagSymm_k_Type

    !!----
    !!---- ERR_MAGSYM
    !!----    logical, public :: err_MagSym
    !!----
    !!----    Logical Variable indicating an error in CFML_Magnetic_Symmetry
    !!----
    !!---- Update: April - 2005
    !!
    logical, public :: err_MagSym

    !!----
    !!---- ERR_MAGSYM_MESS
    !!----    character(len=150), public :: ERR_MagSym_Mess
    !!----
    !!----    String containing information about the last error
    !!----
    !!---- Update: April - 2005
    !!
    character(len=150), public :: ERR_MagSym_Mess

    Interface  Readn_Set_Magnetic_Structure
       Module Procedure Readn_Set_Magnetic_Structure_CFL
       Module Procedure Readn_Set_Magnetic_Structure_MCIF
    End Interface  Readn_Set_Magnetic_Structure

 Contains

    !-------------------!
    !---- Functions ----!
    !-------------------!

    !!----
    !!---- Function ApplyMso(Op,Sk) Result(Skp)
    !!----    Type(MSym_Oper_Type),   intent(in) :: Op        !  Magnetic Symmetry Operator Type
    !!----    complex, dimension(3) , intent(in) :: Sk        !  Complex vector
    !!----    complex, dimension(3)              :: Skp       !  Transformed complex vector
    !!----
    !!----    Apply a magnetic symmetry operator to a complex vector:  Skp = ApplyMSO(Op,Sk)
    !!----
    !!---- Update: April - 2005
    !!
    Function ApplyMSO(Op,Sk) Result(Skp)
       !---- Arguments ----!
       Type(MSym_Oper_Type), intent(in) :: Op
       Complex, dimension(3),intent(in) :: Sk
       Complex, dimension(3)            :: Skp

       Skp = matmul(Op%Rot,Sk) * cmplx(cos(tpi*Op%Phas),sin(tpi*Op%Phas))

       return
    End Function ApplyMSO

    !!---- Function is_Lattice_vec(V,Ltr,nlat,nl) Result(Lattice_Transl)
    !!----    !---- Argument ----!
    !!----    real(kind=cp), dimension(3),   intent( in) :: v
    !!----    real(kind=cp), dimension(:,:), intent( in) :: Ltr
    !!----    integer,                       intent( in) :: nlat
    !!----    integer,                       intent(out) :: nl
    !!----    logical                                    :: Lattice_Transl
    !!----
    !!----  Logical function that provides the value .true. if the vector V is a
    !!----  lattice vector.
    !!----
    !!----  Created: February 2014 (JRC)
    !!----
    Function is_Lattice_vec(V,Ltr,nlat,nl) Result(Lattice_Transl)
       !---- Argument ----!
       real(kind=cp), dimension(3),   intent( in) :: v
       real(kind=cp), dimension(:,:), intent( in) :: Ltr
       integer,                       intent( in) :: nlat
       integer,                       intent(out) :: nl
       logical                                    :: Lattice_Transl

       !---- Local variables ----!
       real(kind=cp)   , dimension(3) :: vec
       integer                        :: i

       Lattice_Transl=.false.
       nl=0

       if (Zbelong(v)) then       ! if v is an integral vector =>  v is a lattice vector
          Lattice_Transl=.true.
       else                       ! if not look for lattice type
          do i=1,nlat
            vec=Ltr(:,i)-v
            if (Zbelong(vec)) then
              Lattice_Transl=.true.
              nl=i
              exit
            end if
          end do
       end if
       return
    End Function is_Lattice_vec

    !!---- Function get_magnetic_form_factor(element) result(formf)
    !!----   character(len=*),intent(in) :: element
    !!----   character(len=6)            :: formf
    !!----
    !!----   Function to get the symbol for the magnetic scattering vector corresponding to the
    !!----   input symbol (element + valence state). Useful for transforming magCIF files to PCR.
    !!----
    !!----  Created: February 2014 (JRC)
    !!----
    Function get_magnetic_form_factor(element) result(formf)
      character(len=*),intent(in) :: element
      character(len=6)            :: formf
      ! Local variables
      logical :: is_re
      integer :: i,valence,ier
      character(len=6)   :: melem,aux
      integer, parameter :: n_re =12
      character(len=*), parameter, dimension(n_re) :: re=(/"ce","pr","nd","sm","eu","gd","tb","dy","ho","er","tm","yb"/)

      melem=l_case(element)
      is_re=.false.
      do i=1,n_re
        if(index(melem,re(i)) /= 0) then
          is_re=.true.
           exit
        end if
      end do
      if(is_re) then
        aux=melem(3:)
        i=index(aux,"+")
        if(i /= 0) then
          aux(i:i)=" "
          read(unit=aux,fmt=*,iostat=ier) valence
          if(ier /= 0) valence=3
        else
           valence=3
        end if
        write(unit=formf,fmt="(a,i1)") "J"//melem(1:2),valence
      else
        i=index(melem,"+")
        if(i /= 0) then
          melem(i:i)=" "
          aux=melem(i-1:i-1)
          read(unit=aux,fmt=*,iostat=ier) valence
          if(ier /= 0) valence=3
          melem(i-1:i-1)=" "
        else
           valence=2
        end if
        write(unit=formf,fmt="(a,i1)") "M"//trim(melem),valence
      end if
      formf=u_case(formf)
      return
    End Function get_magnetic_form_factor


    !---------------------!
    !---- Subroutines ----!
    !---------------------!

    !!---- Subroutine Calc_Induced_Sk(cell,SpG,MField,dir_MField,Atm)
    !!----    !---- Arguments ----!
    !!----   type(Crystal_Cell_type),    intent(in)     :: Cell
    !!----   type(Space_Group_Type),     intent(in)     :: SpG
    !!----   real(kind=cp),              intent(in)     :: MField
    !!----   real(kind=cp),dimension(3), intent(in)     :: dir_MField
    !!----   type(Matom_list_type),    intent(in out)   :: Atm
    !!----
    !!----  This subroutine completes the object Am by calculating the
    !!----  induced magnetic moments of the representant atoms in the asymmetric unit.
    !!----  It modifies also the Chi tensor according to the symmetry constraints of
    !!----  the crystallographic site.
    !!----
    !!----  Created: June 2014 (JRC)
    !!----
    Subroutine Calc_Induced_Sk(cell,SpG,MField,dir_MField,Atm,ipr)
       !---- Arguments ----!
       type(Crystal_Cell_type),    intent(in)     :: Cell
       type(Space_Group_Type),     intent(in)     :: SpG
       real(kind=cp),              intent(in)     :: MField
       real(kind=cp),dimension(3), intent(in)     :: dir_MField
       type(Matom_list_type),    intent(in out)   :: Atm
       integer, optional,          intent(in)     :: ipr
       !--- Local variables ---!
       integer                          :: i,codini
       integer, dimension(6)            :: icodes
       real(kind=cp)                    :: s
       real(kind=cp),    dimension(6)   :: multip
       real(kind=cp),    dimension(3)   :: u_vect,x
       real(kind=cp),    dimension(3,3) :: chi

       !
       u_vect=MField * dir_MField / Veclength(Cell%Cr_Orth_cel,dir_MField)
       if(present(ipr)) write(unit=ipr,fmt="(a,3f8.4)") " => Applied Magnetic Field: ",u_vect
       icodes=(/1,2,3,4,5,6/); multip=(/1.0,1.0,1.0,1.0,1.0,1.0/)
       codini=1
       do i=1,Atm%natoms
          x=atm%atom(i)%x
          call Get_Atom_2nd_Tensor_Ctr(x,atm%atom(i)%chi,SpG,Codini,Icodes,Multip)
          chi=reshape((/atm%atom(i)%chi(1),atm%atom(i)%chi(4), atm%atom(i)%chi(5), &
                        atm%atom(i)%chi(4),atm%atom(i)%chi(2), atm%atom(i)%chi(6), &
                        atm%atom(i)%chi(6),atm%atom(i)%chi(6), atm%atom(i)%chi(3) /),(/3,3/))
          Atm%atom(i)%SkR(:,1)=matmul(Chi,u_vect)
          Atm%atom(i)%SkI(:,1)=0.0
          if(present(ipr)) then
             write(unit=ipr,fmt="(a,i3,a,6f8.4)")     " Atom # ",i," Chi      values: ",atm%atom(i)%chi
             write(unit=ipr,fmt="(a,6i4,6f6.2)")      "            Chi constraints: ",Icodes,multip
             write(unit=ipr,fmt="(a,3f8.4)")          "            Induced  Moment: ",Atm%atom(i)%SkR(:,1)
          end if
       end do ! Atoms

       return
    End Subroutine Calc_Induced_Sk

    !!---- Subroutine Cleanup_Symmetry_Operators(MSpG)
    !!----   Type(Magnetic_Space_Group_Type), intent(in out) :: MSpG
    !!----
    !!----  Subroutine to re-organize symmetry operators extrancting lattice translations
    !!----  and anti-translations and reordering the whole set of operators.
    !!----  (Still under development)
    !!----
    !!----  Created: February 2014 (JRC)
    !!----
    Subroutine Cleanup_Symmetry_Operators(MSpG)
      Type(Magnetic_Space_Group_Type), intent(in out) :: MSpG
      !--- Local variables ---!
      integer,      dimension(3,3,MSpG%Multip) :: ss
      real(kind=cp),dimension(3,  MSpG%Multip) :: ts
      integer,      dimension(    MSpG%Multip) :: p,ip,it
      logical,      dimension(    MSpG%Multip) :: nul
      real(kind=cp),dimension(3,192)           :: Lat_tr
      real(kind=cp),dimension(3,192)           :: aLat_tr
      integer :: i,j,k,L,m, Ng,num_lat, num_alat,invt,nl,i_centre
      !integer :: Ibravl,Isystm, out
     ! character(len=1) :: Latsym
     ! character(len=2) :: Latsy
      integer, dimension(3,3) :: identity, nulo, inver,mat,imat
      real(kind=cp),dimension(3) ::  v !Co,
      character(len=80)          :: ShOp_symb ! SpaceGen ,
      logical                    :: centrosymm
      character (len=*),dimension(0:2), parameter  :: Centro = &
                                         (/"Centric (-1 not at origin)", &
                                           "Acentric                  ", &
                                           "Centric (-1 at origin)    "/)
      !Type(Magnetic_Space_Group_Type) :: MSpGn

      !MSpGn=MSpG  !copy with allocation in F2003
      identity=0; nulo=0
      do i=1,3
        identity(i,i)=1
      end do
      inver=-identity
      num_lat=0; num_alat=0
      p=0
      i=0
      k=0
      centrosymm=.false.
      nul=.false.
      do j=2,MSpG%Multip
        invt= nint(MSpG%MSymOp(j)%phas)
        if(equal_matrix(identity,MSpG%SymOp(j)%Rot(:,:),3)) then
           i=i+1
           if(invt == 1) then
              num_lat=num_lat+1
              Lat_tr(:,num_lat)=MSpG%SymOp(j)%tr(:)
              p(j)=10
              nul(j)=.true.
           else
              num_alat=num_alat+1
              aLat_tr(:,num_alat)=MSpG%SymOp(j)%tr(:)
              p(j)=-10
              nul(j)=.true.
           end if
        else if (equal_matrix(inver,MSpG%SymOp(j)%Rot(:,:),3)) then
           k=k+1
           if(invt == 1) then
             p(j)=20
             if(.not. centrosymm) then
               centrosymm=.true.
               i_centre=j
             end if
           else
             p(j)=-20
           end if
           nul(j)=.true.
        else
           p(j)=axes_rotation(MSpG%SymOp(j)%Rot(:,:))    ! Determine the order of the operator
        end if
      end do
      if(num_lat > 0) then
        if(allocated(MSpG%Latt_trans)) deallocate(MSpG%Latt_trans)
        allocate(MSpG%Latt_trans(3,num_lat+1))
         MSpG%Latt_trans=0.0
         m=1
        do j=1,num_lat
          m=m+1
          MSpG%Latt_trans(:,m)   = Lat_tr(:,j)
        end do
        MSpG%Num_Lat=num_lat+1
      end if
      if(num_alat > 0) then
        if(allocated(MSpG%aLatt_trans)) deallocate(MSpG%aLatt_trans)
        allocate(MSpG%aLatt_trans(3,num_alat))
        MSpG%aLatt_trans   = aLat_tr(:,1:num_alat)
        MSpG%Num_aLat=num_alat
      end if
      !do i=1,num_lat
      !   write(*,"(i6,a,3f12.5,a)")i," Lattice Centring Translation:  (",Lat_tr(:,i),")"
      !end do
      !do i=1,num_alat
      !   write(*,"(i6,a,3f12.5,a)")i," Lattice Centring Anti-Translation:  (",aLat_tr(:,i),")"
      !end do

      !Nullify the operators that can be deduced from others by applying translations,
      !anti-translations and centre of symmetry
      ip=0; it=0
      do j=2,MSpG%Multip-1
         if(nul(j)) cycle
         do i=j+1,MSpG%Multip
           if(nul(i)) cycle
           mat=MSpG%SymOp(i)%Rot(:,:)-MSpG%SymOp(j)%Rot(:,:)
           if(equal_matrix(mat,nulo,3) ) then
              v=MSpG%SymOp(i)%tr(:)-MSpG%SymOp(j)%tr(:)

              if(is_Lattice_vec(V,Lat_tr,num_lat,nl)) then
                 nul(i)=.true.
                 ip(i)=j
                 it(i)=nl
                 cycle
              end if


              if(is_Lattice_vec(V,aLat_tr,num_alat,nl)) then
                 nul(i)=.true.
                 ip(i)=j
                 it(i)=-nl
                 cycle
              end if

           end if

           if(centrosymm) then
              imat=MSpG%SymOp(i)%Rot(:,:)+MSpG%SymOp(j)%Rot(:,:)
              if(equal_matrix(imat,nulo,3)) then
                 v=MSpG%SymOp(i_centre)%tr(:)-MSpG%SymOp(i)%tr(:)-MSpG%SymOp(j)%tr(:)

                 if(is_Lattice_vec(V,Lat_tr,num_lat,nl)) then
                    nul(i)=.true.
                    ip(i)=i_centre
                    it(i)=nl
                    cycle
                 end if

                 if(is_Lattice_vec(V,aLat_tr,num_alat,nl)) then
                    nul(i)=.true.
                    ip(i)=j
                    it(i)=-nl
                    cycle
                 end if
              end if

           end if
         end do
      end do
      j=0
      do i=1,MSpG%Multip
        if(nul(i) .or. i==i_centre) cycle
        j=j+1
        ss(:,:,j)=MSpG%SymOp(i)%Rot
        ts(:,j) = MSpG%SymOp(i)%tr
        ip(j)   = nint(MSpG%MSymOp(i)%phas)
        !write(*,"(i6,a,t70,4i4)") j, "  "//trim(MSpG%SymOpSymb(i))//"   "//trim(MSpG%MSymOpSymb(i)), nint(MSpG%MSymOp(i)%phas),p(i),ip(i),it(i)
      end do
      MSpG%Numops=j !This is the reduced set of symmetry operators

      !Construct in an ordered way all the symmetry operators in MSpG
      !Replacing the operators in the proper order
      do i=1,MSpG%Numops
        MSpG%SymOp(i)%Rot= ss(:,:,i)
        MSpG%SymOp(i)%tr= ts(:,i)
        MSpG%MSymOp(i)%phas= ip(i)
        MSpG%MSymOp(i)%Rot=determ_A(ss(:,:,i))*ip(i)*ss(:,:,i)
      end do
      m=MSpG%Numops
      if(centrosymm) then   !First apply the centre of symmetry
        v=MSpG%SymOp(i_centre)%tr
        do i=1,MSpG%Numops
          m=m+1
          MSpG%SymOp(m)%Rot  = -MSpG%SymOp(i)%Rot
          MSpG%SymOp(m)%tr   =  modulo_lat(-MSpG%SymOp(i)%tr+v)
          MSpG%MSymOp(m)%phas= MSpG%MSymOp(i)%phas
          MSpG%MSymOp(m)%Rot = MSpG%MSymOp(i)%Rot
        end do
      end if
      ng=m
      if(MSpG%Num_Lat > 1) then  !Second apply the lattice centring translations
        do L=2,MSpG%Num_Lat
           do i=1,ng
             m=m+1
             v=MSpG%SymOp(i)%tr(:) + MSpG%Latt_trans(:,L)
             MSpG%SymOp(m)%Rot  = MSpG%SymOp(i)%Rot
             MSpG%SymOp(m)%tr   = modulo_lat(v)
             MSpG%MSymOp(m)%Rot = MSpG%MSymOp(i)%Rot
             MSpG%MSymOp(m)%phas= MSpG%MSymOp(i)%phas
           end do
        end do
      end if
      if(MSpG%Num_aLat > 0) then   !Third apply the lattice centring anti-translations
        do L=1,MSpG%Num_aLat
           do i=1,ng
             m=m+1
             v=MSpG%SymOp(i)%tr(:) + MSpG%aLatt_trans(:,L)
             MSpG%SymOp(m)%Rot  = MSpG%SymOp(i)%Rot
             MSpG%SymOp(m)%tr   = modulo_lat(v)
             MSpG%MSymOp(m)%Rot = -MSpG%MSymOp(i)%Rot
             MSpG%MSymOp(m)%phas= -MSpG%MSymOp(i)%phas
           end do
        end do
      end if
      !Normally here the number of operators should be equal to multiplicity
      ng=m
      if(ng /= MSpG%Multip) write(*,*) "  Problem! the multiplicity has not been recovered, value of ng=",ng
      !now generate all symbols for symmetry operators and magnetic matrices
      do i=1,MSpG%Multip
         call Get_Shubnikov_Operator_Symbol(MSpG%SymOp(i)%Rot,MSpG%MSymOp(i)%Rot,MSpG%SymOp(i)%tr,ShOp_symb,.true.)
        !write(*,"(i6,a,i4)") i, "  "//trim(MSpG%SymOpSymb(i))//"   "//trim(MSpG%MSymOpSymb(i)), nint(MSpG%MSymOp(i)%phas)
        !write(*,"(i6,a)") i, "  "//trim(ShOp_symb)
      end do
      !write(*,"(a)")
     !do i=1,MSpG%Multip
     ! Select Case (p(i))
     !   Case(10)
     !     write(*,"(i6,a,t70,4i4,L4)") i, "     Translation: "//trim(MSpG%SymOpSymb(i))//"   "//trim(MSpG%MSymOpSymb(i)), nint(MSpG%MSymOp(i)%phas),p(i),ip(i),it(i),nul(i)
     !   Case(-10)
     !     write(*,"(i6,a,t70,4i4,L4)") i, " Antitranslation: "//trim(MSpG%SymOpSymb(i))//"   "//trim(MSpG%MSymOpSymb(i)), nint(MSpG%MSymOp(i)%phas),p(i),ip(i),it(i),nul(i)
     !   Case(20)
     !     write(*,"(i6,a,t70,4i4,L4)") i, "          Centre: "//trim(MSpG%SymOpSymb(i))//"   "//trim(MSpG%MSymOpSymb(i)), nint(MSpG%MSymOp(i)%phas),p(i),ip(i),it(i),nul(i)
     !   Case(-20)
     !     write(*,"(i6,a,t70,4i4,L4)") i, "      Anticentre: "//trim(MSpG%SymOpSymb(i))//"   "//trim(MSpG%MSymOpSymb(i)), nint(MSpG%MSymOp(i)%phas),p(i),ip(i),it(i),nul(i)
     !   Case Default
     !     write(*,"(i6,a,t70,4i4,L4)") i, "       Other Op.: "//trim(MSpG%SymOpSymb(i))//"   "//trim(MSpG%MSymOpSymb(i)), nint(MSpG%MSymOp(i)%phas),p(i),ip(i),it(i),nul(i)
     ! End Select
     !end do

      !write(*,"(2i8,a,i4)")k,j,"   Centre at:  "//trim(MSpG%SymOpSymb(j))//"   "//trim(MSpG%MSymOpSymb(j)), invt
      !do j=1,NG
      !  i=p(j)
      !  if(i == 0) exit
      !  write(*,"(2i6,a,i4)")j,i, "    "//trim(MSpG%SymOpSymb(i))//"   "//trim(MSpG%MSymOpSymb(i)), nint(MSpG%MSymOp(i)%phas)
      !end do
      return
    End Subroutine Cleanup_Symmetry_Operators

    !!----
    !!---- Subroutine Init_Err_MagSym()
    !!----
    !!----    Initialize the errors flags in this Module
    !!----
    !!---- Update: March - 2005
    !!
    Subroutine Init_Err_MagSym()

       err_magsym=.false.
       ERR_MagSym_Mess=" "

       return
    End Subroutine Init_Err_MagSym

    !!----
    !!---- subroutine Init_MagSymm_k_Type(MGp)
    !!----   type(MagSymm_k_Type),  intent (in out) :: MGp
    !!----
    !!----   Subroutine to initialize the MagSymm_k_Type variable MGp.
    !!----   It is called inside Readn_set_Magnetic_Structure
    !!----
    !!----  Update: April 2005, January 2014
    !!
    Subroutine Init_MagSymm_k_Type(MGp)
       !---- Arguments ----!
       type(MagSymm_k_Type),  intent (in out) :: MGp

       MGp%MagModel="Unnamed Model"
       MGp%Sk_Type="Crystal_Frame"       ! "Spherical_Frame"
       MGp%Latt="P"
       MGp%BNS_number=" "
       MGp%OG_number=" "
       MGp%BNS_symbol=" "
       MGp%OG_symbol=" "
       MGp%MagType=0
       MGp%Parent_num=0
       MGp%Parent_spg=" "
       MGp%nmsym=0
       MGp%nirreps=0
       MGp%irrep_dim=0          !Dimension of the irreps
       MGp%small_irrep_dim=0    !Dimension of the small irrep
       MGp%irrep_modes_number=0 !Number of the mode of the irrep
       MGp%irrep_id=" "         !Labels for the irreps
       MGp%irrep_direction=" "  !Irrep direction in representation space
       MGp%irrep_action=" "     !Irrep character primary or secondary
       MGp%centred=1    !By default the crystal structure is acentric
       MGp%mcentred=1   !By default the magnetic structure is anti-centric (if there is -1 it is combined with time inversion)
       MGp%nkv=0
       MGp%kvec=0.0
       MGp%Num_Lat=1
       MGp%Ltr=0.0
       MGp%Numops=0
       MGp%Multip=0
       MGp%nbas=0
       MGp%icomp=0
       MGp%basf=cmplx(0.0,0.0)
       return
    End Subroutine Init_MagSymm_k_Type

    !!---- Subroutine Init_Magnetic_Space_Group_Type(MGp)
    !!----   type(Magnetic_Space_Group_Type),  intent (in out) :: MGp
    !!----
    !!----   Initialize the non-allocatle parts of Magnetic_Space_Group_Type MGp
    !!----   It is called inside Readn_set_Magnetic_Structure
    !!----
    !!----   Updated: January-2014
    !!
    Subroutine Init_Magnetic_Space_Group_Type(MGp)
       !---- Arguments ----!
       type(Magnetic_Space_Group_Type),  intent (in out) :: MGp

       !---- Local variables ----!

       MGp%Sh_number=0
       MGp%BNS_number=" "
       MGp%OG_number=" "
       MGp%BNS_symbol=" "
       MGp%OG_symbol=" "
       MGp%MagType=0
       MGp%Parent_num=0
       MGp%Parent_spg=" "
       MGp%standard_setting=.false.
       MGp%mcif=.true.
       MGp%m_cell=.false.
       MGp%m_constr=.false.
       MGp%trn_from_parent=" "
       MGp%trn_to_standard=" "
       MGp%Multip=0
       MGp%n_wyck=0
       MGp%n_kv=0
       return
    End Subroutine Init_Magnetic_Space_Group_Type

    Subroutine Magnetic_Space_Group_Type_to_MagSymm_k_Type(MSpG,mode,MG_Symk)
       Type(Magnetic_Space_Group_Type),   intent(in)  :: MSpG
       character(len=*),                  intent(in)  :: mode
       Type(MagSymm_k_Type),              intent(out) :: MG_Symk
       !---- Local variables ----!
       integer :: i,k
       logical :: full_convertion
       !real(kind=cp)        :: ph
       character(len=132)    :: line !lowline,
       !character(len=30)    :: magmod, shubk
       !character(len=2)     :: lattice, chardom
       !character(len=4)     :: symbcar
       character(Len=*),dimension(4),parameter :: cod=(/"a","b","c",";"/)
       real(kind=cp), dimension(3,3) :: Mat  !Matrix from parent space group to actual setting in magnetic cell
       real(kind=cp), dimension(3)   :: v    !Change of origin with respect to the standard
       !
       call Init_MagSymm_k_Type(MG_Symk)

       full_convertion=.false.
       if(MSpG%parent_num > 0 .or. len_trim(MSpG%Parent_spg) /= 0) Then
         if(len_trim(MSpG%trn_from_parent) /= 0) then !The transformation from the parent space group to the
            call Get_Transf(MSpG%trn_from_parent,mat,v,cod)  !actual given cell is read from this item
            if(Err_String) then
               full_convertion=.false.
            else
               full_convertion=.true.
            end if
         end if
       end if

       Select Case (l_case(Mode(1:2)))
         Case("mc")  !Use magnetic cell is equivalent to use a k=0 in MG_Symk
             if(MSpG%m_cell) then
                MG_Symk%MagModel  ="Using the magnetic cell "
                MG_Symk%Sk_Type   ="Crystal_Frame"
                MG_Symk%BNS_number=MSpG%BNS_number
                MG_Symk%OG_number =MSpG%OG_number
                MG_Symk%BNS_symbol=MSpG%BNS_symbol
                MG_Symk%OG_symbol =MSpG%OG_symbol
                MG_Symk%MagType   =MSpG%MagType
                MG_Symk%Parent_num=MSpG%Parent_num
                MG_Symk%Parent_spg=MSpG%Parent_spg
                MG_Symk%Latt="P"
                MG_Symk%nmsym=1
                MG_Symk%nirreps=0
                MG_Symk%centred=1    !By default the crystal structure is acentric
                MG_Symk%mcentred=1   !By default the magnetic structure is anti-centric (if there is -1 it is combined with time inversion)
                MG_Symk%nkv=1        !always a propagation vector even if not provided in MSpG
                MG_Symk%kvec=0.0     !The propagation vector is assumed to be (0,0,0) w.r.t. "magnetic cell"
                MG_Symk%Num_Lat=1    !No lattice centring are considered (all of them should be included in the list of operators)
                MG_Symk%Ltr=0.0
                MG_Symk%Numops=MSpG%Multip  !Reduced number of symmetry operators is equal to the multiplicity in this
                MG_Symk%Multip=MSpG%Multip  !case ...
                allocate(MG_Symk%Symop(MSpG%Multip))
                allocate(MG_Symk%SymopSymb(MSpG%Multip))
                allocate(MG_Symk%MSymop(MSpG%Multip,1))
                allocate(MG_Symk%MSymopSymb(MSpG%Multip,1))
                MG_Symk%Symop=MSpG%Symop
                do i=1,MG_Symk%Multip
                  MG_Symk%MSymop(i,1)=MSpG%MSymop(i)
                end do
                if(MSpG%mcif) then
                    do i=1,MG_Symk%Multip
                       line=MSpG%MSymopSymb(i)
                       do k=1,len_trim(line)
                         if(line(k:k) == "m") line(k:k)=" "
                         if(line(k:k) == "x") line(k:k)="u"
                         if(line(k:k) == "y") line(k:k)="v"
                         if(line(k:k) == "z") line(k:k)="w"
                       end do
                       line=Pack_String(line)//", 0.0"
                       MG_Symk%MSymopSymb(i,1)=trim(line)
                    end do
                else
                    do i=1,MG_Symk%Multip
                      MG_Symk%MSymopSymb(i,1)=MSpG%MSymopSymb(i)
                    end do
                end if
             else
                Err_Magsym=.true.
                Err_Magsym_Mess=" The magnetic cell in the Magnetic_Space_Group_Type is not provided! Use mode CC!"
                return
             end if

         Case("cc")
             !This only possible if full_convertion is true
             if(full_convertion) then
                MG_Symk%MagModel  = "Using the crystal cell and k-vectors "
                MG_Symk%Sk_Type   = "Crystal_Frame"
                MG_Symk%BNS_number= MSpG%BNS_number
                MG_Symk%OG_number = MSpG%OG_number
                MG_Symk%BNS_symbol= MSpG%BNS_symbol
                MG_Symk%OG_symbol = MSpG%OG_symbol
                MG_Symk%MagType   = MSpG%MagType
                MG_Symk%Parent_num= MSpG%Parent_num
                MG_Symk%Parent_spg= MSpG%Parent_spg
                MG_Symk%Latt      = MSpG%Parent_spg(1:1)
                MG_Symk%nmsym     = 1
                MG_Symk%nirreps=0

                MG_Symk%centred=1    !By default the crystal structure is acentric
                MG_Symk%mcentred=1   !By default the magnetic structure is anti-centric (if there is -1 it is combined with time inversion)
                MG_Symk%nkv=1        !always a propagation vector even if not provided in MSpG
                MG_Symk%kvec=0.0     !The propagation vector is assumed to be (0,0,0) w.r.t. "magnetic cell"
                MG_Symk%Num_Lat=1    !No lattice centring are considered (all of them should be included in the list of operators)
                MG_Symk%Ltr=0.0
                MG_Symk%Numops=MSpG%Multip  !Reduced number of symmetry operators is equal to the multiplicity in this
                MG_Symk%Multip=MSpG%Multip  !case ...
                allocate(MG_Symk%Symop(MSpG%Multip))
                allocate(MG_Symk%SymopSymb(MSpG%Multip))
                allocate(MG_Symk%MSymop(MSpG%Multip,1))
                allocate(MG_Symk%MSymopSymb(MSpG%Multip,1))
                MG_Symk%Symop=MSpG%Symop
                do i=1,MG_Symk%Multip
                  MG_Symk%MSymop(i,1)=MSpG%MSymop(i)
                end do
                if(MSpG%mcif) then
                    do i=1,MG_Symk%Multip
                       line=MSpG%MSymopSymb(i)
                       do k=1,len_trim(line)
                         if(line(k:k) == "m") line(k:k)=" "
                         if(line(k:k) == "x") line(k:k)="u"
                         if(line(k:k) == "y") line(k:k)="v"
                         if(line(k:k) == "z") line(k:k)="w"
                       end do
                       line=Pack_String(line)//", 0.0"
                       MG_Symk%MSymopSymb(i,1)=trim(line)
                    end do
                else
                    do i=1,MG_Symk%Multip
                      MG_Symk%MSymopSymb(i,1)=MSpG%MSymopSymb(i)
                    end do
                end if
             else
                Err_Magsym=.true.
                Err_Magsym_Mess=&
                " This option is available only if the parent group and the transformation has ben provided! Use mode MC!"
                return
             end if

       End Select

       !First determine if there is propagation vector information
       !Integer                              :: Sh_number
       !character(len=15)                    :: BNS_number
       !character(len=15)                    :: OG_number
       !Character(len=34)                    :: BNS_symbol
       !Character(len=34)                    :: OG_symbol
       !Integer                              :: MagType
       !Integer                              :: Parent_num
       !Character(len=20)                    :: Parent_spg
       !logical                              :: standard_setting  !true or false
       !logical                              :: mcif !true if mx,my,mz notation is used , false is u,v,w notation is used
       !logical                              :: m_cell !true if magnetic cell is used for symmetry operators
       !logical                              :: m_constr !true if constraints have been provided
       !Character(len=40)                    :: trn_from_parent
       !Character(len=40)                    :: trn_to_standard
       !Integer                              :: Multip
       !Integer                              :: n_wyck   !Number of Wyckoff positions of the magnetic group
       !Integer                              :: n_kv
       !Integer                              :: n_irreps
       !Integer,             dimension(:),allocatable  :: irrep_dim       !Dimension of the irreps
       !Integer,             dimension(:),allocatable  :: small_irrep_dim !Dimension of the small irrep
       !Integer,             dimension(:),allocatable  :: irrep_modes_number !Number of the mode of the irrep
       !Character(len=15),   dimension(:),allocatable  :: irrep_id        !Labels for the irreps
       !Character(len=20),   dimension(:),allocatable  :: irrep_direction !Irrep direction in representation space
       !Character(len=20),   dimension(:),allocatable  :: irrep_action    !Irrep character primary or secondary
       !Character(len=15),   dimension(:),allocatable  :: kv_label
       !real(kind=cp),     dimension(:,:),allocatable  :: kv
       !character(len=40),   dimension(:),allocatable  :: Wyck_Symb  ! Alphanumeric Symbols for first representant of Wyckoff positions
       !character(len=40),   dimension(:),allocatable  :: SymopSymb  ! Alphanumeric Symbols for SYMM
       !type(Sym_Oper_Type), dimension(:),allocatable  :: SymOp      ! Crystallographic symmetry operators
       !character(len=40),   dimension(:),allocatable  :: MSymopSymb ! Alphanumeric Symbols for MSYMM
       !type(MSym_Oper_Type),dimension(:),allocatable  :: MSymOp     ! Magnetic symmetry operators

       return
    End Subroutine Magnetic_Space_Group_Type_to_MagSymm_k_Type


    Subroutine MagSymm_k_Type_to_Magnetic_Space_Group_Type(MG_Symk,mode,MSpG)
       Type(MagSymm_k_Type),              intent(in)  :: MG_Symk
       character(len=*),                  intent(in)  :: mode
       Type(Magnetic_Space_Group_Type),   intent(out) :: MSpG
       !---- Local variables ----!
       Type(Space_Group_Type) :: SpG
       integer :: i,m,n, ngen
       character(len=40),dimension(:), allocatable   :: gen
       !character(len=132)   :: lowline
       !character(len=30)    :: magmod, shubk
       !character(len=2)     :: lattice, chardom
       !character(len=4)     :: symbcar

       !
       call Init_Magnetic_Space_Group_Type(MSpG)

       !Verify the crystal structure information contained in MG_Symk by constructing the full Space group
       n=MG_Symk%Numops
       m=MG_Symk%Numops*MG_Symk%centred*MG_Symk%Num_Lat
       ngen=n-1
       allocate(gen(ngen))
       ngen=0
       do i=2,MG_Symk%Numops
         ngen=ngen+1
         gen(ngen)=MG_Symk%SymopSymb(i)
       end do
       if(MG_Symk%centred == 2) then
         ngen=ngen+1
         gen(ngen)="-x,-y,-z"
       end if
       Select Case(MG_Symk%Latt)
       End Select
       if(MG_Symk%Latt == "A") then
           ngen=ngen+1
           call Get_SymSymb(MG_Symk%SymOp(1)%rot,MG_Symk%Ltr(:,i),gen(ngen))
           gen(ngen)="-x,-y,-z"
       end if
       !Still to be finished
       call Set_SpaceGroup(" ",SpG,gen,ngen,"gen")

       return
    End Subroutine MagSymm_k_Type_to_Magnetic_Space_Group_Type


    !!----
    !!---- Subroutine Readn_Set_Magnetic_Structure_CFL(file_cfl,n_ini,n_end,MGp,Am,SGo,Mag_dom,Cell)
    !!----    type(file_list_type),                intent (in)     :: file_cfl
    !!----    integer,                             intent (in out) :: n_ini, n_end
    !!----    type(MagSymm_k_Type),                intent (out)    :: MGp
    !!----    type(mAtom_List_Type),               intent (out)    :: Am
    !!----    type(Magnetic_Group_Type), optional, intent (out)    :: SGo
    !!----    type(Magnetic_Domain_type),optional, intent (out)    :: Mag_dom
    !!----    type(Crystal_Cell_type),   optional, intent (in)     :: Cell
    !!----
    !!----    Subroutine for reading and construct the MagSymm_k_Type variable MGp.
    !!----    It is supposed that the CFL file is included in the file_list_type
    !!----    variable file_cfl. On output n_ini, n_end hold the lines with the
    !!----    starting and ending lines with information about a magnetic phase.
    !!----    Optionally the Magnetig space group (Shubnikov group) may be obtained
    !!----    separately for further use.
    !!----    Magnetic S-domains are also read in case of providing the optional variable Mag_dom.
    !!----
    !!---- Updates: November-2006, December-2011, July-2012 (JRC)
    !!
    Subroutine Readn_Set_Magnetic_Structure_CFL(file_cfl,n_ini,n_end,MGp,Am,SGo,Mag_dom,Cell)
       !---- Arguments ----!
       type(file_list_type),                intent (in)     :: file_cfl
       integer,                             intent (in out) :: n_ini, n_end
       type(MagSymm_k_Type),                intent (out)    :: MGp
       type(mAtom_List_Type),               intent (out)    :: Am
       type(Magnetic_Group_Type), optional, intent (out)    :: SGo
       type(Magnetic_Domain_type),optional, intent (out)    :: Mag_dom
       type(Crystal_Cell_type),   optional, intent (in)     :: Cell

       !---- Local Variables ----!
       integer :: i,no_iline,no_eline, num_k, num_xsym, num_irrep, num_dom, num_defdom, &
                  num_msym, ier, j, m, n, num_matom, num_skp, ik,im, ip, ncar
       integer,      dimension(5)    :: pos
       real(kind=cp), parameter      :: epsi=0.00001
       real(kind=cp)                 :: ph
       real(kind=cp),dimension(3)    :: rsk,isk,car,side
       real(kind=cp),dimension(3,12) :: br,bi
       real(kind=cp),dimension(3,3)  :: cart_to_cryst
       real(kind=cp),dimension(12)   :: coef
       character(len=132)            :: lowline,line
       character(len=30)             :: magmod, shubk
       character(len=2)              :: lattice, chardom
       character(len=4)              :: symbcar
       character(len=30)             :: msyr
       logical                       :: msym_begin, kvect_begin, skp_begin, shub_given, irreps_given, &
                                        irreps_begin, bfcoef_begin, magdom_begin, done, spg_given
       type(Magnetic_Group_Type)     :: SG
       type(Space_Group_Type)        :: SpG

       call init_err_MagSym()

       if(n_ini == 0) n_ini=1
       if(n_end == 0) n_end= file_cfl%nlines

       no_iline=0
       no_eline=0

       if(present(Cell)) then
         side(:)=Cell%cell
         cart_to_cryst=Cell%Orth_Cr_cel
       end if

       do i=n_ini,n_end
          ! Read comment
          if (index(file_cfl%line(i)(1:1),"!")/=0 .or. index(file_cfl%line(i)(1:1),"#")/=0) cycle
          lowline=adjustl(l_case(file_cfl%line(i)))

          if (lowline(1:13) == "mag_structure") then
             no_iline=i
          end if
          if (lowline(1:7) =="end_mag" ) then
             no_eline=i
             exit
          end if
       end do

       n_ini=no_iline
       n_end=no_eline

       if (n_ini == 0 .or. n_end == 0) then
          err_magsym=.true.
          ERR_MagSym_Mess=" No magnetic phase found in file!"
          return
       end if
       call Init_MagSymm_k_Type(MGp)

       !Determine the number of symmetry operators existing the magnetic part of the file
       !This is for allocating the dimension of allocatable arrays in MagSymm_k_Type object
       !We will allocate the double for taking into account the possible centring of the magnetic structure
       n=0
       done=.false.
       do i=n_ini,n_end
          lowline=l_case(adjustl(file_cfl%line(i)))
          if (index(lowline(1:4),"symm") == 0 ) cycle
          n=n+1

          !determine now the number of msym cards per symm card
          if(.not. done) then
            m=0
            do j=i+1,i+8
               lowline=l_case(adjustl(file_cfl%line(j)))
               if (index(lowline(1:4),"msym") /= 0 ) then
                 m=m+1
                 cycle
               end if
               done=.true.
               exit
            end do
          end if

       end do
       n=2*n !if it is centred we will need this space
       if(n > 0) then
          !Allocate the allocatable components of MagSymm_k_Type
          if(allocated(MGp%Symop))      deallocate(MGp%Symop)
          if(allocated(MGp%SymopSymb))  deallocate(MGp%SymopSymb)
          if(allocated(MGp%MSymop))     deallocate(MGp%MSymop)
          if(allocated(MGp%MSymopSymb)) deallocate(MGp%MSymopSymb)
          allocate(MGp%Symop(n))
          allocate(MGp%SymopSymb(n))
          if(m > 0) then
             allocate(MGp%MSymop(n,m))
             allocate(MGp%MSymopSymb(n,m))
          end if
       end if


       num_matom=0
       do i=n_ini,n_end
          lowline=l_case(adjustl(file_cfl%line(i)))
          if (index(lowline(1:5),"matom") ==0 ) cycle
          num_matom=num_matom+1
       end do

       Call Allocate_mAtom_list(num_matom,Am)  !Am contains Am%natoms = num_matom
       num_matom=0

       num_k=0
       num_dom=0
       num_defdom=0
       num_xsym=0
       kvect_begin=.true.
       magdom_begin=.true.
       i=n_ini
       shub_given  =.false.
       irreps_given=.false.
       irreps_begin=.false.
       msym_begin  =.false.
       skp_begin   =.false.
       bfcoef_begin=.false.
       spg_given   =.false.
       if (present(mag_dom)) then  !Initialise Mag_dom
          Mag_dom%nd=1
          Mag_dom%Chir=.false.
          Mag_dom%Twin=.false.
          Mag_dom%trans=.false.
          Mag_dom%DMat=0
          do j=1,3
           Mag_dom%DMat(j,j,1)=1
          end do
          Mag_dom%Dt=0.0
          Mag_dom%pop=0.0
          Mag_dom%pop(1,1)=1.0 !one domain is always present
          Mag_dom%Lab=" "
       end if

       do
          i=i+1
          if(i >= n_end) exit

          ! Read comment
          if( len_trim(file_cfl%line(i)) == 0) cycle
          lowline=adjustl(l_case(file_cfl%line(i)))
          if (lowline(1:1) == "!" .or. lowline(1:1)=="#") cycle

          ! Detect keywords

          ! Read magnetic model
          ! write(unit=*,fmt="(i6,a)") i,"  -> "//trim(lowline)
          if (lowline(1:6) == "magmod") then
             read(unit=lowline(8:),fmt=*,iostat=ier) magmod
             if (ier /= 0) then
                err_magsym=.true.
                ERR_MagSym_Mess=" Error reading magnetic model name in magnetic phase"
                return
             end if
             MGp%MagModel= adjustl(magmod)
             cycle
          end if

          ! Read magnetic field for paramagnetic-induced magnetic moments
          ! The first item is the strength of the magnetic field in Tesla and the three other
          ! items correspond to the vector (in crystallographic space) of the direction of applied field.
          if (lowline(1:9) == "mag_field") then
             read(unit=lowline(10:),fmt=*,iostat=ier) Am%MagField, Am%dir_MField
             if (ier /= 0) then
                err_magsym=.true.
                ERR_MagSym_Mess=" Error reading magnetic field in magnetic phase"
                return
             end if
             if( Am%MagField > 0.0001) Am%suscept=.true.
             cycle
          end if

          ! Read lattice
          if (lowline(1:7) == "lattice") then
             read(unit=lowline(9:),fmt=*,iostat=ier) lattice
             if (ier /= 0) then
                err_magsym=.true.
                ERR_MagSym_Mess=" Error reading lattice type in magnetic phase"
                return
             end if
             lattice=adjustl(lattice)
             if (lattice(1:1)=="-") then
                MGp%centred = 2
                MGp%latt=u_case(lattice(2:2))
             else
                MGp%centred = 1
                MGp%Latt= u_case(lattice(1:1))
             end if
             cycle
          end if

          ! Read type of Fourier coefficients
          if (lowline(1:9) == "spherical") then
             if(.not. present(Cell)) then
               err_magsym=.true.
               ERR_MagSym_Mess=" Cell argument is needed when Spherical components are used for Fourier Coefficients!"
             end if
             MGp%Sk_type = "Spherical_Frame"
             cycle
          end if

          ! Read magnetic centrig
          if (lowline(1:7) == "magcent") then
             MGp%mcentred = 2
             cycle
          end if

          ! Read propagation vectors
          if (lowline(1:5) == "kvect" .and. kvect_begin) then
             num_k=num_k+1
             read(unit=lowline(6:),fmt=*,iostat=ier) MGp%kvec(:,num_k)
             if (ier /= 0) then
                err_magsym=.true.
                ERR_MagSym_Mess=" Error reading propagation vectors"
                return
             end if
             do !repeat reading until continuous KVECT lines are exhausted
                i=i+1
                lowline=adjustl(l_case(file_cfl%line(i)))
                ! write(unit=*,fmt="(i6,a)") i,"  -> "//trim(lowline)
                if (lowline(1:1) == "!" .or. lowline(1:1) == "#") cycle
                if (lowline(1:5) == "kvect") then
                   num_k=num_k+1
                   read(unit=lowline(6:),fmt=*,iostat=ier) MGp%kvec(:,num_k)
                   if (ier /= 0) then
                      err_magsym=.true.
                      ERR_MagSym_Mess=" Error reading propagation vectors"
                      return
                   end if
                else
                   i=i-1
                   kvect_begin=.false.
                   exit
                end if
             end do
             cycle
          end if

          ! Read magnetic S-domains
          if (present(mag_dom)) then
             if (lowline(1:6) == "magdom" .and. magdom_begin) then
                num_dom=num_dom+1
                num_defdom=num_defdom+1
                if(index(lowline,"twin") /= 0) Mag_Dom%twin=.true.
                ip=index(lowline,":")
                if(index(lowline,"magdomt") == 0) then
                  msyr=lowline(8:ip-1)
                  call read_msymm(msyr,Mag_Dom%Dmat(:,:,num_dom),ph)
                  Mag_Dom%Dt(:,num_dom)=0.0
                  Mag_Dom%trans=.false.
                else
                  msyr=lowline(9:ip-1)
                  Call Get_Separator_Pos(msyr,",",pos,ncar)
                  if(ncar == 3) then
                    read(unit=msyr(pos(3)+1:),fmt=*,iostat=ier) ph
                    if(ier /= 0) ph=0.0
                    msyr=msyr(1:pos(3)-1)
                  else
                    ph=0.0
                  end if
                  call read_xsym(msyr,1,Mag_Dom%Dmat(:,:,num_dom),Mag_Dom%Dt(:,num_dom))
                  Mag_Dom%Dt(:,num_dom)=0.0
                  Mag_Dom%trans=.true.
                end if
                if (ph > 0.001) then
                  Mag_Dom%chir=.true.
                else
                  Mag_Dom%chir=.false.
                end if
                 if (Mag_Dom%chir) then
                   read(unit=lowline(ip+1:),fmt=*, iostat=ier) Mag_Dom%Pop(1:2,num_dom)
                   write(chardom,"(i2.2)") num_defdom
                   Mag_Dom%Lab(1,num_dom)="magdom"//chardom
                   num_defdom=num_defdom+1
                   write(chardom,"(i2.2)") num_defdom
                   Mag_Dom%Lab(2,num_dom)="magdom"//chardom
                else
                   read(unit=lowline(ip+1:),fmt=*, iostat=ier) Mag_Dom%Pop(1,num_dom)  !, Mag_Dom%MPop(1,num_dom)
                   write(chardom,"(i2.2)") num_defdom
                   Mag_Dom%Lab(1,num_dom)="magdom"//chardom
                end if
                if (ier /= 0) then
                   err_magsym=.true.
                   ERR_MagSym_Mess=" Error reading magnetic S-domains"
                   return
                end if
                Mag_Dom%nd = num_dom

                do  !repeat reading until continuous MAGDOM lines are exhausted
                   i=i+1
                   lowline=adjustl(l_case(file_cfl%line(i)))
                   ! write(unit=*,fmt="(i6,a)") i,"  -> "//trim(lowline)
                   if (lowline(1:1) == "!" .or. lowline(1:1) == "#") cycle
                   if (lowline(1:6) == "magdom") then
                      if(index(lowline,"twin") /= 0) Mag_Dom%twin=.true.
                      num_dom=num_dom+1
                      num_defdom=num_defdom+1
                      ip=index(lowline,":")
                      if(index(lowline,"magdomt") == 0) then
                        msyr=lowline(8:ip-1)
                        call read_msymm(msyr,Mag_Dom%Dmat(:,:,num_dom),ph)
                        Mag_Dom%Dt(:,num_dom)=0.0
                        Mag_Dom%trans=.false.
                      else
                        msyr=lowline(9:ip-1)
                        Call Get_Separator_Pos(msyr,",",pos,ncar)
                        if(ncar == 3) then
                          read(unit=msyr(pos(3)+1:),fmt=*,iostat=ier) ph
                          if(ier /= 0) ph=0.0
                          msyr=msyr(1:pos(3)-1)
                        else
                          ph=0.0
                        end if
                        call read_xsym(msyr,1,Mag_Dom%Dmat(:,:,num_dom),Mag_Dom%Dt(:,num_dom))
                        Mag_Dom%Dt(:,num_dom)=0.0
                        Mag_Dom%trans=.true.
                      end if
                      if (ph > 0.001) then
                        Mag_Dom%chir=.true.
                      else
                         Mag_Dom%chir=.false.
                      end if
                      if (Mag_Dom%chir) then
                         read(unit=lowline(ip+1:),fmt=*, iostat=ier) Mag_Dom%Pop(1:2,num_dom) !, Mag_Dom%MPop(1:2,num_dom)
                         write(chardom,"(i2.2)") num_defdom
                         Mag_Dom%Lab(1,num_dom)="magdom"//chardom
                         num_defdom=num_defdom+1
                         write(chardom,"(i2.2)") num_defdom
                         Mag_Dom%Lab(2,num_dom)="magdom"//chardom
                      else
                         read(unit=lowline(ip+1:),fmt=*, iostat=ier) Mag_Dom%Pop(1,num_dom) !, Mag_Dom%MPop(1,num_dom)
                         write(chardom,"(i2.2)") num_defdom
                         Mag_Dom%Lab(1,num_dom)="magdom"//chardom
                      end if
                      if (ier /= 0) then
                         err_magsym=.true.
                         ERR_MagSym_Mess=" Error reading magnetic S-domains"
                         return
                      end if
                      Mag_Dom%nd = num_dom
                   else
                      i=i-1
                      magdom_begin=.false.
                      exit
                   end if
                end do
                cycle
             end if
          end if

          ! Read number of irreducible representations and number of basis functions for each
          if (lowline(1:6) == "irreps") then
             read(unit=lowline(7:),fmt=*,iostat=ier) MGp%nirreps
             if (ier /= 0) then
                err_magsym=.true.
                ERR_MagSym_Mess=" Error reading number of irreducible representations"
                return
             end if
             read(unit=lowline(7:),fmt=*,iostat=ier) n, (MGp%nbas(j),j=1,MGp%nirreps)
             if (ier /= 0) then
                err_magsym=.true.
                ERR_MagSym_Mess=" Error reading number of basis functions of irreducible representations"
                return
             end if
             irreps_given=.true.
             cycle
          end if

          ! Read the indicator real(0)/imaginary(1) of coefficients for basis functions of
          ! irreducible representations
          if (lowline(1:5) == "icomp" .and. irreps_given) then
             num_irrep=1
             n=MGp%nbas(num_irrep)
             read(unit=lowline(6:),fmt=*,iostat=ier) MGp%icomp(1:abs(n),num_irrep)
             if (ier /= 0) then
                err_magsym=.true.
                ERR_MagSym_Mess=" Error reading real/imaginary indicators of BF coeff. of irreducible representations"
                return
             end if
             do  !repeat reading until continuous icoebf lines are exhausted
                i=i+1
                lowline=adjustl(l_case(file_cfl%line(i)))
                ! write(unit=*,fmt="(i6,a)") i,"  -> "//trim(lowline)
                if (lowline(1:1) == "!" .or. lowline(1:1) == "#") cycle
                if (lowline(1:5) == "icomp") then
                   num_irrep=num_irrep+1
                   n=MGp%nbas(num_irrep)
                   read(unit=lowline(6:),fmt=*,iostat=ier) MGp%icomp(1:abs(n),num_irrep)
                   if (ier /= 0) then
                      err_magsym=.true.
                      ERR_MagSym_Mess=" Error reading real/imaginary indicators of BF coeff. of irreducible representations"
                      return
                   end if
                else
                   i=i-1
                   irreps_given=.false.
                   exit
                end if
             end do
             cycle
          end if

          ! Read Shubnikov group
          if (lowline(1:9) == "shubnikov") then
             shubk=adjustl(file_cfl%line(i)(10:))
             Call Set_Shubnikov_Group(shubk,SG,MGp)
             if (err_magsym) return
             shub_given=.true.
          end if

          ! Read SYMM operators
          if (lowline(1:4) == "symm" .and. .not. shub_given) then
             num_xsym=num_xsym+1
             num_msym=0
             num_irrep=0
             read(unit=lowline(5:),fmt="(a)") MGp%SymopSymb(num_xsym)
             msym_begin=.true.
             irreps_begin=.true.
          end if

          ! Read MSYM operators
          if (lowline(1:4) == "msym" .and. msym_begin .and. .not. shub_given) then
             num_msym=num_msym+1
             read(unit=lowline(5:),fmt="(a)") MGp%MSymopSymb(num_xsym,num_msym)
             do  !repeat reading until continuous MSYM lines are exhausted
                i=i+1
                lowline=adjustl(l_case(file_cfl%line(i)))
                ! write(unit=*,fmt="(i6,a)") i,"  -> "//trim(lowline)
                if (lowline(1:1) == "!" .or. lowline(1:1) == "#") cycle
                if (lowline(1:4) == "msym") then
                   num_msym=num_msym+1
                   read(unit=lowline(5:),fmt="(a)") MGp%MSymopSymb(num_xsym,num_msym)
                else
                   i=i-1
                   msym_begin=.false.
                   exit
                end if
             end do
             cycle
          end if

          ! Read basis functions of irreducible representations
          if (lowline(1:4) == "basr" .and. irreps_begin .and. .not. shub_given) then
             num_irrep=num_irrep+1
             n=MGp%nbas(num_irrep)
             br=0.0; bi=0.0
             read(unit=lowline(5:),fmt=*,iostat=ier) (br(:,j),j=1,abs(n))
             if (ier /= 0) then
                err_magsym=.true.
                write(unit=ERR_MagSym_Mess,fmt="(2(a,i3))")" Error reading basis fuctions (BASR) of irrep ",num_irrep,&
                                                           " for symmetry operator # ",num_xsym
                return
             end if
             if (n < 0) then  !Read the imaginary part of the basis functions
                i=i+1
                lowline=adjustl(l_case(file_cfl%line(i)))
                !write(unit=*,fmt="(i6,a)") i,"  -> "//trim(lowline)
                if (lowline(1:4) == "basi") then
                   read(unit=lowline(5:),fmt=*,iostat=ier) (bi(:,j),j=1,abs(n))
                   if (ier /= 0) then
                      err_magsym=.true.
                      write(unit=ERR_MagSym_Mess,fmt="(2(a,i3))")" Error reading basis fuctions (BASI) of irrep ",num_irrep,&
                                                                 " for symmetry operator # ",num_xsym
                      return
                   end if
                else
                   err_magsym=.true.
                   write(unit=ERR_MagSym_Mess,fmt="(2(a,i3))")" Lacking BASI keyword of irrep ",num_irrep,&
                                                               " for symmetry operator # ",num_xsym
                   return
                end if
             end if
             do j=1,abs(n)
                MGp%basf(:,j,num_xsym,num_irrep)=cmplx( br(:,j),bi(:,j) )
             end do

             do  !repeat reading until continuous BASR or BASI lines are exhausted
                i=i+1
                lowline=adjustl(l_case(file_cfl%line(i)))
                !write(unit=*,fmt="(i6,a)") i,"  -> "//trim(lowline)
                if (lowline(1:1) == "!" .or. lowline(1:1) == "#") cycle
                if (lowline(1:4) == "basr") then
                   num_irrep=num_irrep+1
                   n=MGp%nbas(num_irrep)
                   br=0.0; bi=0.0
                   read(unit=lowline(5:),fmt=*,iostat=ier) (br(:,j),j=1,abs(n))
                   if (ier /= 0) then
                      err_magsym=.true.
                      write(unit=ERR_MagSym_Mess,fmt="(2(a,i3))")" Error reading basis fuctions (BASR) of irrep ",num_irrep,&
                                                                 " for symmetry operator # ",num_xsym
                      return
                   end if
                   if (n < 0) then  !Read the imaginary part of the basis functions
                      i=i+1
                      lowline=adjustl(l_case(file_cfl%line(i)))
                      !write(unit=*,fmt="(i6,a)") i,"  -> "//trim(lowline)
                      if (lowline(1:4) == "basi") then
                         read(unit=lowline(5:),fmt=*,iostat=ier) (bi(:,j),j=1,abs(n))
                         if (ier /= 0) then
                            err_magsym=.true.
                            write(unit=ERR_MagSym_Mess,fmt="(2(a,i3))")" Error reading basis fuctions (BASI) of irrep ",num_irrep,&
                                                                       " for symmetry operator # ",num_xsym
                            return
                         end if
                      else
                         err_magsym=.true.
                         write(unit=ERR_MagSym_Mess,fmt="(2(a,i3))")" Lacking BASI keyword of irrep ",num_irrep,&
                                                                    " for symmetry operator # ",num_xsym
                         return
                      end if
                   end if
                   do j=1,abs(n)
                      MGp%basf(:,j,num_xsym,num_irrep)=cmplx( br(:,j),bi(:,j) )
                   end do
                else
                   i=i-1
                   irreps_begin=.false.
                   exit
                end if
             end do
             cycle
          end if

          ! Read magnetic atoms:  label, magnetic form factor label,x,y,z,Biso,occ
          if (lowline(1:5) == "matom") then
             num_matom=num_matom+1
             num_skp=0
             line=adjustl(file_cfl%line(i))
             read(unit=line(6:),fmt=*,iostat=ier) Am%atom(num_matom)%lab,      & !Label
                                                  Am%atom(num_matom)%SfacSymb, & !Formfactor label
                                                  Am%atom(num_matom)%x,        & !Fract. coord.
                                                  Am%atom(num_matom)%Biso,     & !Is. Temp. Fact.
                                                  Am%atom(num_matom)%occ         !occupation
             if (ier /= 0) then
                err_magsym=.true.
                write(unit=ERR_MagSym_Mess,fmt="(a,i4)")" Error reading magnetic atom #",num_matom
                return
             end if
             skp_begin=.true.
             bfcoef_begin=.true.
             cycle
          end if

          ! Read Fourier coefficients in cryst. axes and phase
          if (lowline(1:3) == "skp" .and. skp_begin) then
             num_skp=num_skp+1
             read(unit=lowline(4:),fmt=*,iostat=ier) ik,im,rsk,isk,ph
             if (ier /= 0) then
                err_magsym=.true.
                write(unit=ERR_MagSym_Mess,fmt="(a,i3)") " Error reading Fourier Coefficient #", num_skp
                return
             end if
               Am%atom(num_matom)%nvk= num_skp
               Am%atom(num_matom)%imat(ik)= im
               Am%atom(num_matom)%mphas(ik)= ph

             if(MGp%Sk_type == "Spherical_Frame") then
               Am%atom(num_matom)%Spher_Skr(:,ik)= rsk(:)
               Am%atom(num_matom)%Spher_Ski(:,ik)= isk(:)
               !Transform from Cartesian coordinates to unitary Crystallographic frame
               call Get_Cart_from_Spher(rsk(1),rsk(3),rsk(2),car,"D")
               Am%atom(num_matom)%Skr(:,ik)=matmul(cart_to_cryst,car)*side(:)
               call Get_Cart_from_Spher(isk(1),isk(3),isk(2),car,"D")
               Am%atom(num_matom)%Ski(:,ik)=matmul(cart_to_cryst,car)*side(:)
             else  !In this case, the Cell argument may be not given
                   !so no transformation is done. This can be done in other parts of the calling program
               Am%atom(num_matom)%Skr(:,ik)= rsk(:)
               Am%atom(num_matom)%Ski(:,ik)= isk(:)
             end if

             do  !repeat reading until continuous SPK lines are exhausted
                i=i+1
                lowline=adjustl(l_case(file_cfl%line(i)))
                !write(unit=*,fmt="(i6,a)") i,"  -> "//trim(lowline)
                if (lowline(1:1) == "!" .or. lowline(1:1) == "#") cycle
                if (lowline(1:3) == "skp") then
                   num_skp=num_skp+1
                   if (num_skp > 12) then
                      err_magsym=.true.
                      ERR_MagSym_Mess= " Too many Fourier Coefficients, the maximum allowed is 12! "
                      return
                   end if
                   read(unit=lowline(4:),fmt=*,iostat=ier) ik,im,rsk,isk,ph
                   if (ier /= 0) then
                      err_magsym=.true.
                      write(unit=ERR_MagSym_Mess,fmt="(a,i3)") " Error reading Fourier Coefficient #", num_skp
                      return
                   end if
                   Am%atom(num_matom)%nvk= num_skp
                   Am%atom(num_matom)%imat(ik)= im
                   Am%atom(num_matom)%Skr(:,ik)= rsk(:)
                   Am%atom(num_matom)%Ski(:,ik)= isk(:)
                   Am%atom(num_matom)%mphas(ik)= ph
                else
                   i=i-1
                   skp_begin=.false.
                   Am%atom(num_matom)%nvk= num_skp
                   exit
                end if
             end do
          end if

          ! Read Local Susceptibility coefficients in cryst. axes
          if (lowline(1:3) == "chi") then
             read(unit=lowline(4:),fmt=*,iostat=ier) coef(1:6)
             if (ier /= 0) then
                err_magsym=.true.
                write(unit=ERR_MagSym_Mess,fmt="(a,i3)") " Error reading Local Susceptibility Coefficient for atom #", num_matom
                return
             end if
               Am%atom(num_matom)%chi= coef(1:6)
               if(abs(coef(1)-coef(2)) < epsi .and. abs(coef(2)-coef(3)) < epsi .and. sum(abs(coef(4:6))) < epsi ) then
                 Am%atom(num_matom)%chitype="isotr"
               else
                 Am%atom(num_matom)%chitype="aniso"
               end if
          end if

          if (lowline(1:6) == "bfcoef" .and. bfcoef_begin) then
             num_skp=num_skp+1
             read(unit=lowline(7:),fmt=*,iostat=ier) ik,im
             n=abs(MGp%nbas(im))
             read(unit=lowline(7:),fmt=*,iostat=ier) ik,im,coef(1:n),ph
             if (ier /= 0) then
                err_magsym=.true.
                write(unit=ERR_MagSym_Mess,fmt="(a,i3)") " Error reading Coefficient of Basis Functions #", num_skp
                return
             end if
             Am%atom(num_matom)%nvk= num_skp
             Am%atom(num_matom)%imat(ik)= im
             Am%atom(num_matom)%cbas(1:n,ik)= coef(1:n)
             Am%atom(num_matom)%mphas(ik)= ph

             do  !repeat reading until continuous bfcoef lines are exhausted
                i=i+1
                lowline=adjustl(l_case(file_cfl%line(i)))
                if (lowline(1:1) == "!" .or. lowline(1:1) == "#") cycle
                write(unit=*,fmt="(i6,a)") i,"  -> "//trim(lowline)
                if (lowline(1:6) == "bfcoef" ) then
                   num_skp=num_skp+1
                   if (num_skp > 12) then
                      err_magsym=.true.
                      ERR_MagSym_Mess= " Too many sets of Coefficients, the maximum allowed is 12! "
                      return
                   end if
                   read(unit=lowline(7:),fmt=*,iostat=ier) ik,im
                   n=abs(MGp%nbas(im))
                   read(unit=lowline(7:),fmt=*,iostat=ier) ik,im,coef(1:n),ph
                   if (ier /= 0) then
                      err_magsym=.true.
                      write(unit=ERR_MagSym_Mess,fmt="(a,i3)") " Error reading Coefficient of Basis Functions #", num_skp
                      return
                   end if
                   Am%atom(num_matom)%nvk= num_skp
                   Am%atom(num_matom)%imat(ik)= im
                   Am%atom(num_matom)%cbas(1:n,ik)= coef(1:n)
                   Am%atom(num_matom)%mphas(ik)= ph
                else
                   i=i-1
                   bfcoef_begin=.false.
                   Am%atom(num_matom)%nvk= num_skp
                   exit
                end if
             end do
          end if
       end do

       !Arriving here we have exhausted reading magnetic phase

       !Check if it is an induced paramagnetic magnetic structure due to an applied magnetic field
       !In such a case use the crystal space group to construct the magnetic matrices. If the symbol
       !of the space group is not provided it is supposed that the symmetry operators have been provided
       !together with th SYMM and MSYM matrices
       if(Am%suscept) then
         do i=1,file_cfl%nlines
            lowline=adjustl(l_case(file_cfl%line(i)))
            if (lowline(1:4) == "spgr" .or. lowline(1:3) == "spg" .or. lowline(1:6) == "spaceg") then
               lowline=adjustl(file_cfl%line(i))
               j=index(lowline," ")
               lowline=lowline(j+1:)
               call Set_SpaceGroup(trim(lowline),SpG)
               spg_given   =.true.
               exit
            end if
         end do
         if(spg_given) then
            n=SpG%Numops * SpG%Centred
            MGp%Centred=SpG%Centred
            MGp%MCentred=1  !Same rotation matrices as that of the space group
            MGp%Latt=SpG%SPG_Symb(1:1)
            num_xsym=SpG%Numops
            num_msym=1
            num_k=1
            if(allocated(MGp%Symop))      deallocate(MGp%Symop)
            if(allocated(MGp%SymopSymb))  deallocate(MGp%SymopSymb)
            if(allocated(MGp%MSymop))     deallocate(MGp%MSymop)
            if(allocated(MGp%MSymopSymb)) deallocate(MGp%MSymopSymb)
            allocate(MGp%Symop(n))
            allocate(MGp%SymopSymb(n))
            allocate(MGp%MSymop(n,1))
            allocate(MGp%MSymopSymb(n,1))

            do i=1,num_xsym
              lowline=" "
              MGp%SymopSymb(i)=SpG%SymopSymb(i)
              call Get_SymSymb(Spg%Symop(i)%Rot,(/0.0,0.0,0.0/),lowline)
              do j=1,len_trim(lowline)
                 if(lowline(j:j) == "x") lowline(j:j) = "u"
                 if(lowline(j:j) == "y") lowline(j:j) = "v"
                 if(lowline(j:j) == "z") lowline(j:j) = "w"
              end do
              MGp%MSymopSymb(i,1) = trim(lowline)//", 0.0"
            end do
         else
           !No action to be taken ... the symmetry operators are read in SYMM cards
         end if
       end if

       !Get pointers to the magnetic form factors
       !Stored for each atom in the component ind(1)
       call Set_Magnetic_Form()

       !---- Find Species in Magnetic_Form ----!
       do i=1,Am%natoms
          symbcar=u_case(Am%atom(i)%SfacSymb)
          do j=1,num_mag_form
             if (symbcar /= Magnetic_Form(j)%Symb) cycle
             Am%atom(i)%ind(1)=j
             exit
          end do
       end do

       !Now construct the rest of magnetic symmetry type variable MGp
       MGp%nmsym =num_msym
       MGp%Numops=num_xsym
       MGp%nkv   =num_k

       !Construct the numerical symmetry operators
       do i=1,MGp%Numops
          Call Read_Xsym(MGp%SymopSymb(i),1,MGp%Symop(i)%Rot,MGp%Symop(i)%tr)
          do j=1,MGp%nmsym
             Call Read_Msymm(MGp%MSymopSymb(i,j),MGp%MSymop(i,j)%Rot,MGp%MSymop(i,j)%Phas)
          end do
       end do
       if (err_symm) then
          err_magsym=.true.
          write(unit=ERR_MagSym_Mess,fmt="(a)") " Error reading symmetry: "//trim(err_symm_mess)
          return
       end if

       !Complete the set of symmetry operators with the centre of symmetry
       m=MGp%Numops
       if (MGp%centred == 2) then
          do i=1,MGp%Numops
             m=m+1
             MGp%Symop(m)%Rot(:,:) = -MGp%Symop(i)%Rot(:,:)
             MGp%Symop(m)%tr(:)    =  modulo_lat(-MGp%Symop(m)%tr(:))
             call Get_SymSymb(MGp%Symop(m)%Rot(:,:), &
                              MGp%Symop(m)%tr(:), MGp%SymopSymb(m))
             if (Mgp%mcentred == 1) then  !Anticentre in the magnetic structure
                do j=1,MGp%nmsym
                   MGp%MSymop(m,j)%Rot(:,:) = -MGp%MSymop(i,j)%Rot(:,:)
                   MGp%MSymop(m,j)%Phas     = -MGp%MSymop(i,j)%Phas
                end do
             else if(Mgp%mcentred == 2) then
                do j=1,MGp%nmsym
                   MGp%MSymop(m,j)%Rot(:,:) =  MGp%MSymop(i,j)%Rot(:,:)
                   MGp%MSymop(m,j)%Phas     =  MGp%MSymop(i,j)%Phas
                end do
             end if
          end do
       end if

       !Get the centring lattice translations of the crystallographic structure
       !and calculate the general multiplicity of the group.
       Mgp%Num_Lat=1
       MGp%Ltr(:,:) = 0.0
       Select Case(MGp%Latt)
          case ("A")
             Mgp%Num_Lat=2
             MGp%Ltr(:,1:2)=Ltr_a(:,1:2)
          case ("B")
             Mgp%Num_Lat=2
             MGp%Ltr(:,1:2)=Ltr_b(:,1:2)
          case ("C")
             Mgp%Num_Lat=2
             MGp%Ltr(:,1:2)=Ltr_c(:,1:2)
          case ("I")
             Mgp%Num_Lat=2
             MGp%Ltr(:,1:2)=Ltr_i(:,1:2)
          case ("R")
             Mgp%Num_Lat=3
             MGp%Ltr(:,1:3)=Ltr_r(:,1:3)
          case ("F")
             Mgp%Num_Lat=4
             MGp%Ltr(:,1:4)=Ltr_f(:,1:4)
       End Select

       select case (MGp%centred)
          case (1)
             MGp%Multip =   MGp%Numops * Mgp%Num_Lat
          case (2)
             MGp%Multip = 2 * MGp%Numops * Mgp%Num_Lat
       end select

       if (present(SGo)) then
          if (shub_given) then
             SGo=SG
          else
             err_magsym=.true.
             ERR_MagSym_Mess=" Shubnikov Group has not been provided "
          end if
       end if

       return
    End Subroutine Readn_Set_Magnetic_Structure_CFL


    !!----
    !!---- Subroutine Readn_Set_Magnetic_Structure_MCIF(file_mcif,mCell,MGp,Am)
    !!----    character(len=*),        intent (in)     :: file_mcif
    !!----    type(Crystal_Cell_type), intent (out)    :: mCell
    !!----    type(MagSymm_k_Type),    intent (out)    :: MGp
    !!----    type(mAtom_List_Type),   intent (out)    :: Am
    !!----
    !!----    Subroutine for reading and construct the MagSymm_k_Type variable MGp.
    !!----    The magnetic atom list and the magnetic cell reading an mCIF file.
    !!----
    !!----  Created: January-2014 (JRC)
    !!
    Subroutine Readn_Set_Magnetic_Structure_MCIF(file_mcif,mCell,MGp,Am)
       character(len=*),               intent (in)  :: file_mcif
       type(Crystal_Cell_type),        intent (out) :: mCell
       type(Magnetic_Space_Group_Type),intent (out) :: MGp
       type(mAtom_List_Type),          intent (out) :: Am

       !---- Local Variables ----!
       integer :: i,num_sym, num_constr, num_kvs,num_matom, num_mom, num_magscat,  &
                  ier, j, m, n, k, ncar,mult,nitems,iv, num_irreps, nitems_irreps
       integer,   dimension(9)             :: lugar
       integer,   dimension(6)             :: irrep_pos
       integer,   dimension(5)             :: pos
       real(kind=cp),dimension(3)          :: cel,ang,cel_std,ang_std
       real(kind=cp),dimension(6)          :: values,std
       real(kind=cp),dimension(3,3)        :: matr
       real(kind=cp),dimension(3,384)      :: orb
       character(len=132)                  :: lowline,keyword,line
       character(len=132),dimension(384)   :: sym_strings
       character(len=132),dimension(384)   :: atm_strings
       character(len=132),dimension(384)   :: mom_strings
       character(len=132),dimension(30)    :: constr_strings, mag_scatt_string
       character(len=132),dimension(30)    :: irreps_strings
       character(len=132),dimension(30)    :: kv_strings
       character(len=20), dimension(15)    :: lab_items
       character(len=40)    :: shubk
       character(len=2)     :: chars
       character(len=10)    :: label
       character(len=4)     :: symbcar
       logical              :: ktag

       !type(Magnetic_Group_Type)  :: SG
       type(file_list_type)       :: mcif

       call init_err_MagSym()

       call File_To_FileList(file_mcif,mcif)
       !Remove all possible tabs and non-ASCII characters in the CIF
       do i=1,mcif%nlines
         do j=1,len_trim(mcif%line(i))
           if(mcif%line(i)(j:j) == char(9)) mcif%line(i)(j:j)=" "
         end do
       end do
       num_constr=0; num_kvs=0; num_matom=0; num_mom=0; num_sym=0; num_magscat=0
       cel=0.0; ang=0.0
       i=0
       call Init_Magnetic_Space_Group_Type(MGp)
       ktag=.false.
       do
          i=i+1
          if(i > mcif%nlines) exit
          if (index(mcif%line(i)(1:1),"!")/=0 .or. index(mcif%line(i)(1:1),"#")/=0 .or. len_trim(mcif%line(i)) == 0) cycle
          line=adjustl(mcif%line(i))
          lowline=l_case(line)
          j=index(lowline," ")
          keyword=lowline(1:j-1)
          !write(*,"(a)") " Keyword: "//trim(keyword)
          Select Case (trim(keyword))

             Case("_magnetic_space_group_standard_setting")
                chars=adjustl(line(j+1:))
                if(chars(2:2) == "y" .or. chars(2:2) == "Y") MGp%standard_setting=.true.

             Case("_parent_space_group.name_h-m")
                shubk=adjustl(line(j+1:))
                m=len_trim(shubk)
                MGp%Parent_spg=shubk(2:m-1)

             Case("_parent_space_group.it_number")
                read(unit=lowline(j:),fmt=*,iostat=ier) m
                if(ier /= 0) then
                  err_magsym=.true.
                  ERR_MagSym_Mess=" Error reading the number of the parent space group"
                  return
                end if
                MGp%Parent_num=m

             Case("_magnetic_space_group_bns_number")
                shubk=adjustl(line(j+1:))
                MGp%BNS_number=shubk

             Case("_magnetic_space_group_bns_name")
                shubk=adjustl(line(j+1:))
                m=len_trim(shubk)
                MGp%BNS_symbol=shubk(2:m-1)

             Case("_magnetic_space_group_og_number")
                shubk=adjustl(line(j+1:))
                MGp%OG_number=shubk

             Case("_magnetic_space_group_og_name")
                shubk=adjustl(line(j+1:))
                m=len_trim(shubk)
                MGp%OG_symbol=shubk(2:m-1)

             Case("_magnetic_space_group.transform_from_parent_pp_abc")
                shubk=adjustl(line(j+1:))
                m=len_trim(shubk)
                MGp%trn_from_parent=shubk(2:m-1)

             Case("_magnetic_space_group.transform_to_standard_pp_abc")
                shubk=adjustl(line(j+1:))
                m=len_trim(shubk)
                MGp%trn_to_standard=shubk(2:m-1)

             Case("_magnetic_cell_length_a")
                call getnum_std(lowline(j:),values,std,iv)
                if(err_string) then
                  err_magsym=.true.
                  ERR_MagSym_Mess=" Error reading the magnetic unit cell parameter 'a' -> "//trim(err_string_mess)
                  return
                end if
                cel(1)=values(1)
                cel_std(1)=std(1)
                MGp%m_cell=.true.

             Case("_magnetic_cell_length_b")
                call getnum_std(lowline(j:),values,std,iv)
                if(err_string) then
                  err_magsym=.true.
                  ERR_MagSym_Mess=" Error reading the magnetic unit cell parameter 'b' -> "//trim(err_string_mess)
                  return
                end if
                cel(2)=values(1)
                cel_std(2)=std(1)

             Case("_magnetic_cell_length_c")
                call getnum_std(lowline(j:),values,std,iv)
                if(err_string) then
                  err_magsym=.true.
                  ERR_MagSym_Mess=" Error reading the magnetic unit cell parameter 'c' -> "//trim(err_string_mess)
                  return
                end if
                cel(3)=values(1)
                cel_std(3)=std(1)

             Case("_magnetic_cell_angle_alpha")
                call getnum_std(lowline(j:),values,std,iv)
                if(err_string) then
                  err_magsym=.true.
                  ERR_MagSym_Mess=" Error reading the magnetic unit cell parameter 'alpha' -> "//trim(err_string_mess)
                  return
                end if
                ang(1)=values(1)
                ang_std(1)=std(1)

             Case("_magnetic_cell_angle_beta")
                call getnum_std(lowline(j:),values,std,iv)
                if(err_string) then
                  err_magsym=.true.
                  ERR_MagSym_Mess=" Error reading the magnetic unit cell parameter 'beta' -> "//trim(err_string_mess)
                  return
                end if
                ang(2)=values(1)
                ang_std(2)=std(1)

             Case("_magnetic_cell_angle_gamma")
                call getnum_std(lowline(j:),values,std,iv)
                if(err_string) then
                  err_magsym=.true.
                  ERR_MagSym_Mess=" Error reading the magnetic unit cell parameter 'gamma' -> "//trim(err_string_mess)
                  return
                end if
                ang(3)=values(1)
                ang_std(3)=std(1)

             Case("loop_")
                 i=i+1
                 line=adjustl(mcif%line(i))
                 lowline=l_case(line)
                 j=index(lowline," ")
                 keyword=lowline(1:j-1)
                 !write(*,"(a)") "         Loop_Keyword: "//trim(keyword)
                 Select Case(trim(keyword))

                   Case("_irrep_id")
                      irrep_pos=0
                      irrep_pos(1)=1
                      j=1
                      do k=1,6
                         i=i+1
                         if(index(mcif%line(i),"_irrep_dimension") /= 0) then
                            j=j+1
                            irrep_pos(2)=j
                            cycle
                         end if
                         if(index(mcif%line(i),"_small_irrep_dimension") /= 0) then
                            j=j+1
                            irrep_pos(3)=j
                            cycle
                         end if
                         if(index(mcif%line(i),"_irrep_direction_type") /= 0) then
                            j=j+1
                            irrep_pos(4)=j
                            cycle
                         end if
                         if(index(mcif%line(i),"_irrep_action") /= 0) then
                            j=j+1
                            irrep_pos(5)=j
                            cycle
                         end if
                         if(index(mcif%line(i),"_irrep_modes_number") /= 0) then
                            j=j+1
                            irrep_pos(6)=j
                            cycle
                         end if
                         exit
                      end do

                      i=i-1
                      nitems_irreps=count(irrep_pos > 0)

                      k=0
                      do
                        i=i+1
                        if(i > mcif%nlines) exit
                        if(len_trim(mcif%line(i)) == 0) exit
                        k=k+1
                        irreps_strings(k)=mcif%line(i)
                      end do
                      num_irreps=k
                      !Treat later the list of irreps

                   Case("_magnetic_propagation_vector_seq_id")
                      do k=1,3
                        i=i+1
                        if(index(mcif%line(i),"_magnetic_propagation_vector") == 0) then
                          err_magsym=.true.
                          ERR_MagSym_Mess=" Error reading the propagation vector loop"
                          return
                        end if
                        if(index(mcif%line(i),"_magnetic_propagation_vector_kxkykz") /= 0) then
                          ktag=.true.  !new format for k-vector klabel '0,1/2,0'
                          exit
                        end if
                      end do
                      k=0
                      do
                        i=i+1
                        if(len_trim(mcif%line(i)) == 0) exit
                        k=k+1
                        kv_strings(k)=mcif%line(i)
                      end do
                      num_kvs=k
                      MGp%n_kv=k
                      if(allocated(Mgp%kv)) deallocate(Mgp%kv)
                      allocate(Mgp%kv(3,k))
                      if(allocated(Mgp%kv_label)) deallocate(Mgp%kv_label)
                      allocate(Mgp%kv_label(k))
                      !Treat later the propagation vectors

                   Case("_atom_type_symbol")
                      do k=1,3
                        i=i+1
                        if(index(mcif%line(i),"_magnetic_atom_type_symbol") == 0) then
                          err_magsym=.true.
                          ERR_MagSym_Mess=" Error reading the _magnetic_atom_type_symbol in loop"
                          return
                        end if
                      end do
                      k=0
                      do
                        i=i+1
                        if(len_trim(mcif%line(i)) == 0) exit
                        k=k+1
                        mag_scatt_string(k)=mcif%line(i)
                      end do
                      num_magscat=k
                      !Treat later the scattering factor

                   Case("_magnetic_atom_site_moment_symmetry_constraints_label")
                      i=i+1
                      if(index(mcif%line(i),"_atom_site_magnetic_moment_symmetry_constraints_mxmymz") == 0) then
                        err_magsym=.true.
                        ERR_MagSym_Mess=" Error reading the magnetic_atom_site_moment_symmetry_constraints loop"
                        return
                      end if
                      k=0
                      do
                        i=i+1
                        if(len_trim(mcif%line(i)) == 0) exit
                        k=k+1
                        constr_strings(k)=mcif%line(i)
                      end do
                      num_constr=k
                      MGp%m_constr=.true.
                      !Treat later the constraints

                   Case("_magnetic_space_group_symop_id")
                      do k=1,3
                        i=i+1
                        if(index(mcif%line(i),"_magnetic_space_group_symop_operation") == 0) then
                          err_magsym=.true.
                          ERR_MagSym_Mess=" Error reading the magnetic_space_group_symop_operation loop"
                          return
                        end if
                      end do
                      k=0
                      do
                        i=i+1
                        if(len_trim(mcif%line(i)) == 0) exit
                        k=k+1
                        sym_strings(k)=mcif%line(i)
                      end do
                      !now allocate the list of symmetry operators
                      num_sym=k
                      MGp%Multip=k
                      if(allocated(Mgp%SymopSymb)) deallocate(Mgp%SymopSymb)
                      allocate(Mgp%SymopSymb(k))
                      if(allocated(Mgp%Symop)) deallocate(Mgp%Symop)
                      allocate(Mgp%Symop(k))
                      if(allocated(Mgp%MSymopSymb)) deallocate(Mgp%MSymopSymb)
                      allocate(Mgp%MSymopSymb(k))
                      if(allocated(Mgp%MSymop)) deallocate(Mgp%MSymop)
                      allocate(Mgp%MSymop(k))

                   Case("_magnetic_atom_site_label")
                      lugar=0
                      lugar(1)=1
                      j=1
                      do k=1,9
                         i=i+1
                         if(index(mcif%line(i),"_atom_site_type_symbol") /= 0) then
                            j=j+1
                            lugar(2)=j
                            cycle
                         end if
                         if(index(mcif%line(i),"_atom_site_fract_x") /= 0) then
                            j=j+1
                            lugar(3)=j
                            cycle
                         end if
                         if(index(mcif%line(i),"_atom_site_fract_y") /= 0) then
                            j=j+1
                            lugar(4)=j
                            cycle
                         end if
                         if(index(mcif%line(i),"_atom_site_fract_z") /= 0) then
                            j=j+1
                            lugar(5)=j
                            cycle
                         end if
                         if (index(mcif%line(i),"_atom_site_U_iso_or_equiv") /= 0) then
                            j=j+1
                            lugar(6)=j
                            cycle
                         end if
                         if (index(mcif%line(i),"_atom_site_occupancy") /= 0) then
                            j=j+1
                            lugar(7)=j
                            cycle
                         end if
                         if (index(mcif%line(i),"_atom_site_symmetry_multiplicity") /= 0) then
                            j=j+1
                            lugar(8)=j
                            cycle
                         end if
                         if (index(mcif%line(i),"_atom_site_Wyckoff_label") /= 0) then
                            j=j+1
                            lugar(9)=j
                            cycle
                         end if
                         exit
                      end do

                      if (any(lugar(3:5) == 0)) then
                          err_magsym=.true.
                          ERR_MagSym_Mess=" Error reading the asymmetric unit of magnetic atoms"
                          return
                      end if

                      i=i-1
                      nitems=count(lugar > 0)

                      k=0
                      do
                        i=i+1
                        if(i > mcif%nlines) exit
                        if(len_trim(mcif%line(i)) == 0) exit
                        k=k+1
                        atm_strings(k)=mcif%line(i)
                      end do
                      num_matom=k
                      !Treat late the list atoms

                   Case("_magnetic_atom_site_moment_label")
                      do k=1,3
                        i=i+1
                        if(index(mcif%line(i),"_magnetic_atom_site_moment_crystalaxis") == 0) then
                          err_magsym=.true.
                          ERR_MagSym_Mess=" Error reading the magnetic_atom_site_moment loop"
                          return
                        end if
                      end do
                      k=0
                      do
                        i=i+1
                        if(i > mcif%nlines) exit
                        if(len_trim(mcif%line(i)) == 0) exit
                        k=k+1
                        mom_strings(k)=mcif%line(i)
                      end do
                      num_mom=k
                      !Treat later the magnetic moment of the atoms
                 End Select
          End Select
       end do

       if(MGp%m_cell) then
         call Set_Crystal_Cell(cel,ang,mCell)
         mCell%cell_std=cel_std
         mCell%ang_std=ang_std
       end if

       !Treat symmetry operators
       if(num_sym == 0) then
          err_magsym=.true.
          ERR_MagSym_Mess=" No symmetry operators have been provided in the MCIF file "//trim(file_mcif)
          return
       else  !Decode the symmetry operators
         do i=1,num_sym
           line=adjustl(sym_strings(i))
           j=index(line," ")
           line=adjustl(line(j+1:))
           j=index(line," ")
           MGp%SymopSymb(i)=line(1:j-1)
           line=adjustl(line(j+1:))
           j=index(line," ")
           MGp%MSymopSymb(i)=line(1:j-1)
           read(unit=line(j:),fmt=*,iostat=ier) n
           if(ier /= 0) then
              err_magsym=.true.
              ERR_MagSym_Mess=" Error reading the time inversion in line: "//trim(sym_strings(i))
              return
           else
              MGp%MSymOp(i)%phas=real(n)
           end if
           call Read_Xsym(MGp%SymopSymb(i),1,MGp%Symop(i)%Rot,MGp%Symop(i)%tr)
           line=MGp%MSymopSymb(i)
           do k=1,len_trim(line)
             if(line(k:k) == "m") line(k:k)=" "
           end do
           line=Pack_String(line)
           call Read_Xsym(line,1,MGp%MSymop(i)%Rot)
         end do
       end if
       ! Symmetry operators treatment done!


       !Treating irreps

       if(num_irreps == 0) then

          MGp%n_irreps=0

        else
          !write(*,"(a,i3)") " Treating irreps: ",num_irreps
          MGp%n_irreps=num_irreps
          if(allocated(MGp%irrep_dim))          deallocate(MGp%irrep_dim)
          if(allocated(MGp%small_irrep_dim))    deallocate(MGp%small_irrep_dim)
          if(allocated(MGp%irrep_id))           deallocate(MGp%irrep_id)
          if(allocated(MGp%irrep_direction))    deallocate(MGp%irrep_direction)
          if(allocated(MGp%irrep_action))       deallocate(MGp%irrep_action)
          if(allocated(MGp%irrep_modes_number)) deallocate(MGp%irrep_modes_number)
          allocate(MGp%irrep_dim(num_irreps),MGp%small_irrep_dim(num_irreps),MGp%irrep_id(num_irreps), &
                   MGp%irrep_direction(num_irreps),MGp%irrep_action(num_irreps),MGp%irrep_modes_number(num_irreps))

          MGp%irrep_dim=0; MGp%small_irrep_dim=0; MGp%irrep_id=" "; MGp%irrep_direction=" "; MGp%irrep_action=" "
          MGp%irrep_modes_number=0

          do i=1,MGp%n_irreps

            call getword(irreps_strings(i),lab_items,iv)

            !if(iv /= nitems_irreps) write(*,"(2(a,i2))") " => Warning irreps_nitems=",nitems_irreps," /= items read=",iv

            MGp%irrep_id(i)=lab_items(irrep_pos(1))
            if(MGp%irrep_id(i) == "?") then
               MGp%n_irreps=0
               exit
            end if

            if (irrep_pos(2) /= 0) then
               read(unit=lab_items(irrep_pos(2)),fmt=*,iostat=ier) MGp%irrep_dim(i)
               if(ier /= 0) MGp%irrep_dim(i)=0
            end if

            if (irrep_pos(3) /= 0) then
               read(unit=lab_items(irrep_pos(3)),fmt=*,iostat=ier) MGp%small_irrep_dim(i)
               if(ier /= 0) MGp%small_irrep_dim(i)=0
            end if

            if (irrep_pos(4) /= 0) then
               MGp%irrep_direction(i)=lab_items(irrep_pos(4))
            end if

            if (irrep_pos(5) /= 0) then
               MGp%irrep_action(i)=lab_items(irrep_pos(5))
            end if

            if (irrep_pos(6) /= 0) then
               read(unit=lab_items(irrep_pos(6)),fmt=*,iostat=ier) MGp%irrep_modes_number(i)
               if(ier /= 0) MGp%irrep_modes_number(i)=0
            end if

          end do
       end if
       ! End treatment of irreps

       ! Treating propagation vectors
       if(num_kvs == 0) then
         MGp%n_kv=0
       else
         !write(*,"(a,i3)") " Treating propagation vectors: ",num_kvs
         do i=1,MGp%n_kv
            line=adjustl(kv_strings(i))
            j=index(line," ")
            MGp%kv_label(i)=line(1:j-1)
            line=adjustl(line(j+1:))
            n=len_trim(line)
            if(ktag) then
              line=line(2:n-1)
              n=n-2
              Call Get_Separator_Pos(line,",",pos,ncar)
            else
              Call Get_Separator_Pos(line," ",pos,ncar)
            end if
            keyword=line(1:pos(1)-1)//"a,"//line(pos(1)+1:pos(2)-1)//"b,"//trim(line(pos(2)+1:))//"c"
            keyword=Pack_String(keyword)
            call Get_Mat_From_Symb(keyword,Matr, (/"a","b","c"/) )
            do k=1,3
               MGp%kv(k,i)=Matr(k,k)
            end do
         end do
       end if
       ! Propagation vectors treatment done!

       !write(*,"(a)") " Cleaning up symmetry operators: "
       Call cleanup_symmetry_operators(MgP)
       !write(*,"(a)") " Cleaning up done! "

       !Treating magnetic atoms
       if(num_matom == 0) then
          Am%natoms = 0
          return
       else
          !write(*,"(a,i4)") " Treating magnetic atoms:  ",num_matom
          Call Allocate_mAtom_list(num_matom,Am)

          do i=1,Am%natoms

            call getword(atm_strings(i),lab_items,iv)
            !if(iv /= nitems) write(*,"(2(a,i2))") " => Warning nitems=",nitems," /= items read=",iv
            Am%atom(i)%lab=lab_items(lugar(1))
            if (lugar(2) /= 0) then
               Am%atom(i)%SfacSymb=lab_items(lugar(2))(1:4)
               if(index("1234567890+-",lab_items(lugar(2))(2:2)) /= 0 ) then
                  Am%atom(i)%chemSymb=U_case(lab_items(lugar(2))(1:1))
               else
                  Am%atom(i)%chemSymb=U_case(lab_items(lugar(2))(1:1))//L_case(lab_items(lugar(2))(2:2))
               end if
            else
               if(index("1234567890+-",lab_items(lugar(1))(2:2)) /= 0 ) then
                  Am%atom(i)%chemSymb=U_case(lab_items(lugar(1))(1:1))
               else
                  Am%atom(i)%chemSymb=U_case(lab_items(lugar(1))(1:1))//L_case(lab_items(lugar(1))(2:2))
               end if
               Am%atom(i)%SfacSymb=Am%atom(i)%chemSymb
            end if
            call getnum_std(lab_items(lugar(3)),values,std,iv)    ! _atom_site_fract_x
            Am%atom(i)%x(1)=values(1)
            Am%atom(i)%x_std(1)=std(1)
            call getnum_std(lab_items(lugar(4)),values,std,iv)    ! _atom_site_fract_y
            Am%atom(i)%x(2)=values(1)
            Am%atom(i)%x_std(2)=std(1)
            call getnum_std(lab_items(lugar(5)),values,std,iv)    ! _atom_site_fract_z
            Am%atom(i)%x(3)=values(1)
            Am%atom(i)%x_std(3)=std(1)

            if (lugar(6) /= 0) then  ! _atom_site_Uiso_or_equiv
               call getnum_std(lab_items(lugar(6)),values,std,iv)
            else
               values=0.0
               std=0.0
            end if
            Am%atom(i)%ueq=values(1)
            Am%atom(i)%Biso=values(1)*78.95683521     !If anisotropic they
            Am%atom(i)%Biso_std=std(1)*78.95683521    !will be put to zero
            Am%atom(i)%utype="u_ij"

            if (lugar(7) /= 0) then ! _atom_site_occupancy
               call getnum_std(lab_items(lugar(7)),values,std,iv)
            else
               values=1.0
               std=0.0
            end if
            Am%atom(i)%occ=values(1)
            Am%atom(i)%occ_std=std(1)

            if(lugar(8) /= 0) then
              read(unit=lab_items(lugar(8)),fmt=*) Mult
              Am%atom(i)%mult=Mult
            else
              Call Get_mOrbit(Am%atom(i)%x,MGp,Mult,orb)
              Am%atom(i)%mult=Mult
            end if
            !Conversion from occupancy to occupation factor
            Am%atom(i)%occ=Am%atom(i)%occ*real(Mult)/real(MGp%Multip)

            if(lugar(9) /= 0) then
               Am%atom(i)%wyck=adjustl(trim(lab_items(lugar(9))))
            end if

          end do
       end if

       !Treating moments of magnetic atoms
       if(num_mom /= 0) then
          !write(*,"(a,i4)") " Treating magnetic moments:  ",num_mom
          do i=1,num_mom
            call getword(mom_strings(i),lab_items,iv)
            !write(*,"(4(a,tr3))")lab_items(1:iv)
            if(iv /= 4) then
               err_magsym=.true.
               write(unit=ERR_MagSym_Mess,fmt="(a,i4)")" Error reading magnetic moment #",i
               ERR_MagSym_Mess=trim(ERR_MagSym_Mess)//" -> 4 items expected in this line: 'Label mx my mz', read: "// &
                                                      trim(mom_strings(i))
               return
            end if
            label=Lab_items(1)
            do j=1,Am%natoms
               if(label == Am%Atom(j)%lab) then
                 do k=1,3
                     call getnum_std(lab_items(1+k),values,std,iv)
                     Am%Atom(j)%SkR(k,1)=values(1)
                     Am%Atom(j)%SkR_std(k,1)=std(1)
                     Am%Atom(j)%SkI(k,1)=0.0
                     Am%Atom(j)%SkI_std(k,1)=0.0
                 end do
               end if
            end do
          end do
       end if

       if(num_constr /= 0) then

         !write(*,"(a,i4)") " Treating constraints:  ",num_constr
         do i=1,num_constr
           line=adjustl(constr_strings(i))
           j=index(line," ")
           label=line(1:j-1)
           keyword=adjustl(line(j+1:))
           Call Get_Separator_Pos(keyword,",",pos,ncar)
           if(ncar == 0) then !There are no ","
             j=index(keyword," ")
             shubk=keyword(1:j-1)//","
             keyword=adjustl(keyword(j+1:))
             j=index(keyword," ")
             shubk=trim(shubk)//keyword(1:j-1)//","
             keyword=trim(shubk)//trim(adjustl(keyword(j+1:)))
           end if
           do j=1,len_trim(keyword)
             if(keyword(j:j) == "m") keyword(j:j) = " "
           end do
           keyword=Pack_String(keyword)
           !write(*,"(a)") "  constr_string: "//trim(line)
           !write(*,"(a)") "        keyword: "//trim(keyword)
           call Get_Mat_From_Symb(keyword,Matr, (/"x","y","z"/) )
           !write(*,"(9f10.3)") Matr
           do j=1,Am%natoms
             if(label == Am%Atom(j)%lab) then
                Am%Atom(j)%SkR=matmul(Matr,Am%Atom(j)%SkR)
                Am%Atom(j)%AtmInfo=constr_strings(i)
                Am%Atom(j)%moment=99.0  !used for indicating that this atom is susceptible to bring a magnetic moment
                exit
             end if
           end do
           !The treatment of the codes will be done in the future
         end do
       end if

       if(num_magscat > 0) then !Reading the valence for determining the magnetic form factor
         do i=1,num_magscat
           call getword(mag_scatt_string(i),lab_items,iv)
           do j=1,Am%natoms
             if(Am%atom(j)%chemSymb == lab_items(1)) then
               Am%atom(j)%SfacSymb=lab_items(2)
               if(lab_items(2) /= ".") then !magnetic atoms
                  Am%Atom(j)%moment=99.0  !used for indicating that this atom is susceptible to bring a magnetic moment
               end if
             end if
           end do
         end do
       end if

       !Get pointers to the magnetic form factors
       !Stored for each atom in the component ind(1)
       call Set_Magnetic_Form()

       !---- Find Species in Magnetic_Form ----!
       do i=1,Am%natoms
          symbcar=get_magnetic_form_factor(Am%atom(i)%SfacSymb)
          do j=1,num_mag_form
             if (symbcar /= Magnetic_Form(j)%Symb) cycle
             Am%atom(i)%ind(1)=j
             exit
          end do
       end do

       return
    End Subroutine Readn_Set_Magnetic_Structure_MCIF




    Subroutine Get_mOrbit(x,Spg,Mult,orb,ptr)
       !---- Arguments ----!
       real(kind=cp), dimension(3),    intent (in) :: x
       type(Magnetic_Space_Group_type),intent (in) :: spg
       integer,                        intent(out) :: mult
       real(kind=cp),dimension(:,:),   intent(out) :: orb
       integer,dimension(:),optional,  intent(out) :: ptr

       !---- Local variables ----!
       integer                                :: j, nt
       real(kind=cp), dimension(3)            :: xx,v
       character(len=1)                       :: laty

       laty="P"
       mult=1
       orb(:,1)=x(:)
       if(present(ptr)) ptr(mult) = 1
       ext: do j=2,Spg%Multip
          xx=ApplySO(Spg%SymOp(j),x)
          xx=modulo_lat(xx)
          do nt=1,mult
             v=orb(:,nt)-xx(:)
             if (Lattice_trans(v,laty)) cycle ext
          end do
          mult=mult+1
          orb(:,mult)=xx(:)
          if(present(ptr)) ptr(mult) = j   !Effective symop
       end do ext
       return
    End Subroutine Get_mOrbit

    !!----
    !!---- Subroutine Set_Magnetic_SpaceGroup(Spacegen, Mode, MSpG, Gen, Ngen)
    !!----    character (len=*),                intent(in)            :: SpaceGen     !  In -> String with Number, symbol, etc depending on Mode
    !!----    character (len=*),                intent(in )           :: Mode         !  In -> NUMBER,BNSN,OGN,BNSS,OGS,GEN
    !!----    Type (Space_Group),               intent(out)           :: MSpG         ! Out -> MSpG object
    !!----    character (len=*), dimension(:),  intent(in ), optional :: gen          !  In -> String Generators
    !!----    Integer,                          intent(in ), optional :: ngen         !  In -> Number of Generators
    !!----
    !!----    Subroutine that construct the object MSpG from the absolute number, BNS/OG number or symbol by.
    !!----    reading a table or by expanding the set of operators, provided in Mode="GEN", anti-translations
    !!----    and translations for centred cells.
    !!----    When Mode="GEN" the optional arguments Gen and Ngen should be given.
    !!----
    !!----
    !!---- Created: February - 2014 (JRC)
    !!
    Subroutine Set_Magnetic_SpaceGroup(Spacegen,Mode,MSpG,Gen,Ngen)
       !----Arguments ----!
       character (len=*),                intent(in )           :: SpaceGen
       character (len=*),                intent(in )           :: Mode
       Type (Magnetic_Space_Group_Type), intent(out)           :: MSpG
       character (len=*), dimension(:),  intent(in ), optional :: gen
       Integer,                          intent(in ), optional :: ngen

       !---- Local variables ----!
       character (len=*),dimension(0:2), parameter  :: Centro = &
                                          (/"Centric (-1 not at origin)", &
                                            "Acentric                  ", &
                                            "Centric (-1 at origin)    "/)
       character (len=20)               :: Spgm
       !character (len=20)               :: ssymb
       !character (len=130)              :: gener
       character (len=8)                :: opcion
       !character (len=2)                :: Latsy
       integer                          :: num, i  !, iv, istart
       !integer,      dimension(1)       :: ivet
       !integer,      dimension(5)       :: poscol
       !integer                          :: Num_g !isymce,isystm,ibravl
       integer                          :: m,l,ngm,nlat !,ier
       integer                          :: ng
       integer,      dimension(3,3,384) :: ss
       real(kind=cp),dimension(3,384)   :: ts !,Ltr
       !integer,      dimension(384)     :: invt
       !real(kind=cp),dimension(3)       :: co
       !real(kind=cp),dimension(1)       :: vet
       real(kind=cp),dimension(3)       :: vec
       !logical                          :: ok

       !---- Inicializing Space Group ----!
       call init_err_magsym()

       !---- Loading Tables ----!
       !call Set_Spgr_Info()
       !call Set_Wyckoff_Info()

       !---- Mode Option ----!
       spgm=adjustl(SpaceGen)
       spgm=u_case(spgm)
       num=-1

       opcion=adjustl(mode)
       call ucase(opcion)

       Select case (trim(opcion))

         case("NUMBER")

         case("BNSS")

         case("BNSN")

         case("OGS")

         case("OGN")

         case("GEN")
             if (present(gen) .and. present(ngen))  then
                !do i=1,ngen
                !   call Check_Generator(gen(i),ok)
                !   !write(*,"(a,i3,a,tr2,L)") " => Generator # ",i,"  "//trim(gen(i)), ok
                !   if(.not. ok) return
                !end do
                !ng=ngen
                !istart=1
                !num_g=ng
                !!call Get_GenSymb_from_Gener(gen,ng,MSpG%gHall)
                !do i=1,ngen
                !   call Read_Xsym(gen(i),istart,ss(:,:,i),ts(:,i))
                !end do
             else
                err_symm=.true.
                ERR_Symm_Mess=" Generators should be provided in GEN calling Set_SpaceGroup"
                return
             end if
             !call Get_SO_from_Gener(Isystm,Isymce,Ibravl,Ng,Ss,Ts,Latsy, &
             !                       Co,Num_g,Spgm)

            ! MSpG%CrystalSys   = sys_cry(isystm)
             !MSpG%SG_setting   = "Non-Conventional (user-given operators)"
             !MSpG%SPG_lat      = Lat_Ch
             !MSpG%SPG_latsy    = latsy
             !MSpG%Num_Lat       = nlat
             !if(allocated(MSpG%Latt_trans)) deallocate(MSpG%Latt_trans)
             !allocate(MSpG%Latt_trans(3,nlat))
             !MSpG%Latt_trans   = Ltr(:,1:nlat)
             !MSpG%Bravais      = Latt(ibravl)
             !MSpG%centre       = Centro(isymce)
             !MSpG%centred      = isymce
             !MSpG%Centre_coord = co
             !MSpG%Numops       = NG
             !MSpG%Num_gen      = max(0,num_g)

         case("FIX")
             if (present(gen) .and. present(ngen))  then
                !ng=ngen
                !istart=1
                !num_g=ng-1
                !do i=1,ngen
                !   call Read_Xsym(gen(i),istart,ss(:,:,i),ts(:,i))
                !end do
             else
                err_symm=.true.
                ERR_Symm_Mess=" Generators should be provided if FIX option is Used"
                return
             end if
             !call Get_SO_from_FIX(isystm,isymce,ibravl,ng,ss,ts,latsy,co,Spgm)
             !MSpG%Spg_Symb     = "unknown "
             !MSpG%Hall         = "unknown "
             !MSpG%Laue         = " "
             !MSpG%Info         = "Fixed symmetry operators (no info)"
             !MSpG%SPG_lat      = Lat_Ch
             !MSpG%Num_Lat       = nlat
             !
             !if(allocated(MSpG%Latt_trans)) deallocate(MSpG%Latt_trans)
             !allocate(MSpG%Latt_trans(3,nlat))
             !
             !MSpG%Latt_trans   = Ltr(:,1:nlat)
             !MSpG%Num_gen      = max(0,num_g)
             !MSpG%Centre_coord = co
             !MSpG%SG_setting   = "Non-Conventional (user-given operators)"
             !MSpG%CrystalSys   = " "
             !MSpG%Bravais      = Latt(ibravl)
             !MSpG%SPG_latsy    = latsy
             !MSpG%centred      = isymce
             !MSpG%centre       = Centro(isymce)
             !MSpG%Numops       = NG

          case default
             err_symm=.true.
             ERR_Symm_Mess=" Problems in MSpG"
             return

       End select

       if (opcion(1:3) /= "FIX") then              !This has been changed of place for allocating
           select case (MSpG%centred)        !the allocatable components properly
              case (0)
                 MSpG%Multip = 2*NG*nlat
              case (1)
                 MSpG%Multip =   NG*nlat
              case (2)
                 MSpG%Multip = 2*NG*nlat
           end select
       else
           MSpG%Multip =   NG
       end if

       !Allocate here the total number of symmetry operators (JRC, Jan2014)

       if(allocated(MSpG%Symop)) deallocate(MSpG%Symop)
       allocate(MSpG%Symop(MSpG%Multip))
       if(allocated(MSpG%SymopSymb)) deallocate(MSpG%SymopSymb)
       allocate(MSpG%SymopSymb(MSpG%Multip))

       do i=1,MSpG%Numops
          MSpG%Symop(i)%Rot(:,:) = ss(:,:,i)
          MSpG%Symop(i)%tr(:)    = ts(:,i)
       end do

       if (opcion(1:3) /= "FIX") then
          m=MSpG%Numops
          if (MSpG%centred == 0) then
             do i=1,MSpG%Numops
                m=m+1
                vec=-ts(:,i)+2.0*MSpG%Centre_coord(:)
                MSpG%Symop(m)%Rot(:,:) = -ss(:,:,i)
                MSpG%Symop(m)%tr(:)    =  modulo_lat(vec)
             end do
          end if
          if (MSpG%centred == 2) then
             do i=1,MSpG%Numops
                m=m+1
                MSpG%Symop(m)%Rot(:,:) = -ss(:,:,i)
                MSpG%Symop(m)%tr(:)    =  modulo_lat(-ts(:,i))
             end do
          end if
          ngm=m
          if (MSpG%Num_Lat > 1) then

             do L=2,MSpG%Num_Lat  ! min(MSpG%Num_Lat,4)  restriction removed Jan2014 (JRC)
                do i=1,ngm
                   m=m+1
                   vec=MSpG%Symop(i)%tr(:) + MSpG%Latt_trans(:,L)
                   MSpG%Symop(m)%Rot(:,:) = MSpG%Symop(i)%Rot(:,:)
                   MSpG%Symop(m)%tr(:)    = modulo_lat(vec)
                end do
             end do
          end if

       end if
       !write(*,"(a)") " => Generating the symetry operators symbols"
       do i=1,MSpG%multip  ! min(MSpG%multip,192) restriction removed Jan2014 (JRC)
          call Get_SymSymb(MSpG%Symop(i)%Rot(:,:), &
                           MSpG%Symop(i)%tr(:)   , &
                           MSpG%SymopSymb(i))
       end do
       !!write(*,"(a)") " => done"
       !
       !if (num <= 0) then
       !   call Get_Laue_PG(MSpG, MSpG%Laue, MSpG%PG)
       !end if
       !!write(*,"(a)") " => Point group done"
       !
       !if(isymce == 0) then
       !   MSpG%centre = trim(MSpG%centre)//"  Gen(-1):"//MSpG%SymopSymb(NG+1)
       !end if
       !
       !if(opcion(1:3)=="GEN") call Get_HallSymb_from_Gener(MSpG)
       return
    End Subroutine Set_Magnetic_SpaceGroup


    !!----
    !!---- Subroutine Set_Shubnikov_Group(shubk,SG,MGp)
    !!----    character (len=*),         intent (in)    :: Shubk
    !!----    type(Magnetic_Group_Type), intent (out)   :: SG
    !!----    type(MagSymm_k_Type),      intent (in out):: MGp
    !!----
    !!----  This subroutined is not completed ... it is still in development
    !!---- Update: April 2008
    !!
    Subroutine Set_Shubnikov_Group(shubk,SG,MGp)
       !---- Arguments ----!
       character (len=*),         intent (in)    :: Shubk
       type(Magnetic_Group_Type), intent (out)   :: SG
       type(MagSymm_k_Type),      intent (in out):: MGp

       !---- Local Variables ----!
       !character (len=132) :: line
       character (len=20)  :: symb
       character (len=4)   :: gn
       character (len=4),dimension(10) :: gen
       logical,          dimension(10) :: found
       integer :: i,j, ng, k,m,n  !,nbl
       integer,              dimension(3)   :: bl
       integer,              dimension(10)  :: syp, numop
       !integer, allocatable, dimension(:,:) :: tab
       !character(len=*),parameter, dimension(26) :: oper = &
       !(/"1 ","-1","m ","2 ","21","3 ","31","32","-3","4 ","41","42","43",&
       !  "-4","6 ","61","62","63","64","65","-6","a ","b ","c ","d ","n "/)
       character(len=40),allocatable, dimension(:) :: ope


       SG%Shubnikov=" "
       SG%Shubnikov=adjustl(Shubk)
       gen = " "

       ! Generate the space group
       j=0
       bl=len_trim(SG%Shubnikov)
       !numop=0
       do i=1,len_trim(SG%Shubnikov)
          if (SG%Shubnikov(i:i) == " ") then
             j=j+1
             bl(j)=i
          end if
       end do

       SG%Shubnikov(bl(1):) = l_case( Shubk(bl(1):))   !Ensures lower case for symmetry elements

       !nbl=j
       j=0
       ng=0
       symb=" "
       syp=0
       do i=1,len_trim(SG%Shubnikov)
          j=j+1
          symb(j:j)=SG%Shubnikov(i:i)
          if (symb(j:j) == "'") then
             ng=ng+1
             k=5
             gn=" "
             do m=j-1,1,-1
                if (symb(m:m) == " ") exit
                if (symb(m:m) == "/") exit
                k=k-1
                gn(k:k)= symb(m:m)
             end do
             gen(ng)=adjustl(gn)
             if (i > bl(1)) syp(ng) = 1
             if (i > bl(2)) syp(ng) = 2
             if (i > bl(3)) syp(ng) = 3
             symb(j:j)=" "
             j= j-1
          end if
       end do
       i=index(symb," ")
       if ( i > 2) then
          symb=symb(1:1)//symb(i:)
       end if
       !write(*,*) " Space group symbol: ", trim(symb)
       !write(*,*) "  Primed Generators: ", (gen(i),i=1,ng), " in positions: ",(syp(i),i=1,ng)

       call Set_SpaceGroup(symb, SG%SpG)

                  !Determine the vector tinv from the information given for the generators
       SG%tinv=1  !by default the magnetic group is identical to the crystallographic group

       m=SG%SpG%Multip
       if (allocated(ope)) deallocate(ope)
       allocate(ope(m))

       found=.false.
       do j=1,ng
          if (gen(j) == "-1") then
             SG%tinv(SG%SpG%Numops+1) = -1
               found(SG%SpG%Numops+1) =.true.
             numop(j)= SG%SpG%Numops+1
          end if
       end do

       !         "Triclinic   ","Monoclinic  ","Orthorhombic","Tetragonal  ",    &
       !  "Trigonal","Hexagonal   ","Cubic       " /)
       n=1
       gn=SG%SpG%CrystalSys(1:4)
       do i=2,m  !over all symmetry operators of Space Group
          if(n == 0) exit  !all operators have been found
          call Symmetry_Symbol(SG%SpG%SymopSymb(i),ope(i))
          n=0
          do j=1,ng
             if (found(j)) cycle
             n=n+1
             if (gen(j)(1:1) == "-") then           !Search for roto-inversion axes
                k=index(ope(i),gen(j)(1:2)//"+")
                if (k /= 0) then    !Operator found
                   if (gn == "Cubi") then
                      k=index(ope(i),"x,x,x")
                      if (k /= 0) then
                         found(j)=.true.
                         SG%tinv(i)=-1
                         numop(j)= i
                         exit
                      end if
                   else
                      found(j)=.true.
                      SG%tinv(i)=-1
                      numop(j)= i
                      exit
                   end if
                end if
             else

                Select Case (gn)
                   case("Mono")
                      k=index(ope(i),gen(j)(1:1))    !Valid for all operators
                      if (k /= 0) then    !Operator found
                         found(j)=.true.
                         SG%tinv(i)=-1
                         numop(j)= i
                         exit
                      end if

                   case("Orth")
                      Select Case (gen(j))
                         Case("2 ","21")           ! Look for 2-fold axes
                            k=index(ope(i),gen(j)(1:1))
                            if (k /= 0) then
                               Select Case (syp(j))
                                  Case(1)
                                     k=index(ope(i),"x")
                                     if (k /= 0) then    !Operator found
                                        found(j)=.true.
                                        SG%tinv(i)=-1
                                        numop(j)= i
                                        exit
                                     end if
                                  Case(2)
                                     k=index(ope(i),"y")
                                     if (k /= 0) then    !Operator found
                                        found(j)=.true.
                                        SG%tinv(i)=-1
                                        numop(j)= i
                                        exit
                                     end if
                                  Case(3)
                                     k=index(ope(i),"z")
                                     if (k /= 0) then    !Operator found
                                        found(j)=.true.
                                        SG%tinv(i)=-1
                                        numop(j)= i
                                        exit
                                     end if
                               End Select
                            end if

                         Case("m ","a ","b ","c ","d ","n ")
                            k=index(ope(i),gen(j)(1:1))
                            if (k /= 0) then
                               Select Case (syp(j))
                                  Case(1)
                                     k=index(ope(i),"x")
                                     if (k == 0) then    !Operator found
                                        found(j)=.true.
                                        SG%tinv(i)=-1
                                        numop(j)= i
                                        exit
                                     end if
                                  Case(2)
                                     k=index(ope(i),"y")
                                     if (k == 0) then    !Operator found
                                        found(j)=.true.
                                        SG%tinv(i)=-1
                                        numop(j)= i
                                        exit
                                     end if
                                  Case(3)
                                     k=index(ope(i),"z")
                                     if (k == 0) then    !Operator found
                                        found(j)=.true.
                                        SG%tinv(i)=-1
                                        numop(j)= i
                                        exit
                                     end if
                               End Select
                            end if
                      End Select

                   case("Tetr")
                      Select Case (gen(j))
                         Case("4 ","41","42","43")           ! Look for 4-fold axes
                            k=index(ope(i),gen(j)(1:1)//"+")
                            if (k /= 0) then
                               found(j)=.true.
                               SG%tinv(i)=-1
                               numop(j)= i
                               exit
                            end if

                         Case("2 ","21")           ! Look for 2-fold axes
                            k=index(ope(i),gen(j)(1:1))
                            if (k /= 0) then
                               Select Case (syp(j))
                                  Case(2)                ! along [100]
                                     k=index(ope(i),"x")
                                     if (k /= 0) then    !Operator found
                                        found(j)=.true.
                                        SG%tinv(i)=-1
                                        numop(j)= i
                                        exit
                                     end if
                                  Case(3)                ! along [1-10]
                                     k=index(ope(i),"-x")
                                     if (k /= 0) then    !Operator found
                                        found(j)=.true.
                                        SG%tinv(i)=-1
                                        numop(j)= i
                                        exit
                                     end if
                               End Select
                            end if

                         Case("m ","a ","b ","c ","d ","n ")
                            k=index(ope(i),gen(j)(1:1))
                            if (k /= 0) then
                               Select Case (syp(j))
                                  Case(1)               ! Plane perp. to z (x,y,..) plane
                                     k=index(ope(i),"z")
                                     if (k == 0) then    !z should not be in the symbol
                                        found(j)=.true.
                                        SG%tinv(i)=-1
                                        numop(j)= i
                                        exit
                                     end if
                                  Case(2)                ! perp. to [100]
                                     k=index(ope(i),"x")
                                     if (k == 0) then    !x should not be in the symbol
                                        found(j)=.true.
                                        SG%tinv(i)=-1
                                        numop(j)= i
                                        exit
                                     end if
                                  Case(3)                ! perp. to [1-100]
                                     k=index(ope(i),"-x")
                                     if (k == 0) then    !-x should not be in the symbol
                                        found(j)=.true.
                                        SG%tinv(i)=-1
                                        numop(j)= i
                                        exit
                                     end if
                               End Select
                            end if
                      End Select

                   case("Rhom")
                      Select Case (gen(j))
                         Case("3 ","31","32")           ! Look for 3-fold axes
                            k=index(ope(i),gen(j)(1:1)//"+")
                            if (k /= 0) then
                               found(j)=.true.
                               SG%tinv(i)=-1
                               numop(j)= i
                               exit
                            end if

                         Case("2 ","21")           ! Look for 2-fold axes
                            k=index(ope(i),gen(j)(1:1))
                            if (k /= 0) then
                               Select Case (syp(j))
                                  Case(2)                ! along [100]
                                     k=index(ope(i),"x,0")
                                     if (k /= 0) then    !Operator found
                                        found(j)=.true.
                                        SG%tinv(i)=-1
                                        numop(j)= i
                                        exit
                                     end if
                                  Case(3)                ! along [1-10]
                                     k=index(ope(i),"-x")
                                     if (k /= 0) then    !Operator found
                                        found(j)=.true.
                                        SG%tinv(i)=-1
                                        numop(j)= i
                                        exit
                                     end if
                               End Select
                            end if

                         Case("m ","c ")
                            k=index(ope(i),gen(j)(1:1))
                            if (k /= 0) then
                               Select Case (syp(j))
                                  Case(1)               ! Plane perp. to z (x,y,..) plane
                                     k=index(ope(i),"z")
                                     if (k == 0) then    !z should not be in the symbol
                                        found(j)=.true.
                                        SG%tinv(i)=-1
                                        numop(j)= i
                                        exit
                                     end if
                                  Case(2)                ! perp. to [100]
                                     k=index(ope(i),"x")
                                     if (k == 0) then    !x should not be in the symbol
                                        found(j)=.true.
                                        SG%tinv(i)=-1
                                        numop(j)= i
                                        exit
                                     end if
                                  Case(3)                ! perp. to [1-100]
                                     k=index(ope(i),"-x")
                                     if (k == 0) then    !-x should not be in the symbol
                                        found(j)=.true.
                                        SG%tinv(i)=-1
                                        numop(j)= i
                                        exit
                                     end if
                               End Select
                            end if
                      End Select

                   case("Hexa")
                      Select Case (gen(j))
                         Case("6 ","61","62","63","64","65")    ! Look for 6-fold axes
                            k=index(ope(i),gen(j)(1:1)//"+")    !only along z
                            if (k /= 0) then
                               found(j)=.true.
                               SG%tinv(i)=-1
                               numop(j)= i
                               exit
                            end if

                         Case("2 ","21")           ! Look for 2-fold axes
                            k=index(ope(i),gen(j)(1:1))
                            if (k /= 0) then
                               Select Case (syp(j))
                                  Case(2)                ! along [100]
                                     k=index(ope(i),"x,0")
                                     if (k /= 0) then    !Operator found
                                        found(j)=.true.
                                        SG%tinv(i)=-1
                                        numop(j)= i
                                        exit
                                     end if
                                  Case(3)                ! along [1-10]
                                     k=index(ope(i),"-x")
                                     if (k /= 0) then    !Operator found
                                        found(j)=.true.
                                        SG%tinv(i)=-1
                                        numop(j)= i
                                        exit
                                     end if
                               End Select
                            end if

                         Case("m ","c ")
                            k=index(ope(i),gen(j)(1:1))
                            if (k /= 0) then
                               Select Case (syp(j))
                                  Case(1)               ! Plane perp. to z (x,y,..) plane
                                     k=index(ope(i),"z")
                                     if (k == 0) then    !z should not be in the symbol
                                        found(j)=.true.
                                        SG%tinv(i)=-1
                                        numop(j)= i
                                        exit
                                     end if
                                  Case(2)                ! perp. to [100]
                                     k=index(ope(i),"x")
                                     if (k == 0) then    !x should not be in the symbol
                                        found(j)=.true.
                                        SG%tinv(i)=-1
                                        numop(j)= i
                                        exit
                                     end if
                                  Case(3)                ! perp. to [1-100]
                                     k=index(ope(i),"-x")
                                     if (k == 0) then    !-x should not be in the symbol
                                        found(j)=.true.
                                        SG%tinv(i)=-1
                                        numop(j)= i
                                        exit
                                     end if
                               End Select
                            end if
                      End Select

                   case("Cubi")
                      Select Case (gen(j))
                         Case("4 ","41","42","43")    ! Look for 4-fold axes
                            k=index(ope(i),gen(j)(1:1)//"+")    !only along z
                            if (k /= 0) then
                               k=index(ope(i),"z")
                               if (k /= 0) then    !Operator found
                                  found(j)=.true.
                                  SG%tinv(i)=-1
                                  numop(j)= i
                                  exit
                               end if
                            end if

                         Case("3 ")    ! Look for 3-fold axes
                            k=index(ope(i),gen(j)(1:1)//"+")    !only along [111]
                            if (k /= 0) then
                               k=index(ope(i),"x,x,x")
                               if (k /= 0 ) then    !Operator found
                                  found(j)=.true.
                                  SG%tinv(i)=-1
                                  numop(j)= i
                                  exit
                               end if
                            end if

                         Case("2 ","21")           ! Look for 2-fold axes
                            k=index(ope(i),gen(j)(1:1))
                            if (k /= 0) then
                               Select Case (syp(j))
                                  Case(1)                ! along [001]
                                     k=index(ope(i),"z")
                                     if (k /= 0) then    !Operator found
                                        found(j)=.true.
                                        SG%tinv(i)=-1
                                        numop(j)= i
                                        exit
                                     end if
                                  Case(3)                ! along [110]
                                     k=index(ope(i),"-x")
                                     if (k /= 0) then    !Operator found
                                        found(j)=.true.
                                        SG%tinv(i)=-1
                                        numop(j)= i
                                        exit
                                     end if
                               End Select
                            end if

                         Case("m ","a ","b ","c ","d ","n ")
                            k=index(ope(i),gen(j)(1:1))
                            if (k /= 0) then
                               Select Case (syp(j))
                                  Case(1)               ! Plane perp. to z (x,y,..) plane
                                     k=index(ope(i),"x,y,0")
                                     if (k /= 0) then
                                        found(j)=.true.
                                        SG%tinv(i)=-1
                                        numop(j)= i
                                        exit
                                     end if
                                  Case(3)                ! perp. to [1-10]
                                     k=index(ope(i),"x,x,z")
                                     if (k /= 0) then
                                        found(j)=.true.
                                        SG%tinv(i)=-1
                                        numop(j)= i
                                        exit
                                     end if
                               End Select
                            end if
                     End Select

                End Select
             end if

          end do  !j=1,ng over all primed symmetry
       end do    !i=2,m over all symmetry operators of Space Group

       !write(*,*) "  Primed Generators: ", (gen(i),i=1,ng), " Correspond to operators: ",(numop(i),i=1,ng)

       !if(allocated(tab)) deallocate(tab)
       !allocate(tab(m,m))
       !call  Set_SpG_Mult_Table(SG%SpG,tab,.true.)

       !Construct MGp from the Shubnikov group
       !Just a dummy construction of MGp for avoiding warning or missbehaviour of compilers (provisional)
       call Init_MagSymm_k_Type(MGp)
       return
    End Subroutine Set_Shubnikov_Group

    !!----
    !!---- Subroutine Write_Magnetic_Structure(Ipr,MGp,Am,Mag_Dom)
    !!----    Integer,                    intent(in)           :: Ipr
    !!----    type(MagSymm_k_Type),       intent(in)           :: MGp
    !!----    type(mAtom_List_Type),      intent(in)           :: Am
    !!----    type(Magnetic_Domain_Type), intent(in), optional :: Mag_Dom
    !!----
    !!----    Subroutine to write out the information about the magnetic symmetry
    !!----    and mangnetic structure in unit Ipr.
    !!----
    !!---- Updated: November 2006, June 2014
    !!
    Subroutine Write_Magnetic_Structure(Ipr,MGp,Am,Mag_Dom,cell)
       !---- Arguments ----!
       Integer,                    intent(in)           :: Ipr
       type(MagSymm_k_Type),       intent(in)           :: MGp
       type(mAtom_List_Type),      intent(in)           :: Am
       type(Magnetic_Domain_Type), intent(in), optional :: Mag_Dom
       type(Crystal_Cell_type),    intent(in), optional :: cell

       !---- Local Variables ----!
       character (len=100), dimension( 4):: texto
       character (len=40)                :: aux
       integer :: i,j,k,l, nlines,n,m,mult,nt
       real(kind=cp)                  :: x
       complex                        :: ci
       real(kind=cp), dimension(3)    :: xp,xo,u_vect,Mom,v
       real(kind=cp), dimension(3,3)  :: chi,chit
       real(kind=cp), dimension(3,48) :: orb
       complex, dimension(3)          :: Sk


       Write(unit=ipr,fmt="(/,a)")  "==================================="
       Write(unit=ipr,fmt="(  a)")  "== Magnetic Symmetry Information =="
       Write(unit=ipr,fmt="(a,/)")  "==================================="

       write(unit=ipr,fmt="(a)")    " => Magnetic  model name: "//trim(MGp%MagModel)
       write(unit=ipr,fmt="(a)")    " => Crystal lattice type: "//MGp%Latt
       if (MGp%nirreps == 0) then
          write(unit=ipr,fmt="(a,i2)") " => Number of Magnetic operators/Crystallographic operator: ",MGp%nmsym
       else
          write(unit=ipr,fmt="(a,i2)") " => Number of Irreducible Representations: ",MGp%nirreps
          do i=1,MGp%nirreps
             write(unit=ipr,fmt="(2(a,i3),a,12i2)") " => Number of basis functions of Irreducible Representation #",i," :", &
                                 MGp%nbas(i),"  Indicators for real(0)/imaginary(1): ", MGp%icomp(1:abs(MGp%nbas(i)),i)
          end do
       end if

       If(Am%Natoms > 0) then
         If (MGp%Centred == 2) then
            write(unit=ipr,fmt="(a)")    " => The crystallographic structure is centric (-1 at origin) "
         else
            write(unit=ipr,fmt="(a)")    " => The crystallographic structure is acentric  "
         End if
         if (MGp%MCentred == 2) then
            write(unit=ipr,fmt="(a)")    " => The magnetic structure is centric "
         else
            if (MGp%Centred == 2) then
               write(unit=ipr,fmt="(a)")    " => The magnetic structure is anti-centric  "
            else
               write(unit=ipr,fmt="(a)")    " => The magnetic structure is acentric  "
            end if
         End if
       End if
       write(unit=ipr,fmt="(a,i2)") " => Number of propagation vectors: ",MGp%nkv
       do i=1,MGp%nkv
          write(unit=ipr,fmt="(a,i2,a,3f8.4,a)") " => Propagation vectors #",i," = (",MGp%kvec(:,i)," )"
       end do
       if (MGp%Num_lat > 1) then
          write(unit=ipr,fmt="(a,i3)")  " => Centring vectors:",MGp%Num_lat-1
          nlines=1
          texto(:) (1:100) = " "
          do i=2,MGp%Num_lat
             call Frac_Trans_2Dig(MGp%Ltr(:,i),aux)
             if (mod(i-1,2) == 0) then
                write(unit=texto(nlines)(51:100),fmt="(a,i2,a,a)") " => Latt(",i-1,"): ",trim(aux)
                nlines=nlines+1
             else
                write(unit=texto(nlines)( 1:50),fmt="(a,i2,a,a)") " => Latt(",i-1,"): ",trim(aux)
             end if
          end do
          do i=1,nlines
             write(unit=ipr,fmt="(a)") texto(i)
          end do
       end if

       If(MGp%Numops > 0) then
         write(unit=ipr,fmt="(/,a,/)")        " => List of all Symmetry Operators and Symmetry Symbols"

         do i=1,MGp%Numops
            texto(1)=" "
            call Symmetry_Symbol(MGp%SymopSymb(i),texto(1))
            write(unit=ipr,fmt="(a,i3,2a,t50,2a)") " => SYMM(",i,"): ",trim(MGp%SymopSymb(i)), &
                                                            "Symbol: ",trim(texto(1))
            if (MGp%nirreps == 0) then
              do j=1,MGp%NMSym
                 write(unit=ipr,fmt="(a,2(i2,a))")      "    MSYMM(",i,",",j,"): "//trim(MGp%MSymopSymb(i,j))
              end do
            else
              do j=1,MGp%nirreps
                write(unit=ipr,fmt="(a,2(i2,a),12(3f9.4,tr2))")"    BASR(",i,",",j,"): ",real(MGp%Basf(:,1:abs(MGp%nbas(j)),i,j))
                if (MGp%nbas(j) < 0) &
                write(unit=ipr,fmt="(a,2(i2,a),12(3f9.4,tr2))")"    BASI(",i,",",j,"): ",AIMAG(MGp%Basf(:,1:abs(MGp%nbas(j)),i,j))
              end do
            end if
         end do
       End if  !MGp%Numops > 0

       If(Am%Natoms > 0) then
         Write(unit=ipr,fmt="(/,a)")  "===================================="
         Write(unit=ipr,fmt="(  a)")  "== Magnetic Structure Information =="
         Write(unit=ipr,fmt="(a,/)")  "===================================="

         Write(unit=ipr,fmt="(a)")    " "
         Write(unit=ipr,fmt="(  a)")  "== Magnetic Asymmetric Unit Data =="
         Write(unit=ipr,fmt="(a,/)")  " "

         if (MGp%nirreps == 0) then

            if(Am%suscept) then
               Write(unit=ipr,fmt="(a,f8.3,a)")  &
               "  The magnetic structure is induced by an applied magnetic field of ",Am%MagField," Tesla"
               Write(unit=ipr,fmt="(a,3f8.3,a)")  &
               "  The direction of the applied magnetic field is: [",Am%dir_MField," ] in crystal space"
               do i=1,Am%Natoms
                  Write(unit=ipr,fmt="(a,a,5f10.5)")  &
                    "   Atom "//Am%Atom(i)%Lab, Am%Atom(i)%SfacSymb, Am%Atom(i)%x,Am%Atom(i)%Biso,Am%Atom(i)%occ
                  Write(unit=ipr,fmt="(a,6f10.5,a)")  &
                        "     Chi-Tensor( Chi11,Chi22,Chi33,Chi12,Chi13,Chi23) =  (", Am%Atom(i)%chi(:),")"
               end do

            else

               Write(unit=ipr,fmt="(a)")  &
               "  The Fourier coefficients are of the form: Sk(j) = 1/2 { Rk(j) + i Ik(j) } exp {-2pi i Mphask(j)}"
               Write(unit=ipr,fmt="(a)")  &
               "  They are written for each atom j as Sk( j)= 1/2 {(Rx Ry Rz) + i ( Ix Iy Iz)} exp {-2pi i Mphask} -> MagMatrix # imat"
               Write(unit=ipr,fmt="(a)")  "  In case of k=2H (H reciprocal lattice vector) Sk(j)= (Rx Ry Rz)"

               do i=1,Am%Natoms
                  Write(unit=ipr,fmt="(a,a,5f10.5)")  &
                    "   Atom "//Am%Atom(i)%Lab, Am%Atom(i)%SfacSymb, Am%Atom(i)%x,Am%Atom(i)%Biso,Am%Atom(i)%occ
                  do j=1,Am%Atom(i)%nvk
                     if (K_Equiv_Minus_K(MGp%kvec(:,j),MGp%latt)) then
                        Write(unit=ipr,fmt="(a,i2,a,3f11.5,a,i4)")  &
                        "     Sk(",j,") =  (", Am%Atom(i)%Skr(:,j),")  -> MagMatrix #", Am%Atom(i)%imat(j)
                     else
                        Write(unit=ipr,fmt="(a,i2,a,2(3f11.5,a),f9.5,a,i4)")  &
                        "     Sk(",j,") = 1/2 {(", Am%Atom(i)%Skr(:,j),") + i (",Am%Atom(i)%Ski(:,j),")}  exp { -2pi i ",&
                        Am%Atom(i)%MPhas(j),"}  -> MagMatrix #", Am%Atom(i)%imat(j)
                     end if
                  end do
               end do
            end if

         else

            Write(unit=ipr,fmt="(a)")  &
            "  The Fourier coefficients are of the form: Sk(j) = 1/2 Sum(i){Ci* Basf(i,imat)} exp {-2pi i Mphask(j)}"
            Write(unit=ipr,fmt="(a)")  &
            "  Where Ci are coefficients given below, Basf are the basis functions given above -> Irrep# imat"

            do i=1,Am%Natoms
               Write(unit=ipr,fmt="(a,a,5f10.5)")  &
                 "   Atom "//Am%Atom(i)%Lab, Am%Atom(i)%SfacSymb, Am%Atom(i)%x,Am%Atom(i)%Biso,Am%Atom(i)%occ
               do j=1,Am%Atom(i)%nvk
                  m=Am%Atom(i)%imat(j)
                  n=abs(MGp%nbas(m))
                  !1234567890123456789012345678
                  aux="(a,i2,a,  f11.5,a,f9.5,a,i4)"
                  write(unit=aux(9:10),fmt="(i2)") n
                  Write(unit=ipr,fmt=aux)  &
                     "  Coef_BasF(",j,") = 1/2 {(", Am%Atom(i)%cbas(1:n,j),")}  exp { -2pi i ",&
                  Am%Atom(i)%MPhas(j),"}  -> Irrep #", m
               end do
            end do
         end if

         ! Complete list of all atoms per primitive cell
         Write(unit=ipr,fmt="(/,a)")  " "
         Write(unit=ipr,fmt="(  a)")  "== List of all atoms and Fourier coefficients in the primitive cell =="
         Write(unit=ipr,fmt="(a,/)")  " "

         ! Construct the Fourier coefficients in case of Irreps
         if (MGp%nirreps /= 0 ) then
            do i=1,Am%natoms
               xo=Am%Atom(i)%x
               mult=0
               orb=0.0
               SOps: do k=1,MGp%NumOps
                  xp=ApplySO(MGp%SymOp(k),xo)
                  do nt=1,mult
                    v=orb(:,nt)-xp(:)
                    if (Lattice_trans(v,MGp%latt)) cycle SOps
                  end do
                  mult=mult+1
                  orb(:,mult)=xp(:)
                  Write(unit=ipr,fmt="(a,i2,a,3f9.5)") " =>  Atom "//Am%Atom(i)%lab//"(",k,") :",xp
                  do j=1,Am%Atom(i)%nvk
                     m=Am%Atom(i)%imat(j)
                     n=abs(MGp%nbas(m))
                     Sk(:) = cmplx(0.0,0.0)
                     do l=1,n !cannot be greater than 12 at present
                        x=real(MGp%icomp(l,m))
                        ci=cmplx(1.0-x,x)
                        Sk(:)=Sk(:)+ Am%atom(i)%cbas(l,m)*ci* MGp%basf(:,l,k,m)
                     end do
                     x=-tpi*Am%atom(i)%mphas(j)
                     Sk=Sk*cmplx(cos(x),sin(x))
                     Write(unit=ipr,fmt="(a,i2,a,2(3f11.5,a),f9.5,a)")  &
                      "     Sk(",j,") = 1/2 {(", real(Sk),") + i (",aimag(Sk),")}"
                  end do
               end do  SOps !Ops
               Write(unit=ipr,fmt="(a)") "  "
            end do  !atoms

         else !MGp%nirreps == 0

            if(Am%suscept .and. present(cell)) then
                u_vect=Am%MagField * Am%dir_MField / Veclength(Cell%Cr_Orth_cel,Am%dir_MField)
                do i=1,Am%natoms
                  xo=Am%Atom(i)%x
                  xo=modulo_lat(xo)
                  chi=reshape((/am%atom(i)%chi(1),am%atom(i)%chi(4), am%atom(i)%chi(5), &
                                am%atom(i)%chi(4),am%atom(i)%chi(2), am%atom(i)%chi(6), &
                                am%atom(i)%chi(6),am%atom(i)%chi(6), am%atom(i)%chi(3) /),(/3,3/))
                  mult=0
                  orb=0.0
                  sym: do k=1,MGp%Numops
                     xp=ApplySO(MGp%SymOp(k),xo)
                     xp=modulo_lat(xp)
                     do nt=1,mult
                       v=orb(:,nt)-xp(:)
                       if (Lattice_trans(v,MGp%latt)) cycle sym
                     end do
                     mult=mult+1
                     orb(:,mult)=xp(:)
                     chit=matmul(MGp%SymOp(k)%Rot,chi)
                     chit=matmul(chit,transpose(MGp%SymOp(k)%Rot))
                     Mom=matmul(Chit,u_vect)

                     Write(unit=ipr,fmt="(a,i2,2(a,3f11.5),a)") " =>  Atom "//Am%Atom(i)%lab//"(",k,") :",xp,"   Induced moment: [",Mom," ]"
                     Write(unit=ipr,fmt="(a)")            "             Local Susceptibility Tensor: "
                     do j=1,3
                        Write(unit=ipr,fmt="(a,3f14.5)")  "                            ",chit(j,:)
                     end do
                  end do sym ! symmetry
                end do ! Atoms

            else !suscept

              do i=1,Am%natoms
                 xo=Am%Atom(i)%x
                 mult=0
                 orb=0.0
                 Ops: do k=1,MGp%NumOps
                    xp=ApplySO(MGp%SymOp(k),xo)
                    do nt=1,mult
                      v=orb(:,nt)-xp(:)
                      if (Lattice_trans(v,MGp%latt)) cycle Ops
                    end do
                    mult=mult+1
                    orb(:,mult)=xp(:)
                    Write(unit=ipr,fmt="(a,i2,a,3f8.5)") " =>  Atom "//Am%Atom(i)%lab//"(",k,") :",xp
                    do j=1,Am%Atom(i)%nvk
                       m=Am%Atom(i)%imat(j)
                       n=abs(MGp%nbas(m))
                       x=-tpi*Am%atom(i)%mphas(j)
                       Sk=cmplx(Am%Atom(i)%Skr(:,j),Am%Atom(i)%Ski(:,j))
                       Sk= ApplyMSO(MGp%MSymOp(k,j),Sk)*cmplx(cos(x),sin(x))
                       Write(unit=ipr,fmt="(a,i2,a,2(3f10.5,a),f9.5,a)")  &
                        "     Sk(",j,") = 1/2 {(", real(Sk),") + i (",aimag(Sk),")}"
                    end do
                 end do Ops
                 Write(unit=ipr,fmt="(a)") "  "
              end do  !atoms
            end if !suscept
         end if

       End If !Am%Natoms > 0

       ! Writing information about domains (like in FullProf)
       if (present(Mag_Dom)) then
          write(unit=ipr,fmt="(a)") " => Magnetic S-Domains are present"
          if(Mag_Dom%chir) write(unit=ipr,fmt="(a)")"    Chirality domains are also present                     Chir-1      Chir-2"
          do i=1,Mag_Dom%nd
             if (Mag_Dom%chir) then
                write(unit=ipr,fmt="(a,i2,1(a,2f12.4))")"      Matrix of Magnetic Domain #:",i, &
                   " -> Populations: ",Mag_Dom%Pop(1:2,i) !,'  Codes:',MagDom(iom)%MPop(1:2,i)
             else
                write(unit=ipr,fmt="(a,i2,1(a,f12.4))")"      Matrix of Magnetic Domain #:",i,  &
                   " -> Population: ",Mag_Dom%Pop(1,i) !,'  Code:',MagDom(iom)%MPop(1,i)
             end if
             do j=1,3
                write(unit=ipr,fmt="(a,3i4)")  "                    ",Mag_Dom%Dmat(j,:,i)
            end do
          end do
       end if

       return
    End Subroutine Write_Magnetic_Structure

    Subroutine Write_MCIF(Ipr,mCell,MSGp,Am,Cell)
       Integer,                         intent(in)           :: Ipr
       type(Magnetic_Space_Group_Type), intent(in)           :: MSGp
       type(Crystal_Cell_Type),         intent(in)           :: mCell
       type(mAtom_List_Type),           intent(in)           :: Am
       type(Crystal_Cell_Type),optional,intent(in)           :: Cell
       !
       Character(len=132)             :: line
       character(len=40),dimension(6) :: text
       character(len=2)               :: invc
       real(kind=cp)                  :: occ,occ_std,uiso,uiso_std
       integer :: i,j

       write(unit=Ipr,fmt="(a)") "#  --------------------------------------"
       write(unit=Ipr,fmt="(a)") "#  Magnetic CIF file generated by CrysFML"
       write(unit=Ipr,fmt="(a)") "#  --------------------------------------"
       write(unit=Ipr,fmt="(a)") "# https://forge.epn-campus.eu/projects/crysfml/repository"
       call Write_Date_Time(dtim=line)
       write(unit=Ipr,fmt="(a)") trim(line)
       write(unit=Ipr,fmt="(a)") " "

       write(unit=Ipr,fmt="(a)") "data_"
       write(unit=Ipr,fmt="(a)") "_citation_journal_abbrev ?"
       write(unit=Ipr,fmt="(a)") "_citation_journal_volume ?"
       write(unit=Ipr,fmt="(a)") "_citation_page_first     ?"
       write(unit=Ipr,fmt="(a)") "_citation_page_last      ?"
       write(unit=Ipr,fmt="(a)") "_citation_article_id     ?"
       write(unit=Ipr,fmt="(a)") "_citation_year           ?"
       write(unit=Ipr,fmt="(a)") "_loop "
       write(unit=Ipr,fmt="(a)") "_citation_author_name"
       write(unit=Ipr,fmt="(a)") "?"
       write(unit=Ipr,fmt="(a)")
       write(unit=Ipr,fmt="(a)") "_atomic_positions_source_database_code_ICSD  ?"
       write(unit=Ipr,fmt="(a)") "_atomic_positions_source_other    .  "
       write(unit=Ipr,fmt="(a)")
       write(unit=Ipr,fmt="(a)") "_Neel_temperature  ?"
       write(unit=Ipr,fmt="(a)") "_magn_diffrn_temperature  ?"
       write(unit=Ipr,fmt="(a)") "_exptl_crystal_magnetic_properties_details"
       write(unit=Ipr,fmt="(a)") ";"
       write(unit=Ipr,fmt="(a)") ";"
       write(unit=Ipr,fmt="(a)") "_active_magnetic_irreps_details"
       write(unit=Ipr,fmt="(a)") ";"
       write(unit=Ipr,fmt="(a)") ";"
       write(unit=Ipr,fmt="(a)") " "
       if(MSGp%standard_setting) then
          write(unit=Ipr,fmt="(a)") "_magnetic_space_group_standard_setting  'yes'"
       else
          write(unit=Ipr,fmt="(a)") "_magnetic_space_group_standard_setting  'no'"
       end if
       write(unit=Ipr,fmt="(a)")    '_parent_space_group.name_H-M  "'//trim(MSGp%Parent_spg)//'"'
       write(unit=Ipr,fmt="(a,i3)") "_parent_space_group.IT_number  ",MSGp%Parent_num
       write(unit=Ipr,fmt="(a)")    "_magnetic_space_group.transform_from_parent_Pp_abc  '"//trim(MSGp%trn_from_parent)//"'"
       write(unit=Ipr,fmt="(a)")    "_magnetic_space_group.transform_to_standard_Pp_abc  '"//trim(MSGp%trn_to_standard)//"'"
       write(unit=Ipr,fmt="(a)")
       if(len_trim(MSGp%BNS_number) /= 0) &
       write(unit=Ipr,fmt="(a)") "_magnetic_space_group_BNS_number  "//trim(MSGp%BNS_number)
       if(len_trim(MSGp%BNS_symbol) /= 0) &
       write(unit=Ipr,fmt="(a)") '_magnetic_space_group_BNS_name  "'//trim(MSGp%BNS_symbol)//'"'
       if(len_trim(MSGp%OG_number) /= 0) &
       write(unit=Ipr,fmt="(a)") '_magnetic_space_group_OG_number '//trim(MSGp%OG_number)
       if(len_trim(MSGp%OG_symbol) /= 0) &
       write(unit=Ipr,fmt="(a)") '_magnetic_space_group_OG_name  "'//trim(MSGp%OG_symbol)//'"'
       write(unit=Ipr,fmt="(a)")

       if(MSGp%n_irreps /= 0) then
          write(unit=Ipr,fmt="(a)") "loop_"
          write(unit=Ipr,fmt="(a)") "_irrep_id"
          write(unit=Ipr,fmt="(a)") "_irrep_dimension"
          if( any(MSGp%small_irrep_dim > 0) ) write(unit=Ipr,fmt="(a)") "_small_irrep_dimension"
          write(unit=Ipr,fmt="(a)") "_irrep_direction_type"
          write(unit=Ipr,fmt="(a)") "_irrep_action"
          if( any(MSGp%irrep_modes_number > 0) ) write(unit=Ipr,fmt="(a)") "_irrep_modes_number"
          do i=1,MSGp%n_irreps
            if(MSGp%small_irrep_dim(i) > 0) then
               write(unit=line,fmt=("(2i4)"))  MSGp%irrep_dim(i), MSGp%small_irrep_dim(i)
            else
               write(unit=line,fmt=("(i4)"))  MSGp%irrep_dim(i)
            end if
            line= trim(MSGp%irrep_id(i))//"  "//trim(line)//"   "// &
                                      trim(MSGp%irrep_direction(i))//"  "//trim(MSGp%irrep_action(i))
            if( MSGp%irrep_modes_number(i) > 0) then
               j=len_trim(line)
              write(unit=line(j+1:),fmt="(i4)") MSGp%irrep_modes_number(i)
            end if
            write(unit=Ipr,fmt="(a)") trim(line)
          end do
          write(unit=Ipr,fmt="(a)")
       else
          write(unit=Ipr,fmt="(a)") "loop_"
          write(unit=Ipr,fmt="(a)") "_irrep_id"
          write(unit=Ipr,fmt="(a)") "_irrep_dimension"
          write(unit=Ipr,fmt="(a)") "_small_irrep_dimension"
          write(unit=Ipr,fmt="(a)") "_irrep_direction_type"
          write(unit=Ipr,fmt="(a)") "_irrep_action"
          write(unit=Ipr,fmt="(a)") "_irrep_modes_number"
          write(unit=Ipr,fmt="(a)") " ?  ?  ?  ?  ?  ?"
          write(unit=Ipr,fmt="(a)")
       end if

       if(MSGp%m_cell) then
          do i=1,3
            call setnum_std(mCell%Cell(i),mCell%cell_std(i),text(i))
            call setnum_std(mCell%ang(i),mCell%ang_std(i),text(i+3))
          end do
          write(unit=Ipr,fmt="(a)") "_magnetic_cell_length_a    "//trim(text(1))
          write(unit=Ipr,fmt="(a)") "_magnetic_cell_length_b    "//trim(text(2))
          write(unit=Ipr,fmt="(a)") "_magnetic_cell_length_c    "//trim(text(3))
          write(unit=Ipr,fmt="(a)") "_magnetic_cell_angle_alpha "//trim(text(4))
          write(unit=Ipr,fmt="(a)") "_magnetic_cell_angle_beta  "//trim(text(5))
          write(unit=Ipr,fmt="(a)") "_magnetic_cell_angle_gamma "//trim(text(6))
          write(unit=Ipr,fmt="(a)")
       else
          if(present(Cell)) then
             do i=1,3
               call setnum_std(Cell%Cell(i),Cell%cell_std(i),text(i))
               call setnum_std(Cell%ang(i),Cell%ang_std(i),text(i+3))
             end do
             write(unit=Ipr,fmt="(a)") "_cell_length_a    "//trim(text(1))
             write(unit=Ipr,fmt="(a)") "_cell_length_b    "//trim(text(2))
             write(unit=Ipr,fmt="(a)") "_cell_length_c    "//trim(text(3))
             write(unit=Ipr,fmt="(a)") "_cell_angle_alpha "//trim(text(4))
             write(unit=Ipr,fmt="(a)") "_cell_angle_beta  "//trim(text(5))
             write(unit=Ipr,fmt="(a)") "_cell_angle_gamma "//trim(text(6))
             write(unit=Ipr,fmt="(a)")
          end if
       end if
       if(MSGp%n_kv > 0) then
          write(unit=Ipr,fmt="(a)") "loop_"
          write(unit=Ipr,fmt="(a)") "_magnetic_propagation_vector_seq_id"
          write(unit=Ipr,fmt="(a)") "_magnetic_propagation_vector_kxkykz"
          do i=1,MSGp%n_kv
            call Frac_Trans_2Dig(MSGp%kv(:,i),line)
            line=line(2:len_trim(line)-1)
            write(unit=Ipr,fmt="(a)") trim(MSGp%kv_label(i))//"  '"//trim(line)//"'"
          end do
       end if
       if(MSGp%m_constr) then
          write(unit=Ipr,fmt="(a)")
          write(unit=Ipr,fmt="(a)") "loop_"
          write(unit=Ipr,fmt="(a)") "_magnetic_atom_site_moment_symmetry_constraints_label"
          write(unit=Ipr,fmt="(a)") "_atom_site_magnetic_moment_symmetry_constraints_mxmymz"
          do i=1,Am%natoms
            line=Am%Atom(i)%AtmInfo
            if(len_trim(line) < 8) cycle
            write(unit=Ipr,fmt="(a)")trim(line)
          end do
       end if
       write(unit=Ipr,fmt="(a)")
       write(unit=Ipr,fmt="(a)")  "loop_"
       write(unit=Ipr,fmt="(a)")  "_magnetic_space_group_symop_id"
       write(unit=Ipr,fmt="(a)")  "_magnetic_space_group_symop_operation_xyz"
       write(unit=Ipr,fmt="(a)")  "_magnetic_space_group_symop_operation_mxmymz"
       write(unit=Ipr,fmt="(a)")  "_magnetic_space_group_symop_operation_timereversal"
       do i=1,MSGp%Multip
          write(unit=invc,fmt="(i2)") nint(MSgp%MSymop(i)%Phas)
          if(invc(1:1) == " ") invc(1:1)="+"
          write(unit=Ipr,fmt="(i3,a)") i," "//trim(MSgp%SymopSymb(i))//" "//trim(MSgp%MSymopSymb(i))//" "//invc
       end do
       write(unit=Ipr,fmt="(a)")
       write(unit=Ipr,fmt="(a)") "loop_"
       write(unit=Ipr,fmt="(a)") "_magnetic_atom_site_label"
       write(unit=Ipr,fmt="(a)") "_magnetic_atom_site_type_symbol"
       write(unit=Ipr,fmt="(a)") "_magnetic_atom_site_fract_x"
       write(unit=Ipr,fmt="(a)") "_magnetic_atom_site_fract_y"
       write(unit=Ipr,fmt="(a)") "_magnetic_atom_site_fract_z"
       write(unit=Ipr,fmt="(a)") "_magnetic_atom_site_U_iso_or_equiv"
       write(unit=Ipr,fmt="(a)") "_magnetic_atom_site_occupancy"
       write(unit=Ipr,fmt="(a)") "_magnetic_atom_site_symmetry_multiplicity"
       write(unit=Ipr,fmt="(a)") "_magnetic_atom_site_Wyckoff_label"
       line=" "
       do i=1,Am%natoms
          do j=1,3
            call setnum_std(Am%atom(i)%x(j),Am%atom(i)%x_std(j),text(j))
          end do
          occ=real(MSgp%Multip)/real(Am%atom(i)%Mult)*Am%atom(i)%occ
          occ_std=real(MSgp%Multip)/real(Am%atom(i)%Mult)*Am%atom(i)%occ_std
          call setnum_std(occ,occ_std,text(5))
          uiso=Am%atom(i)%biso/78.95683521
          uiso_std=Am%atom(i)%biso_std/78.95683521
          call setnum_std(uiso,uiso_std,text(4))
          write(unit=Ipr,fmt="(a6,a6,3a13,2a11,i4,a)") Am%Atom(i)%lab, Am%atom(i)%SfacSymb,(text(j),j=1,5),&
                                                       Am%atom(i)%Mult," "//Am%atom(i)%wyck
       end do
       write(unit=Ipr,fmt="(a)")
       write(unit=Ipr,fmt="(a)") "loop_"
       write(unit=Ipr,fmt="(a)") "_magnetic_atom_site_moment_label"
       write(unit=Ipr,fmt="(a)") "_magnetic_atom_site_moment_crystalaxis_mx"
       write(unit=Ipr,fmt="(a)") "_magnetic_atom_site_moment_crystalaxis_my"
       write(unit=Ipr,fmt="(a)") "_magnetic_atom_site_moment_crystalaxis_mz"
       do i=1,Am%natoms
          !if(sum(abs(Am%Atom(i)%Skr(:,1))) < 0.0001) cycle
          if(Am%Atom(i)%moment < 0.01) cycle
          do j=1,3
            call setnum_std(Am%atom(i)%Skr(j,1),Am%atom(i)%Skr_std(j,1),text(j))
          end do
          write(unit=Ipr,fmt="(a8,3a12)") Am%Atom(i)%lab,(text(j),j=1,3)
       end do
       write(unit=Ipr,fmt="(a)")
       return
    End Subroutine Write_MCIF

    !!----
    !!---- Subroutine Write_Shubnikov_Group(SG,Iunit)
    !!----    type (Magnetic_Group_Type),intent(in) :: SG
    !!----    integer,   optional,       intent(in) :: iunit
    !!----
    !!----    Subroutine to write out the information about the Shubnikov_Group
    !!----
    !!---- Update: April 2008
    !!
    Subroutine Write_Shubnikov_Group(SG,Iunit)
       !---- Arguments ----!
       type (Magnetic_Group_Type),intent(in) :: SG
       integer,   optional,       intent(in) :: iunit

       !---- Local variables ----!
       character (len=100), dimension(24):: texto
       character (len=40)                :: aux
       integer                           :: lun
       integer                           :: i, nlines
       logical                           :: print_latt

       !---- Initializing variables ----!
       lun=6
       if (present(iunit)) lun=iunit
       print_latt=.true.

       !---- Printing ----!
       write(unit=lun,fmt="(/,/,a)")          "        Information on Space Group: "
       write(unit=lun,fmt="(a,/ )")           "        --------------------------- "
       write(unit=lun,fmt="(a,a )")          " =>       Shubnikov Symbol: ", SG%Shubnikov
       write(unit=lun,fmt="(a,i3)")          " =>  Number of Space group: ", SG%SpG%NumSpg
       write(unit=lun,fmt="(a,a)")           " => Hermann-Mauguin Symbol: ", SG%SpG%SPG_Symb
       write(unit=lun,fmt="(a,a)")           " =>            Hall Symbol: ", SG%SpG%Hall
       write(unit=lun,fmt="(a,a)")           " =>   Table Setting Choice: ", SG%SpG%info
       write(unit=lun,fmt="(a,a)")           " =>           Setting Type: ", SG%SpG%SG_setting
       write(unit=lun,fmt="(a,a)")           " =>         Crystal System: ", SG%SpG%CrystalSys
       write(unit=lun,fmt="(a,a)")           " =>             Laue Class: ", SG%SpG%Laue
       write(unit=lun,fmt="(a,a)")           " =>            Point Group: ", SG%SpG%Pg
       write(unit=lun,fmt="(a,a)")           " =>        Bravais Lattice: ", SG%SpG%SPG_Lat
       write(unit=lun,fmt="(a,a)")           " =>         Lattice Symbol: ", SG%SpG%SPG_Latsy
       write(unit=lun,fmt="(a,i3)")          " => Reduced Number of S.O.: ", SG%SpG%NumOps
       write(unit=lun,fmt="(a,i3)")          " =>   General multiplicity: ", SG%SpG%Multip
       write(unit=lun,fmt="(a,a)")           " =>         Centrosymmetry: ", SG%SpG%Centre
       write(unit=lun,fmt="(a,i3)")          " => Generators (exc. -1&L): ", SG%SpG%num_gen
       write(unit=lun,fmt="(a,f6.3,a,f6.3)") " =>        Asymmetric unit: ", SG%SpG%R_Asym_Unit(1,1), &
                                                                " <= x <= ", SG%SpG%R_Asym_Unit(1,2)
       write(unit=lun,fmt="(a,f6.3,a,f6.3)") "                            ", SG%SpG%R_Asym_Unit(2,1), &
                                                                " <= y <= ", SG%SpG%R_Asym_Unit(2,2)
       write(unit=lun,fmt="(a,f6.3,a,f6.3)") "                            ", SG%SpG%R_Asym_Unit(3,1), &
                                                                " <= z <= ", SG%SpG%R_Asym_Unit(3,2)

       if (SG%SpG%centred == 0) then
          call Frac_Trans_1Dig(SG%SpG%Centre_coord,texto(1))
          write(unit=lun,fmt="(a,a)")          " =>              Centre at: ", trim(texto(1))
       end if
       if (SG%SpG%SPG_Lat == "Z" .or. print_latt) then
          texto(:) (1:100) = " "
          if (SG%SpG%SPG_Lat == "Z") then
             write(unit=lun,fmt="(a,i3)")          " => Non-conventional Centring vectors:",SG%SpG%Numlat
          else
             write(unit=lun,fmt="(a,i3)")          " => Centring vectors:",SG%SpG%Numlat-1
          end if
          nlines=1
          do i=2,SG%SpG%Numlat
             call Frac_Trans_1Dig(SG%SpG%Latt_trans(:,i),aux)
             if (mod(i-1,2) == 0) then
                write(unit=texto(nlines)(51:100),fmt="(a,i2,a,a)") &
                                           " => Latt(",i-1,"): ",trim(aux)
                nlines=nlines+1
             else
                write(unit=texto(nlines)( 1:50),fmt="(a,i2,a,a)")  &
                                           " => Latt(",i-1,"): ",trim(aux)
             end if
          end do
          do i=1,nlines
             write(unit=lun,fmt="(a)") texto(i)
          end do
       end if

       !---- Symmetry Operators ----!
       write(unit=lun,fmt="(/,a,/)")        " => List of all Symmetry Operators and Symmetry Symbols"

       do i=1,SG%SpG%Multip
          texto(1)=" "
          call Symmetry_Symbol(SG%SpG%SymopSymb(i),texto(1))
          write(unit=lun,fmt="(a,i3,2a,t50,2a)") " => SYMM(",i,"): ",trim(SG%SpG%SymopSymb(i)), &
                                                    "Symbol: ",trim(texto(1))
       end do

       return
    End Subroutine Write_Shubnikov_Group

 End Module CFML_Magnetic_Symmetry

