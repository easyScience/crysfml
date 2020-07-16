! **************************************************************************
!
! CrysFML API
!
! @file      Src/Extensions/API_IO_Formats.f90
! @brief     CFML IO Formats Fortran binding
!
! @homepage  https://code.ill.fr/scientific-software/crysfml
! @license   GNU LGPL (see LICENSE)
! @copyright Institut Laue Langevin 2020-now
! @authors   Scientific Computing Group at ILL (see AUTHORS), based on Elias Rabel work for Forpy
!
! **************************************************************************

module API_Reflections_Utilities
  
  use forpy_mod
  use, intrinsic :: iso_c_binding
  use, intrinsic :: iso_fortran_env 

  use CFML_GlobalDeps,                 only: Cp
  use CFML_Reflections_Utilities,      only: &
       Reflection_List_Type, &
       Hkl_uni, &
       get_maxnumref
  
  
  use API_Crystallographic_Symmetry, only: &
       Space_Group_Type_p, &
       get_space_group_type_from_arg
  
  use API_Crystal_Metrics, only: &
       Crystal_Cell_Type_p, &
       get_cell_from_arg

  use CFML_Crystal_Metrics,  only: & 
       Write_Crystal_Cell

  
  implicit none

  type Reflection_List_type_p
     type(Reflection_List_type), pointer :: p
  end type Reflection_List_type_p

contains

  function reflections_utilities_hkl_uni_reflist(self_ptr, args_ptr) result(r) bind(c)

    type(c_ptr), value :: self_ptr
    type(c_ptr), value :: args_ptr
    type(c_ptr)        :: r
    type(tuple)        :: args 
    type(dict)         :: retval
    
    integer            :: num_args
    integer            :: ierror
    integer            :: ii
    
    type(list)   :: index_obj
    type(object) :: arg_obj

    type(Crystal_Cell_type_p)       :: cell_p
    type(Space_Group_type_p)        :: spg_p
    type(Reflection_List_type_p)    :: hkl_p
    integer                         :: hkl_p12(12)

    logical       :: friedel
    real(kind=cp) :: value1, value2
    integer       :: maxnumref
    

    r = C_NULL_PTR   ! in case of an exception return C_NULL_PTR
    ! use unsafe_cast_from_c_ptr to cast from c_ptr to tuple
    call unsafe_cast_from_c_ptr(args, args_ptr)
    ! Check if the arguments are OK
    ierror = args%len(num_args)

    if (num_args /= 5) then
       call raise_exception(TypeError, "hkl_uni_reflist expects exactly 5 arguments")
       !Cell, SpG, lFriedel, value1, value2)
       call args%destroy
       return
    endif

    write(8,*) 'before get cell'

    call get_cell_from_arg(args, cell_p, 0)
    call Write_Crystal_Cell(Cell_p%p)
    
    call get_space_group_type_from_arg(args, spg_p, 1)

    ierror = args%getitem(arg_obj, 2)
    ierror = cast_nonstrict(friedel, arg_obj)

    ierror = args%getitem(arg_obj, 3)
    ierror = cast_nonstrict(value1, arg_obj)

    ierror = args%getitem(arg_obj, 4)
    ierror = cast_nonstrict(value2, arg_obj)

    !> @todo here value2 is assumed to be stlmax 
    MaxNumRef = get_maxnumref(value2,Cell_p%p%CellVol,mult=2*SpG_p%p%NumOps)

    write(*,*) 'maxnumref',maxnumref
    
    allocate(hkl_p%p)
    call Hkl_Uni(cell_p%p,spg_p%p,friedel,value1,value2,"s",MaxNumRef,hkl_p%p)

    write(*,*) 'happy'
    
    hkl_p12 = transfer(hkl_p,hkl_p12)
    ierror = list_create(index_obj)
    do ii=1,12
       ierror = index_obj%append(hkl_p12(ii))
    end do

    ierror = dict_create(retval)
    ierror = retval%setitem("address", index_obj)
    r = retval%get_c_ptr()

  end function reflections_utilities_hkl_uni_reflist

end module API_Reflections_Utilities
