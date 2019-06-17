!!----
!!----
!!----
!!
SubModule (CFML_gSpaceGroups) SPG_008
   Contains
   
   !!----
   !!---- Allocate_SpaceGroup
   !!----
   !!---- 19/04/19
   !!
   Module Subroutine Allocate_SpaceGroup(D, Multip, Grp)
      !---- Arguments ----!
      integer,         intent(in)     :: d,multip
      class(Spg_Type), intent(in out) :: Grp
       
      !---- Local Variables ----! 
      integer :: i
      
      !> Init
      if (allocated(Grp%Op)) deallocate(Grp%Op)
      allocate(Grp%Op(multip))
      
      Grp%d=d
      Grp%multip=multip
      do i=1,multip
         call Allocate_Op(d,Grp%Op(i))
      end do
      
      if(allocated(Grp%Symb_Op)) deallocate(Grp%Symb_Op)
      allocate(Grp%Symb_Op(multip))
   End Subroutine Allocate_SpaceGroup

End SubModule SPG_008
   
