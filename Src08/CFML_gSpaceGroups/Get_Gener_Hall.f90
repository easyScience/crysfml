!!----
!!----
!!----
!!----
SubModule (CFML_gSpaceGroups) Spg_052
   Contains
   
   !!----
   !!---- GET_GENERATORS_FROM_HALL
   !!---- 
   !!----    Magnetic Hall symbols interpretation based on descriptions on 
   !!----    http://cci.lbl.gov/sginfo/hall_symbols.html
   !!----
   !!---- 09/05/2019
   !!
   Module Subroutine Get_Generators_from_Hall(Hall, ngen, Gen, RShift, VShift)
      !---- Arguments ----!
      character(len=*),                            intent(in)  :: Hall      ! Hall symbol
      integer,                                     intent(out) :: Ngen      ! Number of genertaors
      character(len=*), dimension(:), allocatable, intent(out) :: Gen       ! String generators
      logical, optional,                           intent(in)  :: RShift    ! .True. to give the shift vector in free format
      real(kind=cp), dimension(3), optional,       intent(out) :: VShift     ! Shift vector from Hall symbol
      
      !---- Local Variables ----!
      character(len=9),  parameter :: L ="PABCIRSTF"
      character(len=13), parameter :: T ="ABCNUVWD12345"
      character(len=6),  parameter :: A ="XYZ^"//'"*'
      character(len=6),  parameter :: N ="123406"
      character(len=8),  parameter :: AT='abcABCIS'
                          
      integer, dimension(3,3), parameter  :: X_1   = reshape([ 1, 0, 0,  0, 1, 0,  0, 0, 1],[3,3])
      integer, dimension(3,3), parameter  :: Y_1   = reshape([ 1, 0, 0,  0, 1, 0,  0, 0, 1],[3,3])
      integer, dimension(3,3), parameter  :: Z_1   = reshape([ 1, 0, 0,  0, 1, 0,  0, 0, 1],[3,3]) 
       
      integer, dimension(3,3), parameter  :: X_2   = reshape([ 1, 0, 0,  0,-1, 0,  0, 0,-1],[3,3])
      integer, dimension(3,3), parameter  :: Y_2   = reshape([-1, 0, 0,  0, 1, 0,  0, 0,-1],[3,3])
      integer, dimension(3,3), parameter  :: Z_2   = reshape([-1, 0, 0,  0,-1, 0,  0, 0, 1],[3,3])

      integer, dimension(3,3), parameter  :: X_3   = reshape([ 1, 0, 0,  0, 0, 1,  0,-1,-1],[3,3])
      integer, dimension(3,3), parameter  :: Y_3   = reshape([-1, 0,-1,  0, 1, 0,  1, 0, 0],[3,3])
      integer, dimension(3,3), parameter  :: Z_3   = reshape([ 0, 1, 0, -1,-1, 0,  0, 0, 1],[3,3])

      integer, dimension(3,3), parameter  :: X_4   = reshape([ 1, 0, 0,  0, 0, 1,  0,-1, 0],[3,3])
      integer, dimension(3,3), parameter  :: Y_4   = reshape([ 0, 0,-1,  0, 1, 0,  1, 0, 0],[3,3])
      integer, dimension(3,3), parameter  :: Z_4   = reshape([ 0, 1, 0, -1, 0, 0,  0, 0, 1],[3,3])
      
      integer, dimension(3,3), parameter  :: X_6   = reshape([ 1, 0, 0,  0, 1, 1,  0,-1, 0],[3,3])
      integer, dimension(3,3), parameter  :: Y_6   = reshape([ 0, 0,-1,  0, 1, 0,  1, 0, 1],[3,3])
      integer, dimension(3,3), parameter  :: Z_6   = reshape([ 1, 1, 0, -1, 0, 0,  0, 0, 1],[3,3])
       
      integer, dimension(3,3), parameter  :: X_2P  = reshape([-1, 0, 0,  0, 0,-1,  0,-1, 0],[3,3])
      integer, dimension(3,3), parameter  :: Y_2P  = reshape([ 0, 0,-1,  0,-1, 0, -1, 0, 0],[3,3])
      integer, dimension(3,3), parameter  :: Z_2P  = reshape([ 0,-1, 0, -1, 0, 0,  0, 0,-1],[3,3])
       
      integer, dimension(3,3), parameter  :: X_2PP = reshape([-1, 0, 0,  0, 0, 1,  0, 1, 0],[3,3])
      integer, dimension(3,3), parameter  :: Y_2PP = reshape([ 0, 0, 1,  0,-1, 0,  1, 0, 0],[3,3])
      integer, dimension(3,3), parameter  :: Z_2PP = reshape([ 0, 1, 0,  1, 0, 0,  0, 0,-1],[3,3])

      integer, dimension(3,3), parameter  :: XYZ_3 = reshape([ 0, 1, 0,  0, 0, 1,  1, 0, 0],[3,3])
       
      integer, dimension(4,4), parameter :: IDENTIDAD = reshape([1, 0, 0, 0, &
                                                                 0, 1, 0, 0, &
                                                                 0, 0, 1, 0, &
                                                                 0, 0, 0, 1],[4,4])                                                                         
       
      integer,             parameter :: PMAX= 5  ! Maximum number of Operators
                               
      integer, dimension(PMAX)       :: Ni       ! rotation symbol for each operator
      integer, dimension(PMAX)       :: Ai       ! axis symbol for each operator
      integer, dimension(3,PMAX)     :: Ti       ! traslation for each symbol
      logical, dimension(PMAX)       :: Tr       ! time reversal
                               
      character(len=20)              :: str
      character(len=1)               :: car
      character(len=10),dimension(5) :: dire
      integer                        :: i,j,n1,n2,nt,iv,signo
      integer                        :: ilat, axis
      integer, dimension(3)          :: ishift, v_trans, a_latt
      integer, dimension(3)          :: ivet
      real(kind=cp), dimension(3)    :: vet, Co
      logical                        :: centro,free,shift
      
      type(rational), dimension(4,4) :: sn, snp
      type(rational), dimension(3)   :: sh
      type(symm_oper_type)           :: op
      
      logical, parameter             :: pout=.false.
      
      !> Init
      ngen=0
      free=.false.
      shift=.false.
      if (present(RShift)) free=RShift
      
      !> Copy
      str=u_case(adjustl(Hall))
      if (pout) print*,'  ---> Magnetic Hall Symbol: '//trim(str)
      
      !> 
      !> Shift origin?
      !>
      ishift=0
      sh=0//1
      
      n1=index(str,'(')
      n2=index(str,')')
      nt=len_trim(str)
      if ((n1 ==0 .and. n2 > 0) .or. (n1 > 0 .and. n2==0) .or. (n1 > n2)) then
         Err_CFML%IErr=1
         Err_CFML%Msg="Get_Generators_from_Hall@GSPACEGROUPS: Error with shift origin format!" 
         return
      end if 
      
      if (n1 > 0) then     
         call get_num(str(n1+1:n2-1), vet, ivet, iv)
         if (iv /= 3) then
            err_CFML%IErr=1
            err_CFML%Msg="Get_Generators_from_Hall@GSPACEGROUPS: Error with shift origin format!" 
            return
         end if
         shift=.true.
         
         if (.not. free) then
            ishift=ivet
            ishift=mod(ishift +24, 12)
            sh=real(ishift)/12.0_cp
         else
            sh=vet
         end if      
         
         if (n2+1 > nt) then
            str=str(:n1-1)
         else   
            str=str(:n1-1)//' '//str(n2+1:)
         end if   
      end if 
      
      !>
      !> Lattice traslational (L)
      !>
      centro=.false.
      ilat=0
      
      if (str(1:1)=='-') then
         centro=.true.
         str=adjustl(str(2:))
      end if
      
      ilat=index(L,str(1:1))
      if (ilat == 0) then
         err_CFML%IErr=1
         err_CFML%Msg="Get_Generators_from_Hall@GSPACEGROUPS: Unknown lattice traslational symmetry!"
         return
      end if 
      str=adjustl(str(2:))
      
      if (pout) then
         if (centro) then
            print*,'  ---> Centrosymmetric structure'
         else
            print*,'  ---> NON-Centrosymmetric structure'
         end if   
         print*,'  ---> Bravais Cell type: '//L(ilat:ilat)
      end if    
      
      !> 
      !> Anti-traslational
      !>
      car=" "
      a_latt=0
      n1=index(AT,str(1:1)) 
      if (n1 > 0) then
         call get_words(Hall,dire,iv)
         car=adjustl(dire(2))
         n2=index(AT,car)
         if (n2 == 0) then
            err_CFML%IErr=1
            err_CFML%Msg="Get_Generators_from_Hall@GSPACEGROUPS: Unknown anti-lattice traslational symmetry!"
            return
         end if 
         select case (car)
            case ("a")
               a_latt=[6,0,0]
            case ("b")
               a_latt=[0,6,0]
            case ("c")
               a_latt=[0,0,6]
            case ("A")
               a_latt=[0,6,6]
            case ("B")
               a_latt=[6,0,6]
            case ("C")
               a_latt=[6,6,0]
            case ("I")
               if (ilat ==6) then  ! R Lattice
                  a_latt=[0,0,6]
               else
                  a_latt=[6,6,6]
               end if   
            case ("S") 
               if (ilat ==9) then ! F Lattice
                  a_latt=[6,6,6]
               else
                  a_latt=[0,0,6]
               end if                       
         end select 
         
         !> 
         str=adjustl(str(2:)) 
      end if   
      
      !>        
      !> Operators
      !>
      dire=" "
      Ni=0; Ai=0; Ti=0
      call Allocate_Symm_Op(4, Op)  ! 4 is Dimension
      
      call get_words(str, dire, iv)
      if (iv ==0 ) then
         err_CFML%IErr=1
         err_CFML%Msg="Get_Generators_from_Hall@GSPACEGROUPS: Hall symbol format is wrong, please check it!"
         return
      end if   
      
      do i=1, iv
         if (pout) then
            print*,' '
            print*,'  ---> Operator description: ',i, trim(dire(i))
         end if   
         
         !> Ni (Rotation)
         signo=1
         if (dire(i)(1:1)=='-') then
            signo=-1
            dire(i)=adjustl(dire(i)(2:))
         end if   
         
         j=index(N,dire(i)(1:1))
         if (j == 0 .or. j==5) then
            err_CFML%IErr=1
            err_CFML%Msg="Get_Generators_from_Hall@GSPACEGROUPS: Wrong proper/improper rotation symbol!"
            return
         end if
         Ni(i)=j
         dire(i)=adjustl(dire(i)(2:))

         if (pout) print*,'  ---> Rotation order: ', signo*Ni(i) 

         !> Ai (axis)
         axis=0
         j=index(A,dire(i)(1:1))
         if (j == 0) then
            !> When A symbol can be omitted
            select case (i) 
               case (1) !> First operator
                  axis=3 ! c axis
                  
               case (2) !> Second operator
                  if (Ni(i) == 2) then
                     if (abs(Ni(i-1))==2 .or. abs(Ni(i-1))==4) then
                        axis=1 ! a axis
                     
                     elseif (abs(Ni(i-1))==3 .or. abs(Ni(i-1))==6) then
                        axis=7 ! a-b   
                     end if
                  end if   
                  
               case (3) !> Third operator
                  if (abs(Ni(i)) == 3) then
                     axis=10 ! a+b+c
                  end if
            end select
         
         else
            select case (j)
               case (1:3)
                  axis=j  ! a or b or c
                  
               case (4) !'
                  if (Ni(i) /= 2) then
                     err_CFML%IErr=1
                     err_CFML%Msg="Get_Generators_from_Hall@GSPACEGROUPS: The rotation order of the operator should be 2!"
                     return
                  end if
                  select case (Ai(i-1))
                     case (1)
                        axis=9 ! b-c
                     case (2)
                        axis=8 ! a-c
                     case (3) 
                        axis=7 ! a-b    
                  end select   
                     
               case (5) !"
                  if (Ni(i) /= 2) then
                     err_CFML%IErr=1
                     err_CFML%Msg="Get_Generators_from_Hall@GSPACEGROUPS: The rotation order of the operator should be 2!"
                     return
                  end if
                  select case (Ai(i-1))
                     case (1)
                        axis=6 ! b+c
                     case (2)
                        axis=5 ! c+a
                     case (3) 
                        axis=4 ! a+b    
                  end select 
               case (6) !* 
                  axis=10 !a+b+c       
            end select
            dire(i)=adjustl(dire(i)(2:)) 
         end if
         
         !> Axis could be 0 only if order the last operator is 1
         if (axis==0 .and. Ni(i) /= 1) then
            err_CFML%IErr=1
            err_CFML%Msg="Get_Generators_from_Hall@GSPACEGROUPS: The axis symbol (A) in Hall is wrong!"
            return
         end if   
         Ai(i)=axis 
         
         if (pout) print*,'  ---> Axis: ',Ai(i)
         
         !> Symbol T
         v_trans=0
         do
            if (len_trim(dire(i))==0) exit
            
            j=index(T,dire(i)(1:1))
            if (j==0) exit
            select case (j)
               case (1) ! a
                  v_trans=v_trans+[6,0,0]
               case (2) ! b
                  v_trans=v_trans+[0,6,0]
               case (3) ! c
                  v_trans=v_trans+[0,0,6]
               case (4) ! n
                  v_trans=v_trans+[6,6,6]
               case (5) ! u
                  v_trans=v_trans+[3,0,0]
               case (6) ! v
                  v_trans=v_trans+[0,3,0]
               case (7) ! w
                  v_trans=v_trans+[0,0,3]
               case (8) ! d
                  v_trans=v_trans+[3,3,3]
                  
               case (9) ! 1
                  select case (Ni(i))
                     case (3) ! 1/3
                        select case (Ai(i))
                           case (1)
                              v_trans=v_trans+[4,0,0]
                           case (2)
                              v_trans=v_trans+[0,4,0]
                           case (3)      
                              v_trans=v_trans+[0,0,4]
                        end select
                        
                     case (4) ! 1/4
                        select case (Ai(i))
                           case (1)
                              v_trans=v_trans+[3,0,0]
                           case (2)
                              v_trans=v_trans+[0,3,0]
                           case (3)      
                              v_trans=v_trans+[0,0,3]
                        end select
                        
                     case (6) ! 1/6
                        select case (Ai(i))
                           case (1)
                              v_trans=v_trans+[2,0,0]
                           case (2)
                              v_trans=v_trans+[0,2,0]
                           case (3)      
                              v_trans=v_trans+[0,0,2]
                        end select     
                  end select   
                  
               case (10)! 2
                  select case (Ni(i))
                     case (3) ! 2/3
                        select case (Ai(i))
                           case (1)
                              v_trans=v_trans+[8,0,0]
                           case (2)
                              v_trans=v_trans+[0,8,0]
                           case (3)      
                              v_trans=v_trans+[0,0,8]
                        end select
                        
                     case (6) ! 2/6  
                        select case (Ai(i))
                           case (1)
                              v_trans=v_trans+[4,0,0]
                           case (2)
                              v_trans=v_trans+[0,4,0]
                           case (3)      
                              v_trans=v_trans+[0,0,4]
                        end select
                  end select  
                   
               case (11)! 3
                  select case (Ni(i))
                     case (4) ! 3/4
                        select case (Ai(i))
                           case (1)
                              v_trans=v_trans+[9,0,0]
                           case (2)
                              v_trans=v_trans+[0,9,0]
                           case (3)      
                              v_trans=v_trans+[0,0,9]
                        end select
                  end select
                  
               case (12)! 4
                  select case (Ni(i))
                     case (6) ! 4/6
                        select case (Ai(i))
                           case (1)
                              v_trans=v_trans+[8,0,0]
                           case (2)
                              v_trans=v_trans+[0,8,0]
                           case (3)      
                              v_trans=v_trans+[0,0,8]
                        end select
                  end select
                  
               case (13)! 5
                  select case (Ni(i))
                     case (6) ! 5/6
                        select case (Ai(i))
                           case (1)
                              v_trans=v_trans+[10,0,0]
                           case (2)
                              v_trans=v_trans+[0,10,0]
                           case (3)      
                              v_trans=v_trans+[0,0,10]
                        end select
                  end select      
            end select
            dire(i)=adjustl(dire(i)(2:)) 
         end do   
         Ti(:,i)=v_trans
         
         if (pout) print*,'  --->Traslation: ',Ti(:,i)
         
         !> Time reversal
         Tr(i)=.false.
         if (len_trim(dire(i)) > 0) then
            if (dire(i)(1:1) /="'") then
               err_CFML%IErr=1
               err_CFML%Msg="Get_Generators_from_Hall@GSPACEGROUPS: Check the MHall symbol!"
               return
            end if   
            Tr(i)=.true.
         
            if (pout) then
               if (tr(i)) then
                  print*,'  ---> Primed operator'
               end if   
            end if
         end if      
         
         !> Save the signo in rotation
         Ni(i)=Ni(i)*signo
      end do  
      
      !> In the original paper was not commented but is possible to
      !> define a shift using the last operator with rotation order -1 
      !> and given additional traslation
      if (Ni(iv)== -1 .and. (.not. tr(iv))) then
         shift=.true.
         ishift=mod(-Ti(:,iv) + 24, 12)
         sh=real(ishift)/12.0_cp
         
         iv=iv-1
      end if
      if (pout) print*,'  ---> Shift: ', rational_string(sh)
      
      !> Allocate Gen
      nt=iv
      if (centro) nt=nt+1
      if (any(a_latt > 0)) nt=nt+1
      select case (ilat)
         case (2:5)
            nt=nt+1
         case (6:8)
            nt=nt+2
         case (9)
            nt=nt+3      
      end select
      if (nt == 0) then
         err_CFML%IErr=1
         err_CFML%Msg="Get_Generators_from_Hall@GSPACEGROUPS: Please check the Hall symbol!"
         return
      end if   

      if (allocated(gen)) deallocate(gen) 
      allocate(gen(nt))
      gen=" "  

      !> Generators
      ngen=0
      do i=1,iv
         sn=identidad
         signo=sign(1,Ni(i))          
         
         select case (abs(Ni(i)))
            case (1)
               select case (Ai(i))
                  case (0)
                     if (.not. tr(i)) then
                        err_CFML%IErr=1
                        err_CFML%Msg="Get_Generators_from_MHall@GSPACEGROUPS: Check symbol!"
                        return
                     end if
                     sn=sign(1,Ni(i))*identidad
                  case (1)
                     sn(1:3,1:3)=signo*X_1
                  case (2)
                     sn(1:3,1:3)=signo*Y_1
                  case (3)
                     sn(1:3,1:3)=signo*Z_1
                  case default   
                     err_CFML%IErr=1
                     err_CFML%Msg="Get_Generators_from_Hall@GSPACEGROUPS: Rotation order 1, Incompatible axis!"
                     return
               end select
               
            case (2)
               select case (Ai(i))
                  case (1)
                     sn(1:3,1:3)=signo*X_2
                  case (2)
                     sn(1:3,1:3)=signo*Y_2
                  case (3)
                     sn(1:3,1:3)=signo*Z_2
                  case (4)  
                     sn(1:3,1:3)=signo*Z_2PP 
                  case (5)   
                     sn(1:3,1:3)=signo*X_2PP 
                  case (6)   
                     sn(1:3,1:3)=signo*Y_2PP
                  case (7)   
                     sn(1:3,1:3)=signo*Z_2P
                  case (8)   
                     sn(1:3,1:3)=signo*X_2P
                  case (9)   
                     sn(1:3,1:3)=signo*Y_2PP
                  case default   
                     err_CFML%IErr=1
                     err_CFML%Msg="Get_Generators_from_Hall@GSPACEGROUPS: Rotation order 2, Incompatible axis!"
                     return
               end select
               
            case (3)
               select case (Ai(i))
                  case (1)
                     sn(1:3,1:3)=signo*X_3
                  case (2)
                     sn(1:3,1:3)=signo*Y_3
                  case (3)
                     sn(1:3,1:3)=signo*Z_3
                  case (10)
                     sn(1:3,1:3)=signo*XYZ_3
                  case default 
                     err_CFML%IErr=1
                     err_CFML%Msg="Get_Generators_from_Hall@GSPACEGROUPS: Rotation order 3, Incompatible axis!"
                     return           
               end select
               
            case (4)
               select case (Ai(i))
                  case (1)
                     sn(1:3,1:3)=signo*X_4
                  case (2)
                     sn(1:3,1:3)=signo*Y_4
                  case (3)
                     sn(1:3,1:3)=signo*Z_4
                  case default 
                     err_CFML%IErr=1
                     err_CFML%Msg="Get_Generators_from_Hall@GSPACEGROUPS: Rotation order 4, Incompatible axis!"
                     return           
               end select
               
            case (6)
               select case (Ai(i))
                  case (1)
                     sn(1:3,1:3)=signo*X_6
                  case (2)
                     sn(1:3,1:3)=signo*Y_6
                  case (3)
                     sn(1:3,1:3)=signo*Z_6
                  case default 
                     err_CFML%IErr=1
                     err_CFML%Msg="Get_Generators_from_Hall@GSPACEGROUPS: Rotation order 4, Incompatible axis!"
                     return           
               end select
         end select
         sn(1:3,4)=Ti(:,i)/12.0_cp
         
         if (shift) then
            snp=identidad
            snp(1:3,4)=sh
            sn=matmul(snp,sn)
            
            snp(1:3,4)=-sh
            sn=matmul(sn,snp)
            sn(1:3,4)=rational_modulo_lat(sn(1:3,4))
         end if   
         
         op%mat=sn
         op%Time_Inv=1
         if (tr(i)) op%Time_Inv=-1
            
         ngen=ngen+1
         gen(ngen)=Get_Symb_from_Op(op)
      end do  

      !> Centro symmetric
      if (centro) then
         sn=-identidad
         
         if (shift) then
            snp=identidad
            snp(1:3,4)=sh
            sn=matmul(snp,sn)
            
            snp(1:3,4)=-sh
            sn=matmul(sn,snp)
            sn(1:3,4)=rational_modulo_lat(sn(1:3,4))
         end if   
         
         op%mat=sn
         op%Time_Inv=1
         
         ngen=ngen+1
         gen(ngen)=Get_Symb_from_Op(op)
      end if   
      
      !> Anti-traslation
      if (any(a_latt > 0)) then
         sn=identidad
         sn(4,4)=1
         sn(1:3,4)=a_latt/12.0_cp
         
         op%mat=sn
         op%Time_Inv=-1
         
         ngen=ngen+1
         gen(ngen)=Get_Symb_from_Op(op)
      end if 
      
      if (ilat > 1) then
         do i=1,3 ! Loops
            select case (i)
               case (1) ! First loop
                  select case (ilat)
                     case (2)
                        sn=identidad
                        sn(1:3,4)=[0//1, 1//2, 1//2]
                        
                     case (3)
                        sn=identidad
                        sn(1:3,4)=[1//2, 0//1, 1//2]
                        
                     case (4)
                        sn=identidad
                        sn(1:3,4)=[1//2, 1//2, 0//1]
                        
                     case (5)
                        sn=identidad
                        sn(1:3,4)=[1//2, 1//2, 1//2]
                        
                     case (6)
                        sn=identidad
                        sn(1:3,4)=[2//3, 1//3, 1//3]
                        
                     case (7)
                        sn=identidad
                        sn(1:3,4)=[1//3, 1//3, 2//3]
                        
                     case (8)
                        sn=identidad
                        sn(1:3,4)=[1//3, 2//3, 1//3]
                        
                     case (9)
                        sn=identidad
                        sn(1:3,4)=[0//1, 1//2, 1//2]
                  end select
                  
               case (2) ! Second loop  
                  select case (ilat)
                     case (6)
                        sn=identidad
                        sn(1:3,4)=[1//3, 2//3, 2//3]
                        
                     case (7)
                        sn=identidad
                        sn(1:3,4)=[2//3, 2//3, 1//3]
                        
                     case (8)
                        sn=identidad
                        sn(1:3,4)=[2//3, 1//3, 2//3]
                        
                     case (9)
                        sn=identidad
                        sn(1:3,4)=[1//2, 0//1, 1//2]         
                  end select 
                  
               case (3) ! Third loop
                  if (ilat ==9) then
                     sn=identidad
                     sn(1:3,4)=[1//2, 1//2, 0//1] 
                  end if      
            end select
            
            if (shift ) then
               snp=identidad
               snp(1:3,4)=sh
               sn=matmul(snp,sn)
            
               snp(1:3,4)=-sh
               sn=matmul(sn,snp)
               sn(1:3,4)=rational_modulo_lat(sn(1:3,4))
            end if   
         
            op%mat=sn
            op%Time_Inv=1
         
            ngen=ngen+1
            gen(ngen)=Get_Symb_from_Op(op)
            
            if (ilat < 6) exit              ! only one cycle
            if (ilat < 9 .and. i==2) exit   ! two cycles 
            
         end do   
      end if
      
      !> End
      if (present (Vshift)) Vshift=sh
      
      if (pout) then
         print*,' '
         print*,'  ---> List of Possible Generators <---'
         print*,'---------------------------------------'
         do i=1,ngen
            print*,'  ---> Generator: '//trim(gen(i))
         end do   
         print*,' '
      end if
         
   End Subroutine Get_Generators_from_Hall
   
   
   
End SubModule Spg_052   