!!----
!!----
!!----
SubModule (CFML_IOForm) IO_CIF

   !---- Local Variables ----!
   character(len=132)            :: line
   character(len=:), allocatable :: str
   integer                       :: j_ini, j_end

   Contains


   !!----
   !!---- Read_Cif_Atom
   !!----    Obtaining Atoms parameters from Cif file. A control error is present.
   !!----
   !!---- 26/06/2019
   !!
   Module Subroutine Read_CIF_Atoms(cif, AtmList, i_ini, i_end)
      !---- Arguments ----!
      type(File_Type),    intent(in)  :: cif
      type(atList_type),  intent(out) :: AtmList
      integer, optional,  intent(in)  :: i_ini, i_end

      !---- Local Variables ----!
      character(len=20),dimension(15)     :: label
      integer                             :: i, j, n, nc, nct, nline, iv, First, nline_big,num_ini,mm
      integer, dimension( 8)              :: lugar   !   1 -> label
                                                     !   2 -> Symbol
                                                     ! 3-5 -> coordinates
                                                     !   6 -> occupancy
                                                     !   7 -> Uequi
                                                     !   8 -> Biso
      real(kind=cp), dimension(1)     :: vet1,vet2
      integer,       dimension(1)     :: ivet

      type(atlist_type)               :: Atm

      type (atm_type)                 :: atm1
      type (atm_std_type)             :: atm2
      type (matm_std_type)            :: atm3
      type (atm_ref_type)             :: atm4

      class(atm_type), allocatable    :: atm5

      !> Init
      call clear_error()
      if (cif%nlines <=0) then
         err_CFML%Ierr=1
         err_CFML%Msg="Read_CIF_Atom: 0 lines "
         return
      end if

      j_ini=1; j_end=cif%nlines
      if (present(i_ini)) j_ini=i_ini
      if (present(i_end)) j_end=i_end

      if (AtmList%natoms > 0) call allocate_atom_list(0, AtmList,'Atm_std',0)

      !> Search loop for atoms
      str="_atom_site_label"
      nl=len_trim(str)
      do i=j_ini,j_end
         line=adjustl(cif%line(i)%str)

         if (len_trim(line) <=0) cycle
         if (line(1:1) == '#') cycle

         !> eliminar tabs
         do
            iv=index(line,TAB)
            if (iv == 0) exit
            line(iv:iv)=' '
         end do

         npos=index(line,str)
         if (npos ==0) cycle

         !> search the loop
         do j=i-1,j_ini,-1
            line=adjustl(cif%line(j)%str)
            if (len_trim(line) <=0) cycle
            if (line(1:1) == '#') cycle

            npos=index(line,'loop_')
            if (npos ==0) cycle
            j_ini=j+1
            exit
         end do
         exit
      end do

      lugar=0
      j=0
      do i=j_ini,j_end
         line=adjustl(cif%line(i)%str)

         if (len_trim(line) <=0) cycle
         if (line(1:1) == '#') cycle
         if (line(1:5) /='_atom') exit

         select case (trim(line))
            case ('_atom_site_label')
               j=j+1
               lugar(1)=j
            case ('_atom_site_type_symbol')
               j=j+1
               lugar(2)=j
            case ('_atom_site_fract_x')
               j=j+1
               lugar(3)=j
            case ('_atom_site_fract_y')
               j=j+1
               lugar(4)=j
            case ('_atom_site_fract_z')
               j=j+1
               lugar(5)=j
            case ('_atom_site_occupancy')
               j=j+1
               lugar(6)=j
            case ('_atom_site_U_iso_or_equiv')
               j=j+1
               lugar(7)=j
            case ('_atom_site_adp_type')
               j=j+1
               lugar(8)=j
         end select
      end do

      if (any(lugar(3:5) == 0)) then
         err_CFML%Ierr=1
         err_CFML%Msg="Read_Cif_Atom: Error reading atoms in CIF format!"
         return
      end if

      !> Calculating atoms
      n=0
      j_ini=i
      do i=j_ini, j_end
         line=adjustl(cif%line(i)%str)

         if (line(1:1) == '#') cycle
         if (len_trim(line) <=0) exit
         if (line(1:1) == "_" .or. line(1:5) == "loop_") exit
         n=n+1
         cycle
      end do
      if (n <=0) then
         err_CFML%Ierr=1
         err_CFML%Msg="Read_Cif_Atom: Error reading atoms in CIF format!"
         return
      end if
      call allocate_atom_list(n,Atm,'Atm_std',0)

      !> reading atoms
      n=0
      do i=j_ini, j_end
         line=adjustl(cif%line(i)%str)

         if (line(1:1) == '#') cycle
         if (len_trim(line) <=0) exit
         if (line(1:1) == "_" .or. line(1:5) == "loop_") exit

         call get_words(line, label, nc)
         if (nc <=0) then
            err_CFML%Ierr=1
            err_CFML%Msg="Read_CIF_Atom: Something is wrong in "//trim(line)
            return
         end if

         n=n+1

         !> _atom_site_label
         atm%atom(n)%lab=label(lugar(1))

         !> _atom_site_type_symbol
         if (lugar(2) /= 0) then
            atm%atom(n)%SfacSymb=label(lugar(2))(1:4)
            if (index(DIGCAR, label(lugar(2))(2:2)) /= 0 ) then
               atm%atom(n)%chemSymb=u_case(label(lugar(2))(1:1))
            else
               atm%atom(n)%chemSymb=u_case(label(lugar(2))(1:1))//l_case(label(lugar(2))(2:2))
            end if
         else
            if(index(DIGCAR,label(lugar(1))(2:2)) /= 0 ) then
               atm%atom(n)%chemSymb=u_case(label(lugar(1))(1:1))
            else
               atm%atom(n)%chemSymb=u_case(label(lugar(1))(1:1))//l_case(label(lugar(1))(2:2))
            end if
            atm%atom(n)%SfacSymb=atm%atom(n)%chemSymb
         end if

         !> Coordinates
         select type (at => atm%atom)
            type is (atm_type)
               call get_numstd(label(lugar(3)),vet1,vet2,iv)
               at(n)%x(1)=vet1(1)
               call get_numstd(label(lugar(4)),vet1,vet2,iv)
               at(n)%x(2)=vet1(1)
               call get_numstd(label(lugar(5)),vet1,vet2,iv)
               at(n)%x(3)=vet1(1)

            class is (atm_std_type)
               call get_numstd(label(lugar(3)),vet1,vet2,iv)
               at(n)%x(1)=vet1(1)
               at(n)%x_std(1)=vet2(1)
               call get_numstd(label(lugar(4)),vet1,vet2,iv)
               at(n)%x(2)=vet1(1)
               at(n)%x_std(2)=vet2(1)
               call get_numstd(label(lugar(5)),vet1,vet2,iv)
               at(n)%x(3)=vet1(1)
               at(n)%x_std(3)=vet2(1)
         end select

         !> _atom_site_occupancy
         if (lugar(6) /= 0) then
            call get_numstd(label(lugar(6)),vet1,vet2,iv)
         else
            vet1=1.0
            vet2=0.0_cp
         end if
         select type (at => atm%atom)
            type is (atm_type)
               at(n)%occ=vet1(1)

            class is (atm_std_type)
               at(n)%occ=vet1(1)
               at(n)%occ_std=vet2(1)
         end select

         !> U_iso
         if (lugar(7) /= 0) then
            call get_numstd(label(lugar(7)),vet1,vet2,iv)    ! _atom_site_U_iso_or_equiv
            select type (at => atm%atom)
               type is (atm_type)
                  at(n)%U_iso=vet1(1)

               class is (atm_std_type)
                  at(n)%U_iso=vet1(1)
                  at(n)%U_iso_std=vet2(1)
            end select
            atm%atom(n)%utype="U"
         else
            select type (at => atm%atom)
               type is (atm_type)
                  at(n)%U_iso=0.5_cp
               class is (atm_std_type)
                  at(n)%U_iso=0.5_cp
                  at(n)%U_iso_std=0.0_cp
            end select
            atm%atom(n)%utype="U"
         end if

         !> Iso or Ani
         if (lugar(8) /= 0) then
            select case (trim(l_case(label(lugar(8)))))
               case('uiso')
                  atm%atom(n)%thtype='iso'
               case('uani')
                  atm%atom(n)%thtype='ani'
            end select
         end if
      end do

      !> Search loop for atoms in aniso
      str="_atom_site_aniso_label"
      nl=len_trim(str)
      do i=j_ini,j_end
         line=adjustl(cif%line(i)%str)

         if (len_trim(line) <=0) cycle
         if (line(1:1) == '#') cycle

         !> eliminar tabs
         do
            iv=index(line,TAB)
            if (iv == 0) exit
            line(iv:iv)=' '
         end do

         npos=index(line,str)
         if (npos ==0) cycle

         !> search the loop
         do j=i-1,j_ini,-1
            line=adjustl(cif%line(j)%str)
            if (len_trim(line) <=0) cycle
            if (line(1:1) == '#') cycle

            npos=index(line,'loop_')
            if (npos ==0) cycle
            j_ini=j+1
            exit
         end do
         exit
      end do

      lugar=0
      j=0
      do i=j_ini,j_end
         line=adjustl(cif%line(i)%str)

         if (len_trim(line) <=0) cycle
         if (line(1:1) == '#') cycle
         if (line(1:5) /='_atom') exit

         select case (trim(line))
            case ('_atom_site_aniso_label')
               j=j+1
               lugar(1)=j
            case ('_atom_site_aniso_U_11')
               j=j+1
               lugar(2)=j
            case ('_atom_site_aniso_U_22')
               j=j+1
               lugar(3)=j
            case ('_atom_site_aniso_U_33')
               j=j+1
               lugar(4)=j
            case ('_atom_site_aniso_U_23')
               j=j+1
               lugar(5)=j
            case ('_atom_site_aniso_U_13')
               j=j+1
               lugar(6)=j
            case ('_atom_site_aniso_U_12')
               j=j+1
               lugar(7)=j
         end select
      end do

      !> reading anisotropic thermal parameters
      j_ini=i
      do i=j_ini, j_end
         line=adjustl(cif%line(i)%str)

         if (line(1:1) == '#') cycle
         if (len_trim(line) <=0) exit
         if (line(1:1) == "_" .or. line(1:5) == "loop_") exit

         call get_words(line, label, nc)

         if (nc <=0) then
            err_CFML%Ierr=1
            err_CFML%Msg="Read_CIF_Atom: Something is wrong in "//trim(line)
            return
         end if

         do j=1,n
            !> Found the anisotropic atom
            if (trim(label(lugar(1))) /= trim(atm%atom(j)%lab)) cycle

            if (atm%atom(j)%thtype /='ani') then
               err_CFML%Ierr=1
               err_CFML%Msg="Read_CIF_Atom: Something is wrong in Anisotropic thermal parameters!"
               return
            end if

            !> _atom_site_aniso_U_11
            call get_numstd(label(lugar(2)),vet1,vet2,iv)
            select type (at => atm%atom)
               type is (atm_type)
                  at(j)%u(1)    =vet1(1)
               class is (atm_std_type)
                  at(j)%u(1)    =vet1(1)
                  at(j)%u_std(1)=vet2(1)
            end select

            !> _atom_site_aniso_U_22
            call get_numstd(label(lugar(3)),vet1,vet2,iv)
            select type (at => atm%atom)
               type is (atm_type)
                  at(j)%u(2)    =vet1(1)
               class is (atm_std_type)
                  at(j)%u(2)    =vet1(1)
                  at(j)%u_std(2)=vet2(1)
            end select

            !> _atom_site_aniso_U_33
            call get_numstd(label(lugar(4)),vet1,vet2,iv)
            select type (at => atm%atom)
               type is (atm_type)
                  at(j)%u(3)    =vet1(1)
               class is (atm_std_type)
                  at(j)%u(3)    =vet1(1)
                  at(j)%u_std(3)=vet2(1)
            end select

            !> _atom_site_aniso_U_12
            call get_numstd(label(lugar(7)),vet1,vet2,iv)
            select type (at => atm%atom)
               type is (atm_type)
                  at(j)%u(4)    =vet1(1)
               class is (atm_std_type)
                  at(j)%u(4)    =vet1(1)
                  at(j)%u_std(4)=vet2(1)
            end select

            !> _atom_site_aniso_U_13
            call get_numstd(label(lugar(6)),vet1,vet2,iv)
            select type (at => atm%atom)
               type is (atm_type)
                  at(j)%u(5)    =vet1(1)
               class is (atm_std_type)
                  at(j)%u(5)    =vet1(1)
                  at(j)%u_std(5)=vet2(1)
            end select

            !> _atom_site_aniso_U_23
            call get_numstd(label(lugar(5)),vet1,vet2,iv)
            select type (at => atm%atom)
               type is (atm_type)
                  at(j)%u(6)    =vet1(1)
               class is (atm_std_type)
                  at(j)%u(6)    =vet1(1)
                  at(j)%u_std(6)=vet2(1)
            end select
         end do

      end do

      !> Look for the first atoms fully occupying the site and put it in first position
      !> This is needed for properly calculating the occupation factors
      !> after normalization in subroutine Readn_Set_XTal_CIF

      vet1=maxval(atm%atom(1:n)%occ)  !Normalize occupancies
      atm%atom%occ=atm%atom%occ/vet1(1)
      First=1
      do i=1,n
         if (abs(atm%atom(i)%occ-1.0_cp) < EPS) then
            First=i
            exit
         end if
      end do

      !> Swapping the orinal atom at the first position with the first having full occupation
      if (First /= 1) Then
         select type (at => atm%atom)
            type is (atm_type)
               atm1=at(1)
               at(1)=at(first)
               at(first)=atm1

            type is (atm_std_type)
               atm2=at(1)
               at(1)=at(first)
               at(first)=atm2

            type is (matm_std_type)
            type is (atm_ref_type)
         end select
      end if

      !> Put the first atom the first having a full occupation factor 1.0
      if (n <=0) return

      call allocate_atom_list(n, AtmList,'atm_std',0)
      AtmList%atom=atm%atom(1:n)
      call allocate_atom_list(0,Atm,'atm_std',0)

   End Subroutine Read_CIF_Atoms

   !!----
   !!---- READ_CIF_CELL
   !!----    Read Cell Parameters from CIF format
   !!----
   !!---- Update: February - 2005
   !!
   Module Subroutine Read_CIF_Cell(cif, Cell, i_Ini, i_End)
      !---- Arguments ----!
      type(File_Type),    intent(in)  :: cif
      class(Cell_Type),   intent(out) :: Cell    ! Cell object
      integer, optional,  intent(in)  :: i_ini, i_end   ! Index to start

      !---- Local Variables ----!
      integer                         :: i,npos,nl,iv
      real(kind=cp), dimension(1)     :: vet1,vet2
      real(kind=cp), dimension(6)     :: vcell, std
      logical                         :: ierror

      !> Init
      call clear_error()
      if (cif%nlines <=0) then
         err_CFML%Ierr=1
         err_CFML%Msg="Read_CIF_Cell: 0 lines "
         return
      end if

      j_ini=1; j_end=cif%nlines
      if (present(i_ini)) j_ini=i_ini
      if (present(i_end)) j_end=i_end

      vcell=0.0_cp; std=0.0_cp
      ierror=.false.

      !> a
      str="_cell_length_a"
      nl=len_trim(str)
      do i=j_ini,j_end
         line=adjustl(cif%line(i)%str)

         if (len_trim(line) <=0) cycle
         if (line(1:1) == '#') cycle

         !> eliminar tabs
         do
            iv=index(line,TAB)
            if (iv == 0) exit
            line(iv:iv)=' '
         end do

         npos=index(line,str)
         if (npos ==0) cycle

         call get_Numstd(line(npos+nl:), vet1, vet2, iv)
         if (iv == 1) then
            vcell(1)=vet1(1)
            std(1)=vet2(1)
            exit
         else
            ierror=.true.
         end if
      end do

      !> b
      str="_cell_length_b"
      nl=len_trim(str)
      do i=j_ini,j_end
         line=adjustl(cif%line(i)%str)

         if (len_trim(line) <=0) cycle
         if (line(1:1) == '#') cycle

         !> eliminar tabs
         do
            iv=index(line,TAB)
            if (iv == 0) exit
            line(iv:iv)=' '
         end do

         npos=index(line,str)
         if (npos ==0) cycle

         call get_Numstd(line(npos+nl:), vet1, vet2, iv)
         if (iv == 1) then
            vcell(2)=vet1(1)
            std(2)=vet2(1)
            exit
         else
            ierror=.true.
         end if
      end do

      !> c
       str="_cell_length_c"
      nl=len_trim(str)
      do i=j_ini,j_end
         line=adjustl(cif%line(i)%str)

         if (len_trim(line) <=0) cycle
         if (line(1:1) == '#') cycle

         !> eliminar tabs
         do
            iv=index(line,TAB)
            if (iv == 0) exit
            line(iv:iv)=' '
         end do

         npos=index(line,str)
         if (npos ==0) cycle

         call get_Numstd(line(npos+nl:), vet1, vet2, iv)
         if (iv == 1) then
            vcell(3)=vet1(1)
            std(3)=vet2(1)
            exit
         else
            ierror=.true.
         end if
      end do

      !> alpha
      str="_cell_angle_alpha"
      nl=len_trim(str)
      do i=j_ini,j_end
         line=adjustl(cif%line(i)%str)

         if (len_trim(line) <=0) cycle
         if (line(1:1) == '#') cycle

         !> eliminar tabs
         do
            iv=index(line,TAB)
            if (iv == 0) exit
            line(iv:iv)=' '
         end do
         npos=index(line,str)
         if (npos ==0) cycle

         call get_Numstd(line(npos+nl:), vet1, vet2, iv)
         if (iv == 1) then
            vcell(4)=vet1(1)
            std(4)=vet2(1)
            exit
         else
            ierror=.true.
         end if
      end do

      !> beta
      str="_cell_angle_beta"
      nl=len_trim(str)
      do i=j_ini,j_end
         line=adjustl(cif%line(i)%str)

         if (len_trim(line) <=0) cycle
         if (line(1:1) == '#') cycle

         !> eliminar tabs
         do
            iv=index(line,TAB)
            if (iv == 0) exit
            line(iv:iv)=' '
         end do
         npos=index(line,str)
         if (npos ==0) cycle

         call get_Numstd(line(npos+nl:), vet1, vet2, iv)
         if (iv == 1) then
            vcell(5)=vet1(1)
            std(5)=vet2(1)
            exit
         else
            ierror=.true.
         end if
      end do

      !> gamma
      str="_cell_angle_gamma"
      nl=len_trim(str)
      do i=j_ini,j_end
         line=adjustl(cif%line(i)%str)

         if (len_trim(line) <=0) cycle
         if (line(1:1) == '#') cycle

         !> eliminar tabs
         do
            iv=index(line,TAB)
            if (iv == 0) exit
            line(iv:iv)=' '
         end do
         npos=index(line,str)
         if (npos ==0) cycle

         call get_Numstd(line(npos+nl:), vet1, vet2, iv)
         if (iv == 1) then
            vcell(6)=vet1(1)
            std(6)=vet2(1)
            exit
         else
            ierror=.true.
         end if
      end do

      if (ierror) then
         err_CFML%Ierr=1
         err_CFML%Msg="Read_CIF_Cell: Problems reading cell parameters!"
         return
      end if

      call Set_Crystal_Cell(vcell(1:3),vcell(4:6), Cell, Vscell=std(1:3), Vsang=std(4:6))

   End Subroutine Read_Cif_Cell

   !!----
   !!---- READ_CIF_WAVE
   !!----    Read Wavelength in CIF Format
   !!----
   !!---- 27/06/2019
   !!
   Module Subroutine Read_CIF_Wave(cif, Wave,i_ini,i_end)
      !---- Arguments ----!
      type(File_Type),    intent(in)  :: cif
      real(kind=cp),      intent(out) :: Wave    ! Wavelength
      integer, optional,  intent(in)  :: i_ini,i_end

      !---- Local Variables ----!
      integer                    :: i,nl,iv
      integer,dimension(1)       :: ivet
      real(kind=cp), dimension(1):: vet

      !> Init
      wave=0.0_cp
      call clear_error()
      if (cif%nlines <=0) then
         err_CFML%Ierr=1
         err_CFML%Msg="Read_CIF_Wave: 0 lines "
         return
      end if

      str="_diffrn_radiation_wavelength"
      nl=len_trim(str)

      do i=j_ini, j_end
         line=adjustl(cif%line(i)%str)

         if (len_trim(line) <=0) cycle
         if (line(1:1) == '#') cycle

         !> eliminar tabs
         do
            iv=index(line,TAB)
            if (iv == 0) exit
            line(iv:iv)=' '
         end do

         npos=index(line,str)
         if (npos ==0) cycle

         call get_num(line(npos+nl:),vet,ivet,iv)
         exit
      end do

      if (iv == 1) then
         wave=vet(1)
      else
         err_CFML%Ierr=1
         err_CFML%Msg="Read_CIF_Wave: Problems reading wavelenth value!"
      end if

   End Subroutine Read_CIF_Wave

   !!----
   !!---- READ_CIF_Z
   !!----    Unit formula from Cif file
   !!----
   !!---- 27/06/2019
   !!
   Module Subroutine Read_CIF_Z(cif,Z, i_ini, i_end)
      !---- Arguments ----!
      type(File_Type),    intent(in)  :: cif
      real(kind=cp),      intent(out) :: Z             ! Z number
      integer, optional,  intent(in)  :: i_ini,i_end   ! Index to Finish

      !---- Local Variables ----!
      integer                     :: i,nl,npos,iv
      integer,dimension(1)        :: ivet
      real(kind=cp), dimension(1) :: vet

      !> Init
      z=0.0_cp
      call clear_error()
      if (cif%nlines <=0) then
         err_CFML%Ierr=1
         err_CFML%Msg="Read_CIF_Z: 0 lines "
         return
      end if

      j_ini=1; j_end=cif%nlines
      if (present(i_ini)) j_ini=i_ini
      if (present(i_end)) j_end=i_end

      str="_cell_formula_units_Z"
      nl=len_trim(str)

      do i=j_ini, j_end
         line=adjustl(cif%line(i)%str)

         if (len_trim(line) <=0) cycle
         if (line(1:1) == '#') cycle

         !> eliminar tabs
         do
            iv=index(line,TAB)
            if (iv == 0) exit
            line(iv:iv)=' '
         end do

         npos=index(line,str)
         if (npos ==0) cycle

         call get_num(line(npos+nl:),vet,ivet,iv)
         exit
      end do

      if (iv == 1) then
         z=vet(1)
      else
         err_CFML%Ierr=1
         err_CFML%Msg="Read_CIF_Z: Problems reading Z value!"
      end if

   End Subroutine Read_CIF_Z

   !!----
   !!---- READ_CIF_CHEMICALNAME
   !!----    Obtaining Chemical Name from Cif file
   !!----
   !!---- 27/06/2019
   !!
   Module Subroutine Read_CIF_ChemName(cif, ChemName, i_ini,i_end)
      !---- Arguments ----!
      type(File_Type),    intent(in)  :: cif
      character(len=*),   intent(out) :: ChemName
      integer, optional,  intent(in)  :: i_ini, i_end

      !---- Local variables ----!
      integer :: i,nl,np1, np2

      !> Init
      ChemName=" "
      call clear_error()
      if (cif%nlines <=0) then
         err_CFML%Ierr=1
         err_CFML%Msg="Read_CIF_ChemName: 0 lines "
         return
      end if

      j_ini=1; j_end=cif%nlines
      if (present(i_ini)) j_ini=i_ini
      if (present(i_end)) j_end=i_end

      !> First tentative
      str="_chemical_name_common"
      nl=len_trim(str)
      do i=j_ini, j_end
         line=adjustl(cif%line(i)%str)

         if (len_trim(line) <=0) cycle
         if (line(1:1) == '#') cycle

         !> eliminar tabs
         do
            iv=index(line,TAB)
            if (iv == 0) exit
            line(iv:iv)=' '
         end do

         npos=index(line,str)
         if (npos ==0) cycle

         ChemName=adjustl(line(npos+nl:))
         exit
      end do
      if (trim(ChemName) =="?" .or. trim(ChemName)=="#" .or. trim(ChemName)=="''") ChemName=" "
      if (len_trim(ChemName) > 0) then
         np1=index(ChemName,"'")
         np2=index(ChemName,"'",back=.true.)
         if (np1 > 0 .and. np2 > 0 .and. np2 > np1) then
            ChemName=ChemName(np1+1:np2-1)
         end if
         return
      end if

      !> Second tentative
      str="_chemical_name_systematic"
      nl=len_trim(str)
      do i=j_ini, j_end
         line=adjustl(cif%line(i)%str)

         if (len_trim(line) <=0) cycle
         if (line(1:1) == '#') cycle

         !> eliminar tabs
         do
            iv=index(line,TAB)
            if (iv == 0) exit
            line(iv:iv)=' '
         end do

         npos=index(line,str)
         if (npos ==0) cycle

         ChemName=adjustl(line(npos+nl:))
         exit
      end do
      if (trim(ChemName) =="?" .or. trim(ChemName)=="#" .or. trim(ChemName)=="''") ChemName=" "
      if (len_trim(ChemName) > 0) then
         np1=index(ChemName,"'")
         np2=index(ChemName,"'",back=.true.)
         if (np1 > 0 .and. np2 > 0 .and. np2 > np1) then
            ChemName=ChemName(np1+1:np2-1)
         end if
      end if

   End Subroutine Read_CIF_ChemName

   !!----
   !!---- READ_CIF_CONT
   !!----    Obtaining the chemical contents from Cif file
   !!----
   !!---- 27/06/2019
   !!
   Module Subroutine Read_CIF_Cont(cif,N_Elem_Type,Elem_Type,N_Elem,i_ini,i_end)
      !---- Arguments ----!
      type(File_Type),                      intent(in)  :: cif
      integer,                              intent(out) :: n_elem_type
      character(len=*), dimension(:),       intent(out) :: elem_type
      real(kind=cp), dimension(:),optional, intent(out) :: n_elem
      integer,                    optional, intent(in)  :: i_ini, i_end

      !---- Local  variables ----!
      character(len=10), dimension(15) :: label

      integer                     :: i,nl,iv
      integer                     :: np1,np2,nlabel,nlong
      integer,       dimension(1) :: ivet
      real(kind=cp), dimension(1) :: vet

      !> Init
      n_elem_type = 0
      elem_type   = " "
      if (present(n_elem)) n_elem = 0.0_cp

      call clear_error()
      if (cif%nlines <=0) then
         err_CFML%Ierr=1
         err_CFML%Msg="Read_CIF_Hall: 0 lines "
         return
      end if

      j_ini=1; j_end=cif%nlines
      if (present(i_ini)) j_ini=i_ini
      if (present(i_end)) j_end=i_end

      str="_chemical_formula_sum"
      nl=len_trim(str)
      line=" "
      do i=j_ini, j_end
         line=adjustl(cif%line(i)%str)

         if (len_trim(line) <=0) cycle
         if (line(1:1) == '#') cycle

         !> eliminar tabs
         do
            iv=index(line,TAB)
            if (iv == 0) exit
            line(iv:iv)=' '
         end do

         npos=index(line,str)
         if (npos ==0) cycle

         line=adjustl(line(npos+nl:))
         exit
      end do
      if (trim(line) =="?" .or. trim(line)=="#" .or. trim(line)=="''") line=" "
      if (len_trim(line) > 0) then
         np1=index(line,"'")
         np2=index(line,"'",back=.true.)
         if (np1 > 0 .and. np2 > 0 .and. np2 > np1) then
            line=line(np1+1:np2-1)
         end if
      end if
      if (len_trim(line) <= 0) return

      call get_words(line, label, nlabel)
      if (nlabel ==0) return

      n_elem_type = nlabel
      do i=1,nlabel
         nlong=len_trim(label(i))
         select case (nlong)
             case (1)
                elem_type(i)=label(i)(1:1)
                if (present(n_elem)) n_elem(i)   = 1.0_cp

             case (2)
                call get_num(label(i)(2:),vet,ivet,iv)
                if (iv == 1) then
                   elem_type(i)=label(i)(1:1)
                   if (present(n_elem)) n_elem(i)   =vet(1)
                else
                   elem_type(i)=label(i)(1:2)
                   if (present(n_elem)) n_elem(i)   = 1.0_cp
                end if

             case (3:)
                call get_num(label(i)(2:),vet,ivet,iv)
                if (iv == 1) then
                   elem_type(i)=label(i)(1:1)
                   if (present(n_elem)) n_elem(i)   =vet(1)
                else
                   call get_num(label(i)(3:),vet,ivet,iv)
                   if (iv == 1) then
                      elem_type(i)=label(i)(1:2)
                      if (present(n_elem)) n_elem(i)   =vet(1)
                   else
                      elem_type(i)=label(i)(1:2)
                      if (present(n_elem)) n_elem(i)   = 1.0_cp
                   end if
                end if
         end select
      end do

   End Subroutine Read_CIF_Cont

   !!----
   !!---- READ_CIF_PRESSURE
   !!----    Pressure and Sigma in GPa
   !!----
   !!---- 27/06/2019
   !!
   Module Subroutine Read_CIF_Pressure(cif, P, SigP, i_ini, i_end)
      !---- Arguments ----!
      type(File_Type),    intent(in)  :: cif
      real(kind=cp),      intent(out) :: p
      real(kind=cp),      intent(out) :: sigp
      integer, optional,  intent(in)  :: i_ini, i_end   ! Index to start

      !---- Local Variables ----!
      integer                       :: i,iv
      real(kind=cp),dimension(1)    :: vet1,vet2

      !> Init
      p=0.0_cp; SigP=1.0e-5

      call clear_error()
      if (cif%nlines <=0) then
         err_CFML%Ierr=1
         err_CFML%Msg="Read_CIF_Pressure: 0 lines "
         return
      end if

      j_ini=1; j_end=cif%nlines
      if (present(i_ini)) j_ini=i_ini
      if (present(i_end)) j_end=i_end

      str="_diffrn_ambient_pressure"
      nl=len_trim(str)
      do i=j_ini,j_end
         line=adjustl(cif%line(i)%str)

         if (len_trim(line) <=0) cycle
         if (line(1:1) == '#') cycle

         !> eliminar tabs
         do
            iv=index(line,TAB)
            if (iv == 0) exit
            line(iv:iv)=' '
         end do

         npos=index(line,str)
         if (npos ==0) cycle

         call get_Numstd(line(npos+nl:), vet1, vet2, iv)
         if (iv == 1) then
            p=vet1(1)*1.0e6
            sigp=vet2(1)*1.0e6
            exit
         end if
      end do

   End Subroutine Read_CIF_Pressure

   !!----
   !!---- Read_Cif_Title
   !!----    Obtaining Title from Cif file
   !!----
   !!---- 27/06/2019
   !!
   Module Subroutine Read_CIF_Title(cif,Title,i_Ini,i_End)
      !---- Arguments ----!
      type(File_Type),    intent(in)  :: cif
      character(len=*),   intent(out) :: title
      integer, optional,  intent(in)  :: i_ini, i_end   ! Index to start

      !---- Local variables ----!
      integer :: i, iv,nl,npos, np1, np2

      !> Init
      title=" "
      call clear_error()
      if (cif%nlines <=0) then
         err_CFML%Ierr=1
         err_CFML%Msg="Read_CIF_Title: 0 lines "
         return
      end if

      j_ini=1; j_end=cif%nlines
      if (present(i_ini)) j_ini=i_ini
      if (present(i_end)) j_end=i_end

      str="_publ_section_title"
      nl=len_trim(str)
      do i=j_ini, j_end
         line=adjustl(cif%line(i)%str)

         if (len_trim(line) <=0) cycle
         if (line(1:1) == '#') cycle

         !> eliminar tabs
         do
            iv=index(line,TAB)
            if (iv == 0) exit
            line(iv:iv)=' '
         end do

         npos=index(line,str)
         if (npos ==0) cycle

         title=adjustl(line(npos+nl:))
         exit
      end do

      !> Check
      if (trim(title)=='?' .or. trim(title)=='#' .or. trim(title)==''  ) then
         title=' '
      else
         np1=index(title,"'")
         np2=index(title,"'",back=.true.)
         if (np1 > 0 .and. np2 > 0 .and. np2 > np1) then
            title=title(np1+1:np2-1)
         end if
      end if

   End Subroutine Read_CIF_Title

   !!----
   !!---- READ_CIF_IT
   !!----    Space group defined by I.T.
   !!----
   !!---- 11/05/2020
   !!
   Module Subroutine Read_CIF_IT(cif,IT,i_ini, i_end)
      !---- Arguments ----!
      type(File_Type),    intent(in)  :: cif
      integer,            intent(out) :: IT
      integer, optional,  intent(in)  :: i_ini, i_end   ! Index to start

      !---- Local Variables ----!
      integer                       :: i,iv
      integer, dimension(1)         :: ivet
      real(kind=cp),dimension(1)    :: vet

      !> Init
      it=0

      call clear_error()
      if (cif%nlines <=0) then
         err_CFML%Ierr=1
         err_CFML%Msg="Read_CIF_IT: 0 lines "
         return
      end if

      j_ini=1; j_end=cif%nlines
      if (present(i_ini)) j_ini=i_ini
      if (present(i_end)) j_end=i_end

      str="_space_group_IT_number"
      nl=len_trim(str)
      do i=j_ini,j_end
         line=adjustl(cif%line(i)%str)

         if (len_trim(line) <=0) cycle
         if (line(1:1) == '#') cycle

         !> eliminar tabs
         do
            iv=index(line,TAB)
            if (iv == 0) exit
            line(iv:iv)=' '
         end do

         npos=index(line,str)
         if (npos ==0) cycle

         call get_Num(line(npos+nl:), vet, ivet, iv)
         if (iv == 1) then
            it=ivet(1)
            exit
         end if
      end do

   End Subroutine Read_CIF_IT

   !!----
   !!---- READ_CIF_TEMP
   !!----    Temperature and Sigma in Kelvin
   !!----
   !!---- 27/06/2019
   !!
   Module Subroutine Read_CIF_Temp(cif,T,SigT,i_ini, i_end)
      !---- Arguments ----!
      type(File_Type),    intent(in)  :: cif
      real(kind=cp),      intent(out) :: T
      real(kind=cp),      intent(out) :: SigT
      integer, optional,  intent(in)  :: i_ini, i_end   ! Index to start

      !---- Local Variables ----!
      integer                       :: i,iv
      real(kind=cp),dimension(1)    :: vet1,vet2

      !> Init
      t=298.0_cp; Sigt=1.0_cp

      call clear_error()
      if (cif%nlines <=0) then
         err_CFML%Ierr=1
         err_CFML%Msg="Read_CIF_Temp: 0 lines "
         return
      end if

      j_ini=1; j_end=cif%nlines
      if (present(i_ini)) j_ini=i_ini
      if (present(i_end)) j_end=i_end

      str="_diffrn_ambient_temperature"
      nl=len_trim(str)
      do i=j_ini,j_end
         line=adjustl(cif%line(i)%str)

         if (len_trim(line) <=0) cycle
         if (line(1:1) == '#') cycle

         !> eliminar tabs
         do
            iv=index(line,TAB)
            if (iv == 0) exit
            line(iv:iv)=' '
         end do

         npos=index(line,str)
         if (npos ==0) cycle

         call get_Numstd(line(npos+nl:), vet1, vet2, iv)
         if (iv == 1) then
            t=vet1(1)
            sigt=vet2(1)
            exit
         end if
      end do

   End Subroutine Read_CIF_Temp

   !!----
   !!---- Read_Cif_Hall
   !!----    Obtaining the Hall symbol of the Space Group
   !!----
   !!---- 27/06/2019
   !!
   Module Subroutine Read_CIF_Hall(cif, Hall, i_Ini, i_End)
      !---- Arguments ----!
      type(File_Type),    intent(in)  :: cif
      character(len=*),   intent(out) :: Hall
      integer, optional,  intent(in)  :: i_ini, i_end

      !---- Local variables ----!
      integer           :: i,nl, np1, np2

      !> Init
      Hall=" "
      call clear_error()
      if (cif%nlines <=0) then
         err_CFML%Ierr=1
         err_CFML%Msg="Read_CIF_Hall: 0 lines "
         return
      end if

      j_ini=1; j_end=cif%nlines
      if (present(i_ini)) j_ini=i_ini
      if (present(i_end)) j_end=i_end

      !> First tentative
      str="_space_group_name_Hall"
      nl=len_trim(str)
      do i=j_ini, j_end
         line=adjustl(cif%line(i)%str)

         if (len_trim(line) <=0) cycle
         if (line(1:1) == '#') cycle

         !> eliminar tabs
         do
            iv=index(line,TAB)
            if (iv == 0) exit
            line(iv:iv)=' '
         end do

         npos=index(line,str)
         if (npos ==0) cycle

         hall=adjustl(line(npos+nl:))
         exit
      end do
      if (trim(Hall) =="?" .or. trim(Hall)=="#" .or. trim(Hall)=="''") hall=" "
      if (len_trim(hall) > 0) then
         np1=index(Hall,"'")
         np2=index(Hall,"'",back=.true.)
         if (np1 > 0 .and. np2 > 0 .and. np2 > np1) then
            Hall=Hall(np1+1:np2-1)
         end if
         return
      end if

      !> Second tentative
      str="_symmetry_space_group_name_Hall"
      nl=len_trim(str)
      do i=j_ini, j_end
         line=adjustl(cif%line(i)%str)

         if (len_trim(line) <=0) cycle
         if (line(1:1) == '#') cycle

         !> eliminar tabs
         do
            iv=index(line,TAB)
            if (iv == 0) exit
            line(iv:iv)=' '
         end do

         npos=index(line,str)
         if (npos ==0) cycle

         hall=adjustl(line(npos+nl:))
         exit
      end do
      if (trim(Hall) =="?" .or. trim(Hall)=="#" .or. trim(Hall)=="''") hall=" "
      if (len_trim(hall) > 0) then
         np1=index(Hall,"'")
         np2=index(Hall,"'",back=.true.)
         if (np1 > 0 .and. np2 > 0 .and. np2 > np1) then
            Hall=Hall(np1+1:np2-1)
         end if
      end if

   End Subroutine Read_CIF_Hall

   !!----
   !!---- READ_CIF_HM
   !!----    Obtaining the Herman-Mauguin symbol of Space Group
   !!----
   !!---- 27/06/2019
   !!
   Module Subroutine Read_CIF_HM(cif, Spgr_Hm, i_ini, i_end)
      !---- Arguments ----!
      type(File_Type),    intent(in)  :: cif
      character(len=*),   intent(out) :: spgr_hm
      integer, optional,  intent(in)  :: i_ini,i_end

      !---- Local variables ----!
      character(len=1) :: csym, csym2
      integer          :: i,nl,np1, np2

      !> Init
      spgr_hm=" "
      call clear_error()
      if (cif%nlines <=0) then
         err_CFML%Ierr=1
         err_CFML%Msg="Read_CIF_HM: 0 lines "
         return
      end if

      j_ini=1; j_end=cif%nlines
      if (present(i_ini)) j_ini=i_ini
      if (present(i_end)) j_end=i_end

      !> First tentative
      str="_space_group_name_H-M_alt"
      nl=len_trim(str)
      do i=j_ini, j_end
         line=adjustl(cif%line(i)%str)

         if (len_trim(line) <=0) cycle
         if (line(1:1) == '#') cycle

         !> eliminar tabs
         do
            iv=index(line,TAB)
            if (iv == 0) exit
            line(iv:iv)=' '
         end do

         npos=index(line,str)
         if (npos ==0) cycle

         spgr_hm=adjustl(line(npos+nl:))
         exit
      end do
      if (trim(spgr_hm) =="?" .or. trim(spgr_hm)=="#" .or. trim(spgr_hm)=="''") spgr_hm=" "
      if (len_trim(spgr_hm) > 0) then
         np1=index(spgr_hm,"'")
         np2=index(spgr_hm,"'",back=.true.)
         if (np1 > 0 .and. np2 > 0 .and. np2 > np1) then
            spgr_hm=spgr_hm(np1+1:np2-1)
         end if
      end if

      !> Adapting Nomenclature from ICSD to our model
      np1=len_trim(spgr_hm)
      if (np1 > 0) then
         csym=u_case(spgr_hm(np1:np1))
         select case (csym)
            case("1")
               csym2=u_case(spgr_hm(np1-1:np1-1))
               if (csym2 == "Z" .or. csym2 =="S") then
                  spgr_hm=spgr_hm(:np1-2)//":1"
               end if

            case("S","Z")
               csym2=u_case(spgr_hm(np1-1:np1-1))
               select case (csym2)
                  case ("H")
                     spgr_hm=spgr_hm(:np1-2)
                  case ("R")
                     spgr_hm=spgr_hm(:np1-2)//":R"
                  case default
                     spgr_hm=spgr_hm(:np1-1)
               end select

            case("R")
               csym2=u_case(spgr_hm(np1-1:np1-1))
               if (csym2 == "H" ) then
                  spgr_hm=spgr_hm(:np1-2)
               else
                  spgr_hm=spgr_hm(:np1-1)//":R"
               end if

            case("H")
               spgr_hm=spgr_hm(:np1-1)
               csym2=u_case(spgr_hm(np1-1:np1-1))
               if(csym2 == ":") spgr_hm=spgr_hm(:np1-2)
         end select
      end if
      if (len_trim(spgr_hm) > 0) return

      !> Second tentative
      str="_symmetry_space_group_name_H-M"
      nl=len_trim(str)
      do i=j_ini, j_end
         line=adjustl(cif%line(i)%str)

         if (len_trim(line) <=0) cycle
         if (line(1:1) == '#') cycle

         !> eliminar tabs
         do
            iv=index(line,TAB)
            if (iv == 0) exit
            line(iv:iv)=' '
         end do

         npos=index(line,str)
         if (npos ==0) cycle

         spgr_hm=adjustl(line(npos+nl:))
         exit
      end do
      if (trim(spgr_hm) =="?" .or. trim(spgr_hm)=="#" .or. trim(spgr_hm)=="''") spgr_hm=" "
      if (len_trim(spgr_hm) > 0) then
         np1=index(spgr_hm,"'")
         np2=index(spgr_hm,"'",back=.true.)
         if (np1 > 0 .and. np2 > 0 .and. np2 > np1) then
            spgr_hm=spgr_hm(np1+1:np2-1)
         end if
      end if

      !> Adapting Nomenclature from ICSD to our model
      np1=len_trim(spgr_hm)
      if (np1 > 0) then
         csym=u_case(spgr_hm(np1:np1))
         select case (csym)
            case("1")
               csym2=u_case(spgr_hm(np1-1:np1-1))
               if (csym2 == "Z" .or. csym2 =="S") then
                  spgr_hm=spgr_hm(:np1-2)//":1"
               end if

            case("S","Z")
               csym2=u_case(spgr_hm(np1-1:np1-1))
               select case (csym2)
                  case ("H")
                     spgr_hm=spgr_hm(:np1-2)
                  case ("R")
                     spgr_hm=spgr_hm(:np1-2)//":R"
                  case default
                     spgr_hm=spgr_hm(:np1-1)
               end select

            case("R")
               csym2=u_case(spgr_hm(np1-1:np1-1))
               if (csym2 == "H" ) then
                  spgr_hm=spgr_hm(:np1-2)
               else
                  spgr_hm=spgr_hm(:np1-1)//":R"
               end if
            case("H")
               spgr_hm=spgr_hm(:np1-1)
               csym2=u_case(spgr_hm(np1-1:np1-1))
               if(csym2 == ":") spgr_hm=spgr_hm(:np1-2)
         end select
      end if

   End Subroutine Read_CIF_HM

   !!----
   !!---- Read_Cif_Symm
   !!----    Obtaining Symmetry Operators from Cif file
   !!----
   !!---- 27/06/2019
   !!
   Module Subroutine Read_CIF_Symm(cif, N_Oper, Oper_Symm,i_ini,i_end)
      !---- Arguments ----!
      type(File_Type),    intent(in)              :: cif
      integer,                        intent(out) :: n_oper
      character(len=*), dimension(:), intent(out) :: oper_symm
      integer, optional,              intent(in)  :: i_ini, i_end

      !---- Local variables ----!
      integer            :: i,j,nl,np1,np2

      !> Init
      n_oper=0
      oper_symm=" "
      call clear_error()

      j_ini=1; j_end=cif%nlines
      if (present(i_ini)) j_ini=i_ini
      if (present(i_end)) j_end=i_end

      !> First tentative
      str="_space_group_symop_operation_xyz"
      nl=len_trim(str)
      do i=j_ini, j_end
         line=adjustl(cif%line(i)%str)

         if (len_trim(line) <=0) cycle
         if (line(1:1) == '#') cycle

         !> eliminar tabs
         do
            iv=index(line,TAB)
            if (iv == 0) exit
            line(iv:iv)=' '
         end do

         npos=index(line,str)
         if (npos ==0) cycle

         do j=i+1,j_end
            line=adjustl(cif%line(j)%str)
            if (len_trim(line) <=0) exit
            if (line(1:1) == '_') exit
            if (line(1:1) == '#') cycle

            np1=index(line,"'")
            np2=index(line,"'",back=.true.)
            if (np1 > 0 .and. np2 > 0 .and. np2 > np1) then
               n_oper=n_oper+1
               oper_symm(n_oper)=line(np1+1:np2-1)
            end if
         end do
         exit
      end do
      if (n_oper > 0) return

      !> Second tentative
      str="_symmetry_equiv_pos_as_xyz"
      nl=len_trim(str)
      do i=j_ini, j_end
         line=adjustl(cif%line(i)%str)

         if (len_trim(line) <=0) cycle
         if (line(1:1) == '#') cycle

         !> eliminar tabs
         do
            iv=index(line,TAB)
            if (iv == 0) exit
            line(iv:iv)=' '
         end do

         npos=index(line,str)
         if (npos ==0) cycle

         do j=i+1,j_end
            line=adjustl(cif%line(j)%str)
            if (len_trim(line) <=0) exit
            if (line(1:1) == '_') exit
            if (line(1:1) == '#') cycle

            np1=index(line,"'")
            np2=index(line,"'",back=.true.)
            if (np1 > 0 .and. np2 > 0 .and. np2 > np1) then
               n_oper=n_oper+1
               oper_symm(n_oper)=line(np1+1:np2-1)
            end if
         end do
         exit
      end do

   End Subroutine Read_CIF_Symm

   !!----
   !!---- WRITE_CIF_POWDER_PROFILE
   !!----
   !!----    Write a Cif Powder Profile file (converted from FullProf)
   !!----
   !!---- Update: January - 2020
   !!
   Module Subroutine Write_CIF_Powder_Profile(filename,Pat,r_facts)
      !---- Arguments ----!
      character(len=*),                      intent(in) :: filename   ! Name of file
      class(DiffPat_Type),                   intent(in) :: Pat        ! Pattern
      real(kind=cp), dimension(4), optional, intent(in) :: r_facts    ! R_patt,R_wpatt,R_exp, Chi2

      !---- Local Variables ----!
      logical             :: info
      character(len=8)    :: date,time
      character(len=30)   :: comm
      integer             :: iunit
      integer             :: i,j,n
      real(kind=cp)       :: an, R_patt,R_wpatt,R_exp, Chi2

      !> Inicialization of variables
      R_Patt=0.0; R_WPatt=0.0; R_Exp=0.0; Chi2=0.0
      if (present(r_facts)) then
         R_patt = r_facts(1)
         R_wpatt= r_facts(2)
         R_exp  = r_facts(3)
         Chi2   = r_facts(4)
      end if

      !> Is this file opened?
      info=.false.
      inquire(file=trim(filename),opened=info)
      if (info) then
         inquire(file=trim(filename),number=iunit)
         close(unit=iunit)
         open(unit=iunit,file=trim(filename),status="unknown",action="write",position="append")
      else
         open(newunit=iunit,file=trim(filename),status="unknown",action="write")
      end if

      !> Writing

      !> Head
      call Date_and_Time(date, time)
      write(unit=iunit,fmt='(a)')    " "
      write(unit=iunit,fmt='(a)')    "#==========================="
      write(unit=iunit,fmt='(a,i3)') "# Powder diffraction pattern "
      write(unit=iunit,fmt='(a)')    "#==========================="
      write(unit=iunit,fmt='(a)')    "#  "//date(7:8)//'/'//date(5:6)//'/'//date(3:4)
      write(unit=iunit,fmt='(a)')    " "

      write(iunit,'(a)') "data_profile"
      write(unit=iunit,fmt="(a)")"_audit_creation_date "//date(3:)//' '//time(:6)
      write(unit=iunit,fmt="(a)")'_audit_creation_method  "CrysFML"'
      write(unit=iunit,fmt='(a)') " "
      write(unit=iunit,fmt='(a)') "_pd_block_id      ?"

      write(iunit,'(a)')"#==============================================================================             "
      write(unit=iunit,fmt='(a)')"# 9. INSTRUMENT CHARACTERIZATION                                                            "
      write(unit=iunit,fmt='(a)')"                                                                                            "
      write(unit=iunit,fmt='(a)')"_exptl_special_details                                                                      "
      write(unit=iunit,fmt='(a)')"; ?                                                                                         "
      write(unit=iunit,fmt='(a)')";                                                                                           "
      write(unit=iunit,fmt='(a)')"                                                                                            "
      write(unit=iunit,fmt='(a)')"# if regions of the data are excluded, the reason(s) are supplied here:                     "
      write(unit=iunit,fmt='(a)')"_pd_proc_info_excluded_regions                                                              "
      write(unit=iunit,fmt='(a)')"; ?                                                                                         "
      write(unit=iunit,fmt='(a)')";                                                                                           "
      write(unit=iunit,fmt='(a)')"                                                                                            "
      write(unit=iunit,fmt='(a)')"# The following item is used to identify the equipment used to record                       "
      write(unit=iunit,fmt='(a)')"# the powder pattern when the diffractogram was measured at a laboratory                    "
      write(unit=iunit,fmt='(a)')"# other than the authors' home institution, e.g. when neutron or synchrotron                "
      write(unit=iunit,fmt='(a)')"# radiation is used.                                                                        "
      write(unit=iunit,fmt='(a)')"                                                                                            "
      write(unit=iunit,fmt='(a)')"_pd_instr_location                                                                          "
      write(unit=iunit,fmt='(a)')"; ?                                                                                         "
      write(unit=iunit,fmt='(a)')";                                                                                           "
      write(unit=iunit,fmt='(a)')"_pd_calibration_special_details           # description of the method used                  "
      write(unit=iunit,fmt='(a)')"                                          # to calibrate the instrument                     "
      write(unit=iunit,fmt='(a)')"; ?                                                                                         "
      write(unit=iunit,fmt='(a)')";                                                                                           "
      write(unit=iunit,fmt='(a)')"                                                                                            "
      write(unit=iunit,fmt='(a)')"_diffrn_ambient_temperature    ?                                                            "
      write(unit=iunit,fmt='(a)')"_diffrn_source                 ?                                                            "
      write(unit=iunit,fmt='(a)')"_diffrn_source_target          ?                                                            "
      write(unit=iunit,fmt='(a)')"_diffrn_source_type            ?                                                            "
      write(unit=iunit,fmt='(a)')"_diffrn_measurement_device_type?                                                            "
      write(unit=iunit,fmt='(a)')"_diffrn_detector               ?                                                            "
      write(unit=iunit,fmt='(a)')"_diffrn_detector_type          ?  # make or model of detector                               "
      write(unit=iunit,fmt='(a)')"                                                                                            "
      write(unit=iunit,fmt='(a)')"_pd_meas_scan_method           ?  # options are 'step', 'cont',                             "
      write(unit=iunit,fmt='(a)')"                                  # 'tof', 'fixed' or                                       "
      write(unit=iunit,fmt='(a)')"                                  # 'disp' (= dispersive)                                   "
      write(unit=iunit,fmt='(a)')"_pd_meas_special_details                                                                    "
      write(unit=iunit,fmt='(a)')";  ?                                                                                        "
      write(unit=iunit,fmt='(a)')";                                                                                           "
      write(unit=iunit,fmt='(a)')"                                                                                            "
      write(unit=iunit,fmt='(a)')"# The following two items identify the program(s) used (if appropriate).                    "
      write(unit=iunit,fmt='(a)')"_computing_data_collection        ?                                                         "
      write(unit=iunit,fmt='(a)')"_computing_data_reduction         ?                                                         "
      write(unit=iunit,fmt='(a)')"                                                                                            "
      write(unit=iunit,fmt='(a)')"# Describe any processing performed on the data, prior to refinement.                       "
      write(unit=iunit,fmt='(a)')"# For example: a manual Lp correction or a precomputed absorption correction                "
      write(unit=iunit,fmt='(a)')"_pd_proc_info_data_reduction      ?                                                         "
      write(unit=iunit,fmt='(a)')"                                                                                            "
      write(unit=iunit,fmt='(a)')"# The following item is used for angular dispersive measurements only.                      "
      write(unit=iunit,fmt='(a)')"                                                                                            "
      write(unit=iunit,fmt='(a)')"_diffrn_radiation_monochromator   ?                                                         "
      write(unit=iunit,fmt='(a)')"                                                                                            "
      write(unit=iunit,fmt='(a)')"# The following items are used to define the size of the instrument.                        "
      write(unit=iunit,fmt='(a)')"# Not all distances are appropriate for all instrument types.                               "
      write(unit=iunit,fmt='(a)')"                                                                                            "
      write(unit=iunit,fmt='(a)')"_pd_instr_dist_src/mono           ?                                                         "
      write(unit=iunit,fmt='(a)')"_pd_instr_dist_mono/spec          ?                                                         "
      write(unit=iunit,fmt='(a)')"_pd_instr_dist_src/spec           ?                                                         "
      write(unit=iunit,fmt='(a)')"_pd_instr_dist_spec/anal          ?                                                         "
      write(unit=iunit,fmt='(a)')"_pd_instr_dist_anal/detc          ?                                                         "
      write(unit=iunit,fmt='(a)')"_pd_instr_dist_spec/detc          ?                                                         "
      write(unit=iunit,fmt='(a)')"                                                                                            "
      write(unit=iunit,fmt='(a)')"# 10. Specimen size and mounting information                                                "
      write(unit=iunit,fmt='(a)')"                                                                                            "
      write(unit=iunit,fmt='(a)')"# The next three fields give the specimen dimensions in mm.  The equatorial                 "
      write(unit=iunit,fmt='(a)')"# plane contains the incident and diffracted beam.                                          "
      write(unit=iunit,fmt='(a)')"                                                                                            "
      write(unit=iunit,fmt='(a)')"_pd_spec_size_axial               ?       # perpendicular to                                "
      write(unit=iunit,fmt='(a)')"                                          # equatorial plane                                "
      write(unit=iunit,fmt='(a)')"                                                                                            "
      write(unit=iunit,fmt='(a)')"_pd_spec_size_equat               ?       # parallel to                                     "
      write(unit=iunit,fmt='(a)')"                                          # scattering vector                               "
      write(unit=iunit,fmt='(a)')"                                          # in transmission                                 "
      write(unit=iunit,fmt='(a)')"                                                                                            "
      write(unit=iunit,fmt='(a)')"_pd_spec_size_thick               ?       # parallel to                                     "
      write(unit=iunit,fmt='(a)')"                                          # scattering vector                               "
      write(unit=iunit,fmt='(a)')"                                          # in reflection                                   "
      write(unit=iunit,fmt='(a)')"                                                                                            "
      write(unit=iunit,fmt='(a)')"_pd_spec_mounting                         # This field should be                            "
      write(unit=iunit,fmt='(a)')"                                          # used to give details of the                     "
      write(unit=iunit,fmt='(a)')"                                          # container.                                      "
      write(unit=iunit,fmt='(a)')"; ?                                                                                         "
      write(unit=iunit,fmt='(a)')";                                                                                           "
      write(unit=iunit,fmt='(a)')"                                                                                            "
      write(unit=iunit,fmt='(a)')"_pd_spec_mount_mode               ?       # options are 'reflection'                        "
      write(unit=iunit,fmt='(a)')"                                          # or 'transmission'                               "
      write(unit=iunit,fmt='(a)')"                                                                                            "
      write(unit=iunit,fmt='(a)')"_pd_spec_shape                    ?       # options are 'cylinder'                          "
      write(unit=iunit,fmt='(a)')"                                          # 'flat_sheet' or 'irregular'                     "
      write(unit=iunit,fmt='(a)')"                                                                                            "
      write(unit=iunit,fmt='(a)')"     "
      write(unit=iunit,fmt='(a)')"_diffrn_radiation_probe   "//trim(pat%KindRad)

      if (trim(l_case(Pat%scatvar))=="2theta") then
         write(unit=iunit,fmt='(a,f12.6)') "_diffrn_radiation_wavelength ",Pat%wave(1)
      end if

      if (present(r_facts)) then
         write(unit=iunit,fmt='(a)')"     "
         write(unit=iunit,fmt='(a)') "#  The following profile R-factors are NOT CORRECTED for background"
         write(unit=iunit,fmt='(a)') "#  The sum is extended to all non-excluded points."
         write(unit=iunit,fmt='(a)') "#  These are the current CIF standard"
         write(unit=iunit,fmt='(a)') " "
         write(unit=iunit,fmt='(a,f12.4)') "_pd_proc_ls_prof_R_factor          ",R_patt
         write(unit=iunit,fmt='(a,f12.4)') "_pd_proc_ls_prof_wR_factor         ",R_wpatt
         write(unit=iunit,fmt='(a,f12.4)') "_pd_proc_ls_prof_wR_expected       ",R_exp
         write(unit=iunit,fmt='(a,f12.4)') "_pd_proc_ls_prof_chi2              ",chi2
      end if

      write(unit=iunit,fmt='(a)')"  "
      write(unit=iunit,fmt='(a)')"_pd_proc_ls_background_function   "
      write(unit=iunit,fmt='(a)')";   Background function description  "
      write(unit=iunit,fmt='(a)')";                                                                              "
      write(unit=iunit,fmt='(a)')"                                                                               "
      write(unit=iunit,fmt='(a)')"_exptl_absorpt_process_details                                                 "
      write(unit=iunit,fmt='(a)')";   Absorption/surface roughness correction description    "
      write(unit=iunit,fmt='(a)')" No correction is applied ?.                                                   "
      write(unit=iunit,fmt='(a)')";                                                                              "
      write(unit=iunit,fmt='(a)')"                                                                               "
      write(unit=iunit,fmt='(a)')"_pd_proc_ls_profile_function                                                   "
      write(unit=iunit,fmt='(a)')";   Profile function description                                              "
      write(unit=iunit,fmt='(a)')";                                                                              "
      write(unit=iunit,fmt='(a)')"_pd_proc_ls_peak_cutoff 0.00500                                                "
      write(unit=iunit,fmt='(a,a)')'_pd_calc_method  "   Rietveld Refinement" '
      write(unit=iunit,fmt='(a)')"                                                                               "
      write(unit=iunit,fmt='(a)')"#---- raw/calc data loop -----   "

      select case (trim(l_case(Pat%scatvar)))
         case ("2theta")   ! 2_Theta
              write(unit=iunit,fmt='(a,f14.6)')"_pd_meas_2theta_range_min " , Pat%xmin
              write(unit=iunit,fmt='(a,f14.6)')"_pd_meas_2theta_range_max " , Pat%xmax
              if (Pat%NPts > 1) then
                 write(unit=iunit,fmt='(a,f14.6)')"_pd_meas_2theta_range_inc " , (Pat%xmax-Pat%xmin)/real(Pat%Npts)
              end if

          case ("tof")   ! T.O.F.
            write(unit=iunit,fmt='(a)') "_pd_proc_d_spacing "
      end select


      !> Profile
      write(unit=iunit,fmt='(a)') " "

      write(unit=iunit,fmt='(a)') "loop_"
      write(unit=iunit,fmt='(a)') "_pd_proc_point_id"
      select case (trim(l_case(Pat%scatvar)))
         case ("2theta")   !
            write(unit=iunit,fmt='(a)') "_pd_proc_2theta_corrected   "
         case ("tof")   ! T.O.F.
            write(unit=iunit,fmt='(a)') "_pd_proc_d_spacing "
         case ("energy")   ! Energy
            write(unit=iunit,fmt='(a)') "_pd_proc_energy_incident  "
      end select
      write(unit=iunit,fmt='(a)') "_pd_proc_intensity_total"
      write(unit=iunit,fmt='(a)') "_pd_calc_intensity_total"
      write(unit=iunit,fmt='(a)') "_pd_proc_intensity_bkg_calc"
      write(unit=iunit,fmt='(a)') " "

      select type (Pat)
         class is (DiffPat_E_Type)
             n=0
             do_poi: do i=1,Pat%Npts
                if (Pat%istat(i) == 0) cycle
                an=Pat%x(i)
                line=" "
                write(unit=line(1:6),fmt='(i6)') i
                n=n+1
                select case (trim(l_case(Pat%scatvar)))
                   case ("2theta")   ! 2_Theta
                      !write(unit=line(10:),fmt='(f8.4,5x,a)') an-Pat%zerop,'.    .'
                      write(unit=line(10:),fmt='(f8.4,5x,a)') an,'.    .'
                   case ("tof")   ! T.O.F.
                      !write(line(10:),'(f8.4,5x,a)') (an-Pat%zerop)/pat%conv(1),'.    .'  !dtt1
                      write(unit=line(10:),fmt='(f8.4,5x,a)') an/pat%wave(3),'.    .'  !dtt1
                   case ("energy")   ! Energy
                      !write(line(10:),'(a,f15.4,2x,a)') '. ',1000.0*(an-Pat%zerop),'.'
                      write(unit=line(10:),fmt='(a,f15.4,2x,a)') '. ',1000.0*an,'.'
                end select
                comm=string_NumStd(Pat%y(i),sqrt(Pat%sigma(i)))
                write(unit=line(21:),fmt='(a,2f18.4)') trim(comm)//" ", Pat%ycalc(i),Pat%bgr(i)
                write(unit=iunit,fmt='(a)') line
             end do do_poi
         write(unit=iunit,fmt='(a,i7)')  "_pd_proc_number_of_points",n
         write(unit=iunit,fmt='(a)') " "
      end select

      write(unit=iunit,fmt='(a)') " "
      write(unit=iunit,fmt='(a)') "# The following lines are used to test the character set of files sent by     "
      write(unit=iunit,fmt='(a)') "# network email or other means. They are not part of the CIF data set.        "
      write(unit=iunit,fmt='(a)') "# abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789              "
      write(unit=iunit,fmt='(a)') "# !@#$%^&*()_+{}:""~<>?|\-=[];'`,./ "

   End Subroutine Write_CIF_Powder_Profile

   !!----
   !!---- Write_Cif_Template
   !!----    Write a Cif File
   !!----
   !!---- 28/06/2019
   !!
   Module Subroutine Write_CIF_Template(filename, Cell, SpG, Atmlist, Type_data, Code)
      !---- Arguments ----!
      character(len=*),        intent(in) :: filename     ! Filename
      class(Cell_G_Type),      intent(in) :: Cell         ! Cell parameters
      class(SpG_Type),         intent(in) :: SpG          ! Space group information
      Type(AtList_Type),       intent(in) :: AtmList      ! Atoms
      integer,                 intent(in) :: Type_data    ! 0,2:Single crystal diffraction; 1:Powder
      character(len=*),        intent(in) :: Code         ! Code or name of the structure

      !---- Local Variables ----!
      logical                                 :: info, aniso
      character(len=1), parameter             :: QMARK='?'
      character(len=30)                       :: comm,adptyp
      character(len=30),dimension(6)          :: text
      real(kind=cp)                           :: u, su, ocf,rval
      real(kind=cp), dimension(6)             :: Ua,sua,aux
      real(kind=cp), dimension(AtmList%Natoms):: occup,soccup
      integer                                 :: iunit,i, j

      !> Init
      info=.false.
      iunit=0

      !> Is this file opened?
      inquire(file=trim(filename),opened=info)
      if (info) then
         inquire(file=trim(filename),number=iunit)
         close(unit=iunit)
      end if

      !> Writing
      open(newunit=iunit, file=trim(filename),status="unknown",action="write")
      rewind(unit=iunit)

      !> Head Information
      select case (type_data)
         case (0:1)
            write(unit=iunit,fmt="(a)") "##############################################################################"
            write(unit=iunit,fmt="(a)") "###    CIF submission form for molecular structure report (Acta Cryst. C)  ###"
            write(unit=iunit,fmt="(a)") "##############################################################################"
            write(unit=iunit,fmt="(a)") " "
            write(unit=iunit,fmt="(a)") "#============================================================================="
            write(unit=iunit,fmt="(a)") "data_global"
            write(unit=iunit,fmt="(a)") "#============================================================================="
            write(unit=iunit,fmt="(a)") " "

         case (2:)
            write(unit=iunit,fmt="(a)") "##################################################################"
            write(unit=iunit,fmt="(a)") "###    CIF file from CrysFML, contains only structural data    ###"
            write(unit=iunit,fmt="(a)") "##################################################################"
      end select

      !> Processing Summary
      if (type_data < 2) then
         write(unit=iunit,fmt="(a)") "# PROCESSING SUMMARY (IUCr Office Use Only)"

         write(unit=iunit,fmt="(a)") " "
         write(unit=iunit,fmt="(a)") "_journal_data_validation_number      ?"

         write(unit=iunit,fmt="(a)") " "
         write(unit=iunit,fmt="(a)") "_journal_date_recd_electronic        ?"
         write(unit=iunit,fmt="(a)") "_journal_date_to_coeditor            ?"
         write(unit=iunit,fmt="(a)") "_journal_date_from_coeditor          ?"
         write(unit=iunit,fmt="(a)") "_journal_date_accepted               ?"
         write(unit=iunit,fmt="(a)") "_journal_date_printers_first         ?"
         write(unit=iunit,fmt="(a)") "_journal_date_printers_final         ?"
         write(unit=iunit,fmt="(a)") "_journal_date_proofs_out             ?"
         write(unit=iunit,fmt="(a)") "_journal_date_proofs_in              ?"
         write(unit=iunit,fmt="(a)") "_journal_coeditor_name               ?"
         write(unit=iunit,fmt="(a)") "_journal_coeditor_code               ?"
         write(unit=iunit,fmt="(a)") "_journal_coeditor_notes"
         write(unit=iunit,fmt="(a)") "; ?"
         write(unit=iunit,fmt="(a)") ";"
         write(unit=iunit,fmt="(a)") "_journal_techeditor_code             ?"
         write(unit=iunit,fmt="(a)") "_journal_techeditor_notes"
         write(unit=iunit,fmt="(a)") "; ?"
         write(unit=iunit,fmt="(a)") ";"
         write(unit=iunit,fmt="(a)") "_journal_coden_ASTM                  ?"
         write(unit=iunit,fmt="(a)") "_journal_name_full                   ?"
         write(unit=iunit,fmt="(a)") "_journal_year                        ?"
         write(unit=iunit,fmt="(a)") "_journal_volume                      ?"
         write(unit=iunit,fmt="(a)") "_journal_issue                       ?"
         write(unit=iunit,fmt="(a)") "_journal_page_first                  ?"
         write(unit=iunit,fmt="(a)") "_journal_page_last                   ?"
         write(unit=iunit,fmt="(a)") "_journal_paper_category              ?"
         write(unit=iunit,fmt="(a)") "_journal_suppl_publ_number           ?"
         write(unit=iunit,fmt="(a)") "_journal_suppl_publ_pages            ?"

         write(unit=iunit,fmt="(a)") " "
         write(unit=iunit,fmt="(a)") "#============================================================================="
         write(unit=iunit,fmt="(a)") " "

         !> Submission details
         write(unit=iunit,fmt="(a)") "# 1. SUBMISSION DETAILS"
         write(unit=iunit,fmt="(a)") " "

         write(unit=iunit,fmt="(a)") "_publ_contact_author_name            ?   # Name of author for correspondence"
         write(unit=iunit,fmt="(a)") "_publ_contact_author_address             # Address of author for correspondence"
         write(unit=iunit,fmt="(a)") "; ?"
         write(unit=iunit,fmt="(a)") ";"
         write(unit=iunit,fmt="(a)") "_publ_contact_author_email           ?"
         write(unit=iunit,fmt="(a)") "_publ_contact_author_fax             ?"
         write(unit=iunit,fmt="(a)") "_publ_contact_author_phone           ?"

         write(unit=iunit,fmt="(a)") " "
         write(unit=iunit,fmt="(a)") "_publ_contact_letter"
         write(unit=iunit,fmt="(a)") "; ?"
         write(unit=iunit,fmt="(a)") ";"

         write(unit=iunit,fmt="(a)") " "
         write(unit=iunit,fmt="(a)") "_publ_requested_journal              ?"
         write(unit=iunit,fmt="(a)") "_publ_requested_coeditor_name        ?"
         write(unit=iunit,fmt="(a)") "_publ_requested_category             ?   # Acta C: one of CI/CM/CO/FI/FM/FO"

         write(unit=iunit,fmt="(a)") "#=============================================================================="
         write(unit=iunit,fmt="(a)") " "

         !> Title  and Author List
         write(unit=iunit,fmt="(a)") "# 3. TITLE AND AUTHOR LIST"

         write(unit=iunit,fmt="(a)") " "
         write(unit=iunit,fmt="(a)") "_publ_section_title"
         write(unit=iunit,fmt="(a)") "; ?"
         write(unit=iunit,fmt="(a)") ";"
         write(unit=iunit,fmt="(a)") "_publ_section_title_footnote"
         write(unit=iunit,fmt="(a)") ";"
         write(unit=iunit,fmt="(a)") ";"

         write(unit=iunit,fmt="(a)") " "
         write(unit=iunit,fmt="(a)") "# The loop structure below should contain the names and addresses of all "
         write(unit=iunit,fmt="(a)") "# authors, in the required order of publication. Repeat as necessary."

         write(unit=iunit,fmt="(a)") " "
         write(unit=iunit,fmt="(a)") "loop_"
         write(unit=iunit,fmt="(a)") "    _publ_author_name"
         write(unit=iunit,fmt="(a)") "    _publ_author_footnote"
         write(unit=iunit,fmt="(a)") "    _publ_author_address"
         write(unit=iunit,fmt="(a)") "?                                   #<--'Last name, first name' "
         write(unit=iunit,fmt="(a)") "; ?"
         write(unit=iunit,fmt="(a)") ";"
         write(unit=iunit,fmt="(a)") "; ?"
         write(unit=iunit,fmt="(a)") ";"

         write(unit=iunit,fmt="(a)") " "
         write(unit=iunit,fmt="(a)") "#============================================================================="
         write(unit=iunit,fmt="(a)") " "

         !> Text
         write(unit=iunit,fmt="(a)") "# 4. TEXT"

         write(unit=iunit,fmt="(a)") " "
         write(unit=iunit,fmt="(a)") "_publ_section_synopsis"
         write(unit=iunit,fmt="(a)") ";  ?"
         write(unit=iunit,fmt="(a)") ";"
         write(unit=iunit,fmt="(a)") "_publ_section_abstract"
         write(unit=iunit,fmt="(a)") "; ?"
         write(unit=iunit,fmt="(a)") ";          "
         write(unit=iunit,fmt="(a)") "_publ_section_comment"
         write(unit=iunit,fmt="(a)") "; ?"
         write(unit=iunit,fmt="(a)") ";"
         write(unit=iunit,fmt="(a)") "_publ_section_exptl_prep      # Details of the preparation of the sample(s)"
         write(unit=iunit,fmt="(a)") "                              # should be given here. "
         write(unit=iunit,fmt="(a)") "; ?"
         write(unit=iunit,fmt="(a)") ";"
         write(unit=iunit,fmt="(a)") "_publ_section_exptl_refinement"
         write(unit=iunit,fmt="(a)") "; ?"
         write(unit=iunit,fmt="(a)") ";"
         write(unit=iunit,fmt="(a)") "_publ_section_references"
         write(unit=iunit,fmt="(a)") "; ?"
         write(unit=iunit,fmt="(a)") ";"
         write(unit=iunit,fmt="(a)") "_publ_section_figure_captions"
         write(unit=iunit,fmt="(a)") "; ?"
         write(unit=iunit,fmt="(a)") ";"
         write(unit=iunit,fmt="(a)") "_publ_section_acknowledgements"
         write(unit=iunit,fmt="(a)") "; ?"
         write(unit=iunit,fmt="(a)") ";"

         write(unit=iunit,fmt="(a)") " "
         write(unit=iunit,fmt="(a)") "#============================================================================="
         write(unit=iunit,fmt="(a)") " "

         !> Identifier
         write(unit=iunit,fmt="(a)") "#============================================================================="
         write(unit=iunit,fmt="(a)") "# If more than one structure is reported, the remaining sections should be "
         write(unit=iunit,fmt="(a)") "# completed per structure. For each data set, replace the '?' in the"
         write(unit=iunit,fmt="(a)") "# data_? line below by a unique identifier."
      end if !type_data < 2
      write(unit=iunit,fmt="(a)") " "

      if (len_trim(code) == 0) then
         write(unit=iunit,fmt="(a)") "data_?"
      else
         write(unit=iunit,fmt="(a)") "data_"//code(1:len_trim(code))
      end if
      write(unit=iunit,fmt="(a)") " "

      if (type_data < 2) then
         write(unit=iunit,fmt="(a)") " "
         write(unit=iunit,fmt="(a)") "#============================================================================="
         write(unit=iunit,fmt="(a)") " "

         !> Chemical Data
         write(unit=iunit,fmt="(a)") "# 5. CHEMICAL DATA"

         write(unit=iunit,fmt="(a)") " "
         write(unit=iunit,fmt="(a)") "_chemical_name_systematic"
         write(unit=iunit,fmt="(a)") "; ?"
         write(unit=iunit,fmt="(a)") ";"
         write(unit=iunit,fmt="(a)") "_chemical_name_common             ?"
         write(unit=iunit,fmt="(a)") "_chemical_formula_moiety          ?"
         write(unit=iunit,fmt="(a)") "_chemical_formula_structural      ?"
         write(unit=iunit,fmt="(a)") "_chemical_formula_analytical      ?"
         write(unit=iunit,fmt="(a)") "_chemical_formula_iupac           ?"
         write(unit=iunit,fmt="(a)") "_chemical_formula_sum             ?"
         write(unit=iunit,fmt="(a)") "_chemical_formula_weight          ?"
         write(unit=iunit,fmt="(a)") "_chemical_melting_point           ?"
         write(unit=iunit,fmt="(a)") "_chemical_compound_source         ?       # for minerals and "
         write(unit=iunit,fmt="(a)") "                                          # natural products"

         write(unit=iunit,fmt="(a)") " "
         write(unit=iunit,fmt="(a)") "loop_"
         write(unit=iunit,fmt="(a)") "    _atom_type_symbol               "
         write(unit=iunit,fmt="(a)") "    _atom_type_description          "
         write(unit=iunit,fmt="(a)") "    _atom_type_scat_dispersion_real "
         write(unit=iunit,fmt="(a)") "    _atom_type_scat_dispersion_imag "
         write(unit=iunit,fmt="(a)") "    _atom_type_scat_source          "
         write(unit=iunit,fmt="(a)") "    _atom_type_scat_length_neutron       # include if applicable"
         write(unit=iunit,fmt="(a)") "    ?    ?    ?    ?    ?      ?    "
      end if !type_data < 2
      write(unit=iunit,fmt="(a)") " "
      write(unit=iunit,fmt="(a)") "#============================================================================="
      write(unit=iunit,fmt="(a)") " "

      !> Crystal Data
      select case (type_data)
         case (0,2) ! Single Crystal or structural data only
            write(unit=iunit,fmt="(a)") "# 6. CRYSTAL DATA"
         case (1) ! Powder Data + Crystal Data
            write(unit=iunit,fmt="(a)") "# 6. POWDER SPECIMEN AND CRYSTAL DATA"
      end select
      write(unit=iunit,fmt="(a)") " "

      write(unit=iunit,fmt="(a)") "_symmetry_cell_setting               ?"
      line=SpG%SPG_Symb
      write(unit=iunit,fmt="(a)") "_symmetry_space_group_name_H-M       '"//trim(line)//"'"
      line=SpG%Hall
      write(unit=iunit,fmt="(a)") "_symmetry_space_group_name_Hall      '"//trim(line)//"'"

      write(unit=iunit,fmt="(a)") " "
      write(unit=iunit,fmt="(a)") "loop_"
      write(unit=iunit,fmt="(a)") "    _symmetry_equiv_pos_as_xyz"
      do i=1,SpG%multip
         line="'"//trim(SpG%Symb_Op(i))//"'"
         write(iunit,'(a)') trim(line)
      end do
      write(unit=iunit,fmt="(a)") " "

      do i=1,3
         text(i)=string_numstd(cell%cell(i),cell%scell(i))
         text(i+3)=string_numstd(cell%ang(i),cell%sang(i))
      end do
      write(unit=iunit,fmt='(a)')       "_cell_length_a                       "//trim(adjustl(text(1)))
      write(unit=iunit,fmt='(a)')       "_cell_length_b                       "//trim(adjustl(text(2)))
      write(unit=iunit,fmt='(a)')       "_cell_length_c                       "//trim(adjustl(text(3)))
      write(unit=iunit,fmt='(a)')       "_cell_angle_alpha                    "//trim(adjustl(text(4)))
      write(unit=iunit,fmt='(a)')       "_cell_angle_beta                     "//trim(adjustl(text(5)))
      write(unit=iunit,fmt='(a)')       "_cell_angle_gamma                    "//trim(adjustl(text(6)))
      write(unit=iunit,fmt="(a,f14.4)") "_cell_volume                   ",Cell%Vol
      if (type_data < 2) then
         write(unit=iunit,fmt="(a)") "_cell_formula_units_Z                ?"
         write(unit=iunit,fmt="(a)") "_cell_measurement_temperature        ?"
         write(unit=iunit,fmt="(a)") "_cell_special_details"
         write(unit=iunit,fmt="(a)") "; ?"
         write(unit=iunit,fmt="(a)") ";"
      end if

      select case (type_data)
         case (0) ! Single Crystal
            write(unit=iunit,fmt="(a)") "_cell_measurement_reflns_used        ?"
            write(unit=iunit,fmt="(a)") "_cell_measurement_theta_min          ?"
            write(unit=iunit,fmt="(a)") "_cell_measurement_theta_max          ?"

            write(unit=iunit,fmt="(a)") " "
            write(unit=iunit,fmt="(a)") "_exptl_crystal_description           ?"
            write(unit=iunit,fmt="(a)") "_exptl_crystal_colour                ?"
            write(unit=iunit,fmt="(a)") "_exptl_crystal_size_max              ?"
            write(unit=iunit,fmt="(a)") "_exptl_crystal_size_mid              ?"
            write(unit=iunit,fmt="(a)") "_exptl_crystal_size_min              ?"
            write(unit=iunit,fmt="(a)") "_exptl_crystal_size_rad              ?"
            write(unit=iunit,fmt="(a)") "_exptl_crystal_density_diffrn        ?"
            write(unit=iunit,fmt="(a)") "_exptl_crystal_density_meas          ?"
            write(unit=iunit,fmt="(a)") "_exptl_crystal_density_method        ?"
            write(unit=iunit,fmt="(a)") "_exptl_crystal_F_000                 ?"

         case (1) ! Powder Data
            write(unit=iunit,fmt="(a)") "# The next three fields give the specimen dimensions in mm.  The equatorial"
            write(unit=iunit,fmt="(a)") "# plane contains the incident and diffracted beam."

            write(unit=iunit,fmt="(a)") " "
            write(unit=iunit,fmt="(a)") "_pd_spec_size_axial               ?       # perpendicular to "
            write(unit=iunit,fmt="(a)") "                                          # equatorial plane"

            write(unit=iunit,fmt="(a)") "_pd_spec_size_equat               ?       # parallel to "
            write(unit=iunit,fmt="(a)") "                                          # scattering vector"
            write(unit=iunit,fmt="(a)") "                                          # in transmission"
            write(unit=iunit,fmt="(a)") "_pd_spec_size_thick               ?       # parallel to "
            write(unit=iunit,fmt="(a)") "                                          # scattering vector"
            write(unit=iunit,fmt="(a)") "                                          # in reflection"

            write(unit=iunit,fmt="(a)") " "
            write(unit=iunit,fmt="(a)") "# The next five fields are character fields that describe the specimen."

            write(unit=iunit,fmt="(a)") " "
            write(unit=iunit,fmt="(a)") "_pd_spec_mounting                         # This field should be"
            write(unit=iunit,fmt="(a)") "                                          # used to give details of the "
            write(unit=iunit,fmt="(a)") "                                          # container."
            write(unit=iunit,fmt="(a)") "; ?"
            write(unit=iunit,fmt="(a)") ";"
            write(unit=iunit,fmt="(a)") "_pd_spec_mount_mode               ?       # options are 'reflection'"
            write(unit=iunit,fmt="(a)") "                                          # or 'transmission'"
            write(unit=iunit,fmt="(a)") "_pd_spec_shape                    ?       # options are 'cylinder' "
            write(unit=iunit,fmt="(a)") "                                          # 'flat_sheet' or 'irregular'"
            write(unit=iunit,fmt="(a)") "_pd_char_particle_morphology      ?"
            write(unit=iunit,fmt="(a)") "_pd_char_colour                   ?       # use ICDD colour descriptions"

            write(unit=iunit,fmt="(a)") " "
            write(unit=iunit,fmt="(a)") "# The following three fields describe the preparation of the specimen."
            write(unit=iunit,fmt="(a)") "# The cooling rate is in K/min.  The pressure at which the sample was "
            write(unit=iunit,fmt="(a)") "# prepared is in kPa.  The temperature of preparation is in K.        "

            write(unit=iunit,fmt="(a)") " "
            write(unit=iunit,fmt="(a)") "_pd_prep_cool_rate                ?"
            write(unit=iunit,fmt="(a)") "_pd_prep_pressure                 ?"
            write(unit=iunit,fmt="(a)") "_pd_prep_temperature              ?"
      end select
      if (type_data < 2) then
         write(unit=iunit,fmt="(a)") " "
         write(unit=iunit,fmt="(a)") "# The next four fields are normally only needed for transmission experiments."
         write(unit=iunit,fmt="(a)") " "
         write(unit=iunit,fmt="(a)") "_exptl_absorpt_coefficient_mu        ?"
         write(unit=iunit,fmt="(a)") "_exptl_absorpt_correction_type       ?"
         write(unit=iunit,fmt="(a)") "_exptl_absorpt_process_details       ?"
         write(unit=iunit,fmt="(a)") "_exptl_absorpt_correction_T_min      ?"
         write(unit=iunit,fmt="(a)") "_exptl_absorpt_correction_T_max      ?"

         write(unit=iunit,fmt="(a)") " "
         write(unit=iunit,fmt="(a)") "#============================================================================="
         write(unit=iunit,fmt="(a)") " "

         !> Experimental Data
         write(unit=iunit,fmt="(a)") "# 7. EXPERIMENTAL DATA"

         write(unit=iunit,fmt="(a)") " "
         write(unit=iunit,fmt="(a)") "_exptl_special_details"
         write(unit=iunit,fmt="(a)") "; ?"
         write(unit=iunit,fmt="(a)") ";"

        if (type_data == 1) then
           write(unit=iunit,fmt="(a)") " "
           write(unit=iunit,fmt="(a)") "# The following item is used to identify the equipment used to record "
           write(unit=iunit,fmt="(a)") "# the powder pattern when the diffractogram was measured at a laboratory "
           write(unit=iunit,fmt="(a)") "# other than the authors' home institution, e.g. when neutron or synchrotron"
           write(unit=iunit,fmt="(a)") "# radiation is used."

           write(unit=iunit,fmt="(a)") " "
           write(unit=iunit,fmt="(a)") "_pd_instr_location"
           write(unit=iunit,fmt="(a)") "; ?"
           write(unit=iunit,fmt="(a)") ";"
           write(unit=iunit,fmt="(a)") "_pd_calibration_special_details           # description of the method used"
           write(unit=iunit,fmt="(a)") "                                          # to calibrate the instrument"
           write(unit=iunit,fmt="(a)") "; ?"
           write(unit=iunit,fmt="(a)") ";"
        end if

        write(unit=iunit,fmt="(a)") " "
        write(unit=iunit,fmt="(a)") "_diffrn_ambient_temperature          ?"
        write(unit=iunit,fmt="(a)") "_diffrn_radiation_type               ?"
        write(unit=iunit,fmt="(a)") "_diffrn_radiation_wavelength         ?"
        write(unit=iunit,fmt="(a)") "_diffrn_radiation_source             ?"
        write(unit=iunit,fmt="(a)") "_diffrn_source                       ?"
        write(unit=iunit,fmt="(a)") "_diffrn_source_target                ?"
        write(unit=iunit,fmt="(a)") "_diffrn_source_type                  ?"

        write(unit=iunit,fmt="(a)") " "
        write(unit=iunit,fmt="(a)") "_diffrn_radiation_monochromator      ?"
        write(unit=iunit,fmt="(a)") "_diffrn_measurement_device_type      ?"
        write(unit=iunit,fmt="(a)") "_diffrn_measurement_method           ?"
        write(unit=iunit,fmt="(a)") "_diffrn_detector_area_resol_mean     ?   # Not in version 2.0.1"
        write(unit=iunit,fmt="(a)") "_diffrn_detector                     ?"
        write(unit=iunit,fmt="(a)") "_diffrn_detector_type                ?   # make or model of detector"
        if (type_data == 1) then
           write(unit=iunit,fmt="(a)") "_pd_meas_scan_method                 ?   # options are 'step', 'cont',"
           write(unit=iunit,fmt="(a)") "                                         # 'tof', 'fixed' or"
           write(unit=iunit,fmt="(a)") "                                         # 'disp' (= dispersive)"
           write(unit=iunit,fmt="(a)") "_pd_meas_special_details"
           write(unit=iunit,fmt="(a)") ";  ?"
           write(unit=iunit,fmt="(a)") ";"
        end if

        select case (type_data)
           case (0)
              write(unit=iunit,fmt="(a)") " "
              write(unit=iunit,fmt="(a)") "_diffrn_reflns_number                ?"
              write(unit=iunit,fmt="(a)") "_diffrn_reflns_av_R_equivalents      ?"
              write(unit=iunit,fmt="(a)") "_diffrn_reflns_av_sigmaI/netI        ?"
              write(unit=iunit,fmt="(a)") "_diffrn_reflns_theta_min             ?"
              write(unit=iunit,fmt="(a)") "_diffrn_reflns_theta_max             ?"
              write(unit=iunit,fmt="(a)") "_diffrn_reflns_theta_full            ?"
              write(unit=iunit,fmt="(a)") "_diffrn_measured_fraction_theta_max  ?"
              write(unit=iunit,fmt="(a)") "_diffrn_measured_fraction_theta_full ?"
              write(unit=iunit,fmt="(a)") "_diffrn_reflns_limit_h_min           ?"
              write(unit=iunit,fmt="(a)") "_diffrn_reflns_limit_h_max           ?"
              write(unit=iunit,fmt="(a)") "_diffrn_reflns_limit_k_min           ?"
              write(unit=iunit,fmt="(a)") "_diffrn_reflns_limit_k_max           ?"
              write(unit=iunit,fmt="(a)") "_diffrn_reflns_limit_l_min           ?"
              write(unit=iunit,fmt="(a)") "_diffrn_reflns_limit_l_max           ?"
              write(unit=iunit,fmt="(a)") "_diffrn_reflns_reduction_process     ?"

              write(unit=iunit,fmt="(a)") " "
              write(unit=iunit,fmt="(a)") "_diffrn_standards_number             ?"
              write(unit=iunit,fmt="(a)") "_diffrn_standards_interval_count     ?"
              write(unit=iunit,fmt="(a)") "_diffrn_standards_interval_time      ?"
              write(unit=iunit,fmt="(a)") "_diffrn_standards_decay_%            ?"
              write(unit=iunit,fmt="(a)") "loop_"
              write(unit=iunit,fmt="(a)") "    _diffrn_standard_refln_index_h"
              write(unit=iunit,fmt="(a)") "    _diffrn_standard_refln_index_k"
              write(unit=iunit,fmt="(a)") "    _diffrn_standard_refln_index_l"
              write(unit=iunit,fmt="(a)") "?   ?   ?"

           case (1)
              write(unit=iunit,fmt="(a)") " "
              write(unit=iunit,fmt="(a)") "#  The following four items give details of the measured (not processed)"
              write(unit=iunit,fmt="(a)") "#  powder pattern.  Angles are in degrees."

              write(unit=iunit,fmt="(a)") " "
              write(unit=iunit,fmt="(a)") "_pd_meas_number_of_points         ?"
              write(unit=iunit,fmt="(a)") "_pd_meas_2theta_range_min         ?"
              write(unit=iunit,fmt="(a)") "_pd_meas_2theta_range_max         ?"
              write(unit=iunit,fmt="(a)") "_pd_meas_2theta_range_inc         ?"

              write(unit=iunit,fmt="(a)") " "
              write(unit=iunit,fmt="(a)") "# The following three items are used for time-of-flight measurements only."

              write(unit=iunit,fmt="(a)") " "
              write(unit=iunit,fmt="(a)") "_pd_instr_dist_src/spec           ?"
              write(unit=iunit,fmt="(a)") "_pd_instr_dist_spec/detc          ?"
              write(unit=iunit,fmt="(a)") "_pd_meas_2theta_fixed             ?"

        end select

        write(unit=iunit,fmt="(a)") " "
        write(unit=iunit,fmt="(a)") "#============================================================================="
        write(unit=iunit,fmt="(a)") " "

        !> Refinement Data
        write(unit=iunit,fmt="(a)") "# 8. REFINEMENT DATA"

        write(unit=iunit,fmt="(a)") " "

        write(unit=iunit,fmt="(a)") "_refine_special_details"
        write(unit=iunit,fmt="(a)") "; ?"
        write(unit=iunit,fmt="(a)") ";"

        if (type_data == 1) then
           write(unit=iunit,fmt="(a)") " "
           write(unit=iunit,fmt="(a)") "# Use the next field to give any special details about the fitting of the"
           write(unit=iunit,fmt="(a)") "# powder pattern."

           write(unit=iunit,fmt="(a)") " "
           write(unit=iunit,fmt="(a)") "_pd_proc_ls_special_details"
           write(unit=iunit,fmt="(a)") "; ?"
           write(unit=iunit,fmt="(a)") ";"

           write(unit=iunit,fmt="(a)") " "
           write(unit=iunit,fmt="(a)") "# The next three items are given as text."
           write(unit=iunit,fmt="(a)") " "

           write(unit=iunit,fmt="(a)") "_pd_proc_ls_profile_function      ?"
           write(unit=iunit,fmt="(a)") "_pd_proc_ls_background_function   ?"
           write(unit=iunit,fmt="(a)") "_pd_proc_ls_pref_orient_corr"
           write(unit=iunit,fmt="(a)") "; ?"
           write(unit=iunit,fmt="(a)") ";"
        end if

        select case (type_data)
           case (0)
              write(unit=iunit,fmt="(a)") " "
              write(unit=iunit,fmt="(a)") "_reflns_number_total                 ?"
              write(unit=iunit,fmt="(a)") "_reflns_number_gt                    ?"
              write(unit=iunit,fmt="(a)") "_reflns_threshold_expression         ?"

           case (1)
              write(unit=iunit,fmt="(a)") " "
              write(unit=iunit,fmt="(a)") "_pd_proc_ls_prof_R_factor         ?"
              write(unit=iunit,fmt="(a)") "_pd_proc_ls_prof_wR_factor        ?"
              write(unit=iunit,fmt="(a)") "_pd_proc_ls_prof_wR_expected      ?"

              write(unit=iunit,fmt="(a)") " "
              write(unit=iunit,fmt="(a)") "# The following four items apply to angular dispersive measurements."
              write(unit=iunit,fmt="(a)") "# 2theta minimum, maximum and increment (in degrees) are for the "
              write(unit=iunit,fmt="(a)") "# intensities used in the refinement."

              write(unit=iunit,fmt="(a)") " "
              write(unit=iunit,fmt="(a)") "_pd_proc_2theta_range_min         ?"
              write(unit=iunit,fmt="(a)") "_pd_proc_2theta_range_max         ?"
              write(unit=iunit,fmt="(a)") "_pd_proc_2theta_range_inc         ?"
              write(unit=iunit,fmt="(a)") "_pd_proc_wavelength               ?"

              write(unit=iunit,fmt="(a)") " "
              write(unit=iunit,fmt="(a)") "_pd_block_diffractogram_id        ?  # The id used for the block containing"
              write(unit=iunit,fmt="(a)") "                                     # the powder pattern profile (section 11)."

              write(unit=iunit,fmt="(a)") " "
              write(unit=iunit,fmt="(a)") "# Give appropriate details in the next two text fields."
              write(unit=iunit,fmt="(a)") " "
              write(unit=iunit,fmt="(a)") "_pd_proc_info_excluded_regions    ?"
              write(unit=iunit,fmt="(a)") "_pd_proc_info_data_reduction      ?"
        end select

        write(unit=iunit,fmt="(a)") " "
        write(unit=iunit,fmt="(a)") "_refine_ls_structure_factor_coef     ?"
        write(unit=iunit,fmt="(a)") "_refine_ls_matrix_type               ?"
        write(unit=iunit,fmt="(a)") "_refine_ls_R_I_factor                ?"
        write(unit=iunit,fmt="(a)") "_refine_ls_R_Fsqd_factor             ?"
        write(unit=iunit,fmt="(a)") "_refine_ls_R_factor_all              ?"
        write(unit=iunit,fmt="(a)") "_refine_ls_R_factor_gt               ?"
        write(unit=iunit,fmt="(a)") "_refine_ls_wR_factor_all             ?"
        write(unit=iunit,fmt="(a)") "_refine_ls_wR_factor_ref             ?"
        write(unit=iunit,fmt="(a)") "_refine_ls_goodness_of_fit_all       ?"
        write(unit=iunit,fmt="(a)") "_refine_ls_goodness_of_fit_ref       ?"
        write(unit=iunit,fmt="(a)") "_refine_ls_restrained_S_all          ?"
        write(unit=iunit,fmt="(a)") "_refine_ls_restrained_S_obs          ?"
        write(unit=iunit,fmt="(a)") "_refine_ls_number_reflns             ?"
        write(unit=iunit,fmt="(a)") "_refine_ls_number_parameters         ?"
        write(unit=iunit,fmt="(a)") "_refine_ls_number_restraints         ?"
        write(unit=iunit,fmt="(a)") "_refine_ls_number_constraints        ?"
        write(unit=iunit,fmt="(a)") "_refine_ls_hydrogen_treatment        ?"
        write(unit=iunit,fmt="(a)") "_refine_ls_weighting_scheme          ?"
        write(unit=iunit,fmt="(a)") "_refine_ls_weighting_details         ?"
        write(unit=iunit,fmt="(a)") "_refine_ls_shift/su_max              ?"
        write(unit=iunit,fmt="(a)") "_refine_ls_shift/su_mean             ?"
        write(unit=iunit,fmt="(a)") "_refine_diff_density_max             ?"
        write(unit=iunit,fmt="(a)") "_refine_diff_density_min             ?"
        write(unit=iunit,fmt="(a)") "_refine_ls_extinction_method         ?"
        write(unit=iunit,fmt="(a)") "_refine_ls_extinction_coef           ?"
        write(unit=iunit,fmt="(a)") "_refine_ls_abs_structure_details     ?"
        write(unit=iunit,fmt="(a)") "_refine_ls_abs_structure_Flack       ?"
        write(unit=iunit,fmt="(a)") "_refine_ls_abs_structure_Rogers      ?"

        write(unit=iunit,fmt="(a)") " "
        write(unit=iunit,fmt="(a)") "# The following items are used to identify the programs used."
        write(unit=iunit,fmt="(a)") " "

        write(unit=iunit,fmt="(a)") "_computing_data_collection           ?"
        write(unit=iunit,fmt="(a)") "_computing_cell_refinement           ?"
        write(unit=iunit,fmt="(a)") "_computing_data_reduction            ?"
        write(unit=iunit,fmt="(a)") "_computing_structure_solution        ?"
        write(unit=iunit,fmt="(a)") "_computing_structure_refinement      ?"
        write(unit=iunit,fmt="(a)") "_computing_molecular_graphics        ?"
        write(unit=iunit,fmt="(a)") "_computing_publication_material      ?"
      end if  !(type_data < 2) then
      write(unit=iunit,fmt="(a)") " "
      write(unit=iunit,fmt="(a)") "#============================================================================="
      write(unit=iunit,fmt="(a)") " "

      !> Atomic Coordinates and Displacement Parameters
      write(unit=iunit,fmt="(a)") "# 9. ATOMIC COORDINATES AND DISPLACEMENT PARAMETERS"

      write(unit=iunit,fmt="(a)") " "

      write(unit=iunit,fmt="(a)") "loop_"
      write(unit=iunit,fmt='(a)') "    _atom_site_label"
      write(unit=iunit,fmt='(a)') "    _atom_site_type_symbol"
      write(unit=iunit,fmt='(a)') "    _atom_site_fract_x"
      write(unit=iunit,fmt='(a)') "    _atom_site_fract_y"
      write(unit=iunit,fmt='(a)') "    _atom_site_fract_z"
      write(unit=iunit,fmt='(a)') "    _atom_site_U_iso_or_equiv"
      write(unit=iunit,fmt='(a)') "    _atom_site_occupancy"
      write(unit=iunit,fmt='(a)') "    _atom_site_adp_type"
      write(unit=iunit,fmt='(a)') "    _atom_site_type_symbol"

      !> Calculation of the factor corresponding to the occupation factor provided in A
      do i=1,AtmList%natoms
         occup(i)=Atmlist%Atom(i)%occ/(real(AtmList%Atom(i)%mult)/real(SpG%multip))
         soccup(i)=0.0
         select type (at => AtmList%Atom)
            class is (Atm_Std_Type)
                soccup(i)=At(i)%occ_std/(real(At(i)%mult)/real(SpG%multip))
         end select
      end do
      ocf=sum(abs(Atmlist%atom(1)%x-Atmlist%atom(2)%x))
      if ( ocf < 0.001) then
         ocf=occup(1)+occup(2)
      else
         ocf=occup(1)
      end if
      occup=occup/ocf; soccup=soccup/ocf
      aniso=.false.

      do i=1,AtmList%natoms
         line=" "
         line(2:)= Atmlist%Atom(i)%Lab//"  "//Atmlist%Atom(i)%SfacSymb

         do j=1,3
            rval=0.0
            select type (at => AtmList%Atom)
               class is (Atm_Std_Type)
                   rval=At(i)%x_std(j)
            end select
            comm=string_numstd(Atmlist%Atom(i)%x(j),rval)
            line=trim(line)//" "//trim(comm)
         end do

         comm=" "
         select case (AtmList%Atom(i)%Thtype)
            case ('iso')
               adptyp='Uiso'
               select case (trim(AtmList%Atom(i)%UType))
                  case ("U")
                     u=Atmlist%Atom(i)%U_iso
                     su=0.0
                     select type (at => AtmList%Atom)
                        class is (Atm_Std_Type)
                            su=At(i)%U_iso_std
                     end select

                  case ("B")
                     u=Atmlist%Atom(i)%U_iso/(8.0*pi*pi)
                     su=0.0
                     select type (at => AtmList%Atom)
                        class is (Atm_Std_Type)
                            su=At(i)%U_iso_std/(8.0*pi*pi)
                     end select

                  case ("beta")
                     u=Atmlist%Atom(i)%U_iso
                     su=0.0
                     select type (at => AtmList%Atom)
                        class is (Atm_Std_Type)
                            su=At(i)%U_iso_std
                     end select
               end select
               comm=string_numstd(u,su)

            case ('ani')
               aniso=.true.
               adptyp='Uani'
               select case (trim(AtmList%Atom(i)%UType))
                  case ("U")
                     ua=AtmList%atom(i)%u
                     sua=0.0
                     select type (at => AtmList%Atom)
                        class is (Atm_Std_Type)
                            sua=At(i)%U_std
                     end select

                  case ("B")
                     ua=AtmList%atom(i)%u/(8.0*pi*pi)
                     sua=0.0
                     select type (at => AtmList%Atom)
                        class is (Atm_Std_Type)
                            sua=At(i)%U_std/(8.0*pi*pi)
                     end select

                  case ("beta")
                     aux=Atmlist%atom(i)%u
                     ua=get_U_from_Betas(aux,cell)
                     aux=0.0
                     select type (at => AtmList%Atom)
                        class is (Atm_Std_Type)
                            aux=At(i)%U_std
                     end select
                     sua=get_U_from_Betas(aux,cell)
               end select
               u=(ua(1)+ua(2)+ua(3))/3.0
               su=(ua(1)+ua(2)+ua(3))/3.0
               comm=string_numstd(u,su)

            case default
               adptyp='.'
         end select
         line=trim(line)//" "//trim(comm)

         comm=string_numstd(occup(i),soccup(i))
         line=trim(line)//" "//trim(comm)
         write(unit=iunit,fmt="(a)") trim(line)//" "//trim(adptyp)//" "//Atmlist%atom(i)%SfacSymb
      end do

      if (aniso) then
         write(unit=iunit,fmt="(a)") " "
         write(unit=iunit,fmt="(a)") "loop_"
         write(unit=iunit,fmt="(a)") "    _atom_site_aniso_label "
         write(unit=iunit,fmt="(a)") "    _atom_site_aniso_U_11  "
         write(unit=iunit,fmt="(a)") "    _atom_site_aniso_U_22  "
         write(unit=iunit,fmt="(a)") "    _atom_site_aniso_U_33  "
         write(unit=iunit,fmt="(a)") "    _atom_site_aniso_U_12  "
         write(unit=iunit,fmt="(a)") "    _atom_site_aniso_U_13  "
         write(unit=iunit,fmt="(a)") "    _atom_site_aniso_U_23  "
         write(unit=iunit,fmt="(a)") "    _atom_site_aniso_type_symbol"

         do i=1,AtmList%natoms
            if (AtmList%Atom(i)%thtype /= "ani") cycle

            line=" "
            line(2:)= Atmlist%Atom(i)%Lab

            select case (trim(AtmList%Atom(i)%UType))
               case ("U")
                  ua=AtmList%atom(i)%u
                  sua=0.0
                  select type (at => AtmList%Atom)
                     class is (Atm_Std_Type)
                         sua=At(i)%U_std
                  end select

               case ("B")
                  ua=AtmList%atom(i)%u/(8.0*pi*pi)
                  sua=0.0
                  select type (at => AtmList%Atom)
                     class is (Atm_Std_Type)
                         sua=At(i)%U_std/(8.0*pi*pi)
                  end select

               case ("beta")
                  aux=Atmlist%atom(i)%u
                  ua=get_U_from_Betas(aux,cell)
                  aux=0.0
                  select type (at => AtmList%Atom)
                     class is (Atm_Std_Type)
                         aux=At(i)%U_std
                  end select
                  sua=get_U_from_Betas(aux,cell)
            end select

            do j=1,6
              comm=String_NumStd(ua(j),sua(j))
              line=trim(line)//" "//trim(comm)
            end do
            write(iunit,"(a)") trim(line)//"  "//Atmlist%atom(i)%SfacSymb
         end do
      end if

      if(type_data < 2) then
         write(unit=iunit,fmt="(a)") " "
         write(unit=iunit,fmt="(a)") "# Note: if the displacement parameters were refined anisotropically"
         write(unit=iunit,fmt="(a)") "# the U matrices should be given as for single-crystal studies."

         write(unit=iunit,fmt="(a)") " "
         write(unit=iunit,fmt="(a)") "#============================================================================="
         write(unit=iunit,fmt="(a)") " "

         !---- Molecular Geometry ----!
         write(unit=iunit,fmt="(a)") "# 10. MOLECULAR GEOMETRY"

         write(unit=iunit,fmt="(a)") " "


         write(unit=iunit,fmt="(a)") "_geom_special_details                ?"

         write(unit=iunit,fmt="(a)") " "
         write(unit=iunit,fmt="(a)") "loop_"
         write(unit=iunit,fmt="(a)") "    _geom_bond_atom_site_label_1  "
         write(unit=iunit,fmt="(a)") "    _geom_bond_atom_site_label_2  "
         write(unit=iunit,fmt="(a)") "    _geom_bond_site_symmetry_1    "
         write(unit=iunit,fmt="(a)") "    _geom_bond_site_symmetry_2    "
         write(unit=iunit,fmt="(a)") "    _geom_bond_distance           "
         write(unit=iunit,fmt="(a)") "    _geom_bond_publ_flag          "
         write(unit=iunit,fmt="(a)") "    ?   ?   ?   ?   ?   ?"

         write(unit=iunit,fmt="(a)") " "
         write(unit=iunit,fmt="(a)") "loop_"
         write(unit=iunit,fmt="(a)") "    _geom_contact_atom_site_label_1 "
         write(unit=iunit,fmt="(a)") "    _geom_contact_atom_site_label_2 "
         write(unit=iunit,fmt="(a)") "    _geom_contact_distance          "
         write(unit=iunit,fmt="(a)") "    _geom_contact_site_symmetry_1   "
         write(unit=iunit,fmt="(a)") "    _geom_contact_site_symmetry_2   "
         write(unit=iunit,fmt="(a)") "    _geom_contact_publ_flag         "
         write(unit=iunit,fmt="(a)") "    ?   ?   ?   ?   ?   ?"

         write(unit=iunit,fmt="(a)") " "
         write(unit=iunit,fmt="(a)") "loop_"
         write(unit=iunit,fmt="(a)") "_geom_angle_atom_site_label_1 "
         write(unit=iunit,fmt="(a)") "_geom_angle_atom_site_label_2 "
         write(unit=iunit,fmt="(a)") "_geom_angle_atom_site_label_3 "
         write(unit=iunit,fmt="(a)") "_geom_angle_site_symmetry_1   "
         write(unit=iunit,fmt="(a)") "_geom_angle_site_symmetry_2   "
         write(unit=iunit,fmt="(a)") "_geom_angle_site_symmetry_3   "
         write(unit=iunit,fmt="(a)") "_geom_angle                   "
         write(unit=iunit,fmt="(a)") "_geom_angle_publ_flag         "
         write(unit=iunit,fmt="(a)") "?   ?   ?   ?   ?   ?   ?   ?"

         write(unit=iunit,fmt="(a)") " "
         write(unit=iunit,fmt="(a)") "loop_"
         write(unit=iunit,fmt="(a)") "_geom_torsion_atom_site_label_1 "
         write(unit=iunit,fmt="(a)") "_geom_torsion_atom_site_label_2 "
         write(unit=iunit,fmt="(a)") "_geom_torsion_atom_site_label_3 "
         write(unit=iunit,fmt="(a)") "_geom_torsion_atom_site_label_4 "
         write(unit=iunit,fmt="(a)") "_geom_torsion_site_symmetry_1   "
         write(unit=iunit,fmt="(a)") "_geom_torsion_site_symmetry_2   "
         write(unit=iunit,fmt="(a)") "_geom_torsion_site_symmetry_3   "
         write(unit=iunit,fmt="(a)") "_geom_torsion_site_symmetry_4   "
         write(unit=iunit,fmt="(a)") "_geom_torsion                   "
         write(unit=iunit,fmt="(a)") "_geom_torsion_publ_flag         "
         write(unit=iunit,fmt="(a)") "?   ?   ?   ?   ?   ?   ?   ?   ?   ?"

         write(unit=iunit,fmt="(a)") " "
         write(unit=iunit,fmt="(a)") "loop_"
         write(unit=iunit,fmt="(a)") "_geom_hbond_atom_site_label_D "
         write(unit=iunit,fmt="(a)") "_geom_hbond_atom_site_label_H "
         write(unit=iunit,fmt="(a)") "_geom_hbond_atom_site_label_A "
         write(unit=iunit,fmt="(a)") "_geom_hbond_site_symmetry_D   "
         write(unit=iunit,fmt="(a)") "_geom_hbond_site_symmetry_H   "
         write(unit=iunit,fmt="(a)") "_geom_hbond_site_symmetry_A   "
         write(unit=iunit,fmt="(a)") "_geom_hbond_distance_DH       "
         write(unit=iunit,fmt="(a)") "_geom_hbond_distance_HA       "
         write(unit=iunit,fmt="(a)") "_geom_hbond_distance_DA       "
         write(unit=iunit,fmt="(a)") "_geom_hbond_angle_DHA         "
         write(unit=iunit,fmt="(a)") "_geom_hbond_publ_flag         "
         write(unit=iunit,fmt="(a)") "?   ?   ?   ?   ?   ?   ?   ?   ?   ?   ?"

         write(unit=iunit,fmt="(a)") " "
         write(unit=iunit,fmt="(a)") "#============================================================================="
         write(unit=iunit,fmt="(a)") " "


         !---- Final Informations ----!
         write(unit=iunit,fmt="(a)") "#============================================================================="
         write(unit=iunit,fmt="(a)") "# Additional structures (last six sections and associated data_? identifiers) "
         write(unit=iunit,fmt="(a)") "# may be added at this point.                                                 "
         write(unit=iunit,fmt="(a)") "#============================================================================="

         write(unit=iunit,fmt="(a)") " "
         write(unit=iunit,fmt="(a)") "# The following lines are used to test the character set of files sent by     "
         write(unit=iunit,fmt="(a)") "# network email or other means. They are not part of the CIF data set.        "
         write(unit=iunit,fmt="(a)") "# abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789              "
         write(unit=iunit,fmt="(a)") "# !@#$%^&*()_+{}:"//""""//"~<>?|\-=[];'`,./ "
      end if

      close(unit=iunit)

   End Subroutine Write_CIF_Template

   !!--++
   !!--++ Read_XTal_CIF
   !!--++
   !!--++ Read a CIF File
   !!--++
   !!--++ 11/05/2020
   !!
   Module Subroutine Read_XTal_CIF(cif, Cell, Spg, AtmList, Nphase)
      !---- Arguments ----!
      type(File_Type),               intent(in)  :: cif
      class(Cell_Type),              intent(out) :: Cell
      class(SpG_Type),               intent(out) :: SpG
      Type(AtList_Type),             intent(out) :: Atmlist
      Integer,             optional, intent(in)  :: Nphase   ! Select the Phase to read

      !---- Local Variables ----!
      character(len= 20)             :: Spp
      integer                        :: i, iph, nt_phases, it, n_ini,n_end
      integer, dimension(MAX_PHASES) :: ip

      real(kind=cp),dimension(6):: vet,vet2

      !> Init
      call clear_error()
      if (cif%nlines <=0) then
         err_CFML%Ierr=1
         err_CFML%Msg="Read_XTal_CIF: No lines in the file!"
         return
      end if

      !> Calculating number of Phases
      nt_phases=0; ip=cif%nlines; ip(1)=1
      do i=1,cif%nlines
         line=adjustl(cif%line(i)%str)
         if (l_case(line(1:5)) == "data_" .and. l_case(line(1:11)) /= "data_global" )  then
            nt_phases=nt_phases+1
            ip(nt_phases)=i
         end if
      end do

      !> Read the Phase information
      iph=1
      if (present(nphase)) then
         iph=min(nphase, nt_phases)
         iph=max(1,iph)
      end if

      n_ini=ip(iph)
      n_end=ip(iph+1)

      !> Reading Cell Parameters
      call Read_Cif_Cell(cif,Cell,n_ini,n_end)
      if (Err_CFML%IErr==1) return

      !> SpaceGroup Information
      spp=" "
      call read_cif_it(cif,it,n_ini,n_end)
      if (it > 0) write(unit=spp,fmt='(i4)') it
      call set_spacegroup(spp,Spg)

      if (len_trim(Spg%spg_symb) <= 0) then
         call read_cif_hm(cif,spp,n_ini,n_end)
         call set_spacegroup(spp,Spg)
      end if
      if (len_trim(Spg%spg_symb) <= 0) then
         call read_cif_hall(cif,spp,n_ini,n_end)
         call set_spacegroup(spp,Spg)
      end if
      if (len_trim(Spg%spg_symb) <= 0 .or. Err_CFML%IErr ==1) return

      !> Atoms information
      call read_cif_Atoms(cif,AtmList,n_ini,n_end)
      if (Err_CFML%IErr==1) return

      !> Modify occupation factors and set multiplicity of atoms
      !> in order to be in agreement with the definitions of Sfac in CrysFML
      !> Convert Us to Betas and Uiso to Biso
      do i=1,Atmlist%natoms
         vet(1:3)=Atmlist%atom(i)%x
         Atmlist%atom(i)%Mult=Get_Multip_Pos(vet(1:3),SpG)
         Atmlist%atom(i)%Occ=Atmlist%atom(i)%Occ*real(Atmlist%atom(i)%Mult)/max(1.0_cp,real(SpG%Multip))
         if (Atmlist%atom(i)%occ < EPSV) Atmlist%atom(i)%occ=real(Atmlist%atom(i)%Mult)/max(1.0,real(SpG%Multip))

         select case (AtmList%atom(i)%thtype)
            case ("iso")
               Atmlist%atom(i)%u_iso= Atmlist%atom(i)%u_iso*78.95683521

            case ("ani")
               Atmlist%atom(i)%u_iso= Atmlist%atom(i)%u(1)*78.95683521 !by default

               select type (cell)
                  class is (Cell_G_Type)
                     Atmlist%atom(i)%u_iso=U_Equiv(cell,Atmlist%atom(i)%u(1:6))  ! Uequi
                     Atmlist%atom(i)%u_iso= Atmlist%atom(i)%u_iso*78.95683521

                     select case (Atmlist%atom(i)%Utype)
                        case ("u_ij")
                           Atmlist%atom(i)%u(1:6) =  Get_Betas_from_U(Atmlist%atom(i)%u(1:6),Cell)

                        case ("b_ij")
                           Atmlist%atom(i)%u(1:6) = Get_Betas_from_B(Atmlist%atom(i)%u(1:6),Cell)
                     end select
               end select

            case default
               Atmlist%atom(i)%u_iso=0.05
               Atmlist%atom(i)%u_iso = Atmlist%atom(i)%u_iso*78.95683521
               Atmlist%atom(i)%thtype = "iso"
         end select
         Atmlist%atom(i)%Utype="beta"
      end do

   End Subroutine Read_XTal_CIF

End SubModule IO_CIF