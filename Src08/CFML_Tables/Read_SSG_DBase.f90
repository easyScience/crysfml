!!----
!!----
!!----
!!----
SubModule (CFML_SuperSpace_Database) Reading_SuperSpace_Database
   Contains
   !!----
   !!---- READ SUPERSPACE DATA BASE
   !!----
   !!---- Read data about magnetic space groups
   !!---- input data from magnetic_table.dat
   !!----
   !!---- 24/04/2019
   !!
   Module Subroutine Read_SSG_DBase(database_path)
      character(len=*), optional,intent(in)  :: database_path
      !
      integer :: i,j,k,m,n,nmod,iclass
      integer :: i_db, ier,L !,i_lab
      character(len=512) :: ssg_file,fullprof_suite
      character(len=4)   :: line

      !> Init
      call clear_error()

      if(.not. SSG_DBase_allocated) then
         call Allocate_SSG_DBase()
      end if
      if(present(database_path)) then
         n=len_trim(database_path)
         if(n == 0) then
           ssg_file='ssg_datafile.txt'
         else
           if(database_path(n:n) /= OPS_SEP) then
               ssg_file=trim(database_path)//OPS_SEP//'ssg_datafile.txt'
           else
               ssg_file=trim(database_path)//'ssg_datafile.txt'
           end if
         end if
      else
         !> open data file
         call GET_ENVIRONMENT_VARIABLE("FULLPROF",fullprof_suite)
         n=len_trim(fullprof_suite)
         if (n == 0) then
            err_CFML%IErr=1
            write(unit=err_cfml%msg,fmt="(a)") " => The FULLPROF environment variable is not defined! "//newline// &
                                               "    This is needed for localizing the data base: magnetic_data.txt"//newline// &
                                               "    that should be within the %FULLPROF%/Databases directory"
            return
         end if

         if (fullprof_suite(n:n) /= OPS_SEP) then
            ssg_file=trim(fullprof_suite)//OPS_SEP//"Databases"//OPS_SEP//'ssg_datafile.txt'
         else
            ssg_file=trim(fullprof_suite)//"Databases"//OPS_SEP//'ssg_datafile.txt'
         end if
      end if

      open(newunit=i_db,file=ssg_file,status='old',action='read',position='rewind',iostat=ier)
      if(ier /= 0) then
        err_CFML%IErr=1
        err_cfml%msg= 'Error opening the database file: '//trim(ssg_file)
        return
      end if

      ! Uncomment for creating the file SSG_Labels.txt
      !open(newunit=i_lab,file=trim(fullprof_suite)//OPS_SEP//"Databases"//OPS_SEP//"SSG_Labels.txt",status='replace',action='write',iostat=ier)
      !if(ier /= 0) then
      !  err_CFML%IErr=1
      !  err_cfml%msg= 'Error opening the labels file: '//trim(trim(fullprof_suite)//"Databases"//OPS_SEP//"Labels.txt")
      !  return
      !else                 !12345678123456  123456  123456  123456  123456  12345678901      123456
      !  write(i_lab,"(a)") "       #   Class  Pos-Cl  Pos-Gr  Gr-Num  Parent  Num-Label        SSG-Label"
      !end if

      L=0
      do i=1,2526
        read(unit=i_db,fmt="(a)") line
        if(line(1:1) == '"') then
          L=L+1
          pos_class(L)= i-1
        end if
      end do
      L=0

      do i=2527,300000
        read(unit=i_db,fmt="(a)",iostat=ier) line
        if (ier /= 0) exit
        if(line(1:1) == '"') then
          L=L+1
          pos_group(L)= i-1
        end if
      end do
      rewind(unit=i_db)
      ! skip heading
      read(unit=i_db,fmt=*)
      read(unit=i_db,fmt=*)
      read(unit=i_db,fmt=*)
      ! read number of Bravais classes
      read(unit=i_db,fmt=*) nclasses
      ! read each Bravais class
      do m=1,nclasses
        read(unit=i_db,fmt=*)n,iclass_nmod(m),iclass_number(m), iclass_spacegroup(m),iclass_nstars(m), &
                  (iclass_nmodstar(i,m),i=1,iclass_nstars(m))
        nmod=iclass_nmod(m)
        if(n /= m) then
          err_CFML%IErr=1
          write(unit=err_cfml%msg,fmt="(a,i3)") 'Error in ssg_datafile @reading Bravais class #: ',m
          close(unit=i_db)
          return
        end if

        read(unit=i_db,fmt=*)class_nlabel(m),class_label(m)
        read(unit=i_db,fmt=*)(((iclass_qvec(i,j,k,m),i=1,3),j=1,3),k=1,nmod)
        read(unit=i_db,fmt=*)iclass_ncentering(m)
        read(unit=i_db,fmt=*)((iclass_centering(i,j,m),i=1,nmod+4),j=1,iclass_ncentering(m))
      end do

      ! read number of superspace groups
      read(i_db,*)ngroups
      ! read each superspace group
      do m=1,ngroups
        !write(6,'(i5)')m
        read(i_db,*)n,igroup_number(m),igroup_class(m),igroup_spacegroup(m)
        if(n /= m)then
          err_CFML%IErr=1
          write(unit=err_cfml%msg,fmt="(a,i3)") 'Error in ssg_datafile @reading group#: ',m
          close(unit=i_db)
          return
        end if
        iclass=igroup_class(m)
        nmod=iclass_nmod(iclass)
        read(i_db,*)group_nlabel(m),group_label(m)
        read(i_db,*)igroup_nops(m)
        read(i_db,*)(((igroup_ops(i,j,k,m),i=1,nmod+4),j=1,nmod+4), k=1,igroup_nops(m))
        read(i_db,*)igroup_nconditions(m)
        if(igroup_nconditions(m) > 0)then
            read(unit=i_db,fmt=*)(((igroup_condition1(i,j,k,m),i=1,nmod+3),j=1,nmod+3),(igroup_condition2(j,k,m),j=1,nmod+4), &
                                    k=1,igroup_nconditions(m))
        end if
        !write(i_lab,"(6i8,2a)") m,iclass,pos_class(iclass),pos_group(m),igroup_number(m),igroup_spacegroup(m),"   "//group_nlabel(m),"   "//trim(group_label(m))
      end do
      close(unit=i_db)
      !close(unit=i_lab)
      SSG_DBase_allocated=.true.
   End Subroutine Read_SSG_DBase

   Module Subroutine Read_single_SSG(str,num,database_path)
      character(len=*),           intent(in)  :: str
      integer,                    intent(out) :: num
      character(len=*), optional, intent(in)  :: database_path
      !
      integer :: i,j,k,n,m,i_pos,n_skip,nmod,i_db,ier,iclass
      character(len=512) :: ssg_file,pos_file,fullprof_suite,db_dir,lab_file
      character(len=13)  :: nlabel
      character(len=60)  :: label
      character(len=256) :: line
      logical :: found

      if(present(database_path)) then
         n=len_trim(database_path)
         if(database_path(n:n) /= OPS_SEP) then
             ssg_file=trim(database_path)//OPS_SEP//'ssg_datafile.txt'
             pos_file=trim(database_path)//OPS_SEP//'class+group_pos.txt'
         else
             ssg_file=trim(database_path)//'ssg_datafile.txt'
             pos_file=trim(database_path)//'class+group_pos.txt'
         end if
      else
         !> open data file
         call GET_ENVIRONMENT_VARIABLE("FULLPROF",fullprof_suite)
         n=len_trim(fullprof_suite)
         if (n == 0) then
            err_CFML%IErr=1
            write(unit=err_cfml%msg,fmt="(a)") " => The FULLPROF environment variable is not defined! "//newline// &
                                               "    This is needed for localizing the data base: magnetic_data.txt"//newline// &
                                               "    that should be within the $FULLPROF/Databases directory"
            return
         end if

         if (fullprof_suite(n:n) /= OPS_SEP) then
            db_dir=trim(fullprof_suite)//OPS_SEP//"Databases"//OPS_SEP
         else
            db_dir=trim(fullprof_suite)//"Databases"//OPS_SEP
         end if
         ssg_file=trim(db_dir)//'ssg_datafile.txt'
         pos_file=trim(db_dir)//'class+group_pos.txt'
         lab_file=trim(db_dir)//'SSG_Labels.txt'
      end if

      if(.not. ssg_DBase_allocated) then
        call Allocate_SSG_DBase()
      end if
      call clear_error()
      found=.false.
      !First determine the number of the space groups (it may be provided in the string "str")
      read(unit=str,fmt=*,iostat=ier) num
      if(ier /= 0) then !The provided string does not contain the number
        open(newunit=i_lab,file=lab_file,status='old',action='read',position='rewind',iostat=ier)
        read(i_lab,*)
        do i=1,m_ngs
          read(i_lab,"(a)") line
          j=index(line,trim(str))
          if(j /= 0) then
            found=.true.
            !backspace(i_lab)
            read(line,*) num
            found=.true.
            exit
          end if
        end do
        if(.not. found) then
          err_CFML%IErr=1
          err_CFML%Msg= 'The space group label: '//trim(str)//" has not been found in the database!"
          return
        end if
      end if

      ! open data file
      open(newunit=i_db,file=ssg_file,status='old',action='read',position='rewind',iostat=ier)
      if(ier /= 0) then
        err_CFML%IErr=1
        err_CFML%Msg= 'Error opening the database file: '//trim(ssg_file)
        return
      end if
      open(newunit=i_pos,file=pos_file,status='old',action='read',position='rewind',iostat=ier)
      if(ier /= 0) then
        err_CFML%IErr=1
        err_CFML%Msg= 'Error opening the database file: '//trim(pos_file)
        return
      end if
      read(unit=i_pos,fmt=*) !skip class line
      read(unit=i_pos,fmt=*) pos_class
      read(unit=i_pos,fmt=*) !skip group line
      read(unit=i_pos,fmt=*) pos_group
      close(unit=i_pos)
      read(unit=i_db,fmt=*)
      read(unit=i_db,fmt=*)
      read(unit=i_db,fmt=*)
      ! read number of Bravais classes
      read(unit=i_db,fmt=*) nclasses
      ! read each Bravais class
      do m=1,nclasses
        read(unit=i_db,fmt=*) n,iclass_nmod(m),iclass_number(m), iclass_spacegroup(m),iclass_nstars(m), &
                              (iclass_nmodstar(i,m),i=1,iclass_nstars(m))
        nmod=iclass_nmod(m)
        read(unit=i_db,fmt=*) class_nlabel(m),class_label(m)
        read(unit=i_db,fmt=*) (((iclass_qvec(i,j,k,m),i=1,3),j=1,3),k=1,nmod)
        read(unit=i_db,fmt=*) iclass_ncentering(m)
        read(unit=i_db,fmt=*) ((iclass_centering(i,j,m),i=1,nmod+4),j=1,iclass_ncentering(m))
      end do
      rewind(unit=i_db)
      !write(*,"(10i8)") pos_group
      n_skip=pos_group(num)-1
      !write(*,"(a,i12)") "Skipping ",n_skip
      do i=1,n_skip
        read(unit=i_db,fmt=*)
      end do
      m=num
      read(unit=i_db,fmt=*) n,igroup_number(m),igroup_class(m),igroup_spacegroup(m)
      if(n /= m)then
        err_CFML%IErr=1
        write(unit=err_CFML%Msg,fmt="(a,2i5)") 'Error in ssg_datafile @reading group#: ',m,n
        close(unit=i_db)
        return
      end if
      iclass=igroup_class(m)
      nmod=iclass_nmod(iclass)
      read(unit=i_db,fmt=*) group_nlabel(m),group_label(m)
      read(unit=i_db,fmt=*) igroup_nops(m)
      read(unit=i_db,fmt=*) (((igroup_ops(i,j,k,m),i=1,nmod+4),j=1,nmod+4), k=1,igroup_nops(m))
      close(unit=i_db)

   End Subroutine Read_single_SSG

End SubModule Reading_SuperSpace_Database