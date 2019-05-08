SubModule (CFML_gSpaceGroups) SPG_038
   Contains
    !!----
    !!---- Get_Generators
    !!----
    !!---- Returns the generators for the space group = spaceGroupNumber
    !!----
    !!---- 24/04/2019 
    !!
    Module Subroutine Get_Generators(laueClass,symOp,nSymOp,G,nGen)
        !---- Arguments ----!
        character(len=*),                        intent(in)  :: laueClass ! Laue class
        type(Symm_Oper_Type), dimension(nSymOp), intent(in)  :: symOp     ! symmetry operations
        integer,                                 intent(in)  :: nSymOp    ! number of symmetry operations
        type(Symm_Oper_Type), dimension(3),      intent(out) :: G         ! generators
        integer,                                 intent(out) :: nGen      ! number of generators

        integer                              :: i,n,ngaux,inversion
        type(rational), dimension(3)         :: axis
        type(rational), dimension(3,3)       :: identity
        integer, dimension(:,:), allocatable :: idd


        !> Initialization
        Call Clear_Error()
        
        nGen          = 0
        inversion     = 0
        call Rational_Identity_Matrix(identity)
        allocate(idd(nSymOp,2))
        do i = 1 , 3
           allocate(G(i)%Mat(4,4))
        end do

        !> Look for an inversion center
        do i = 1 , nSymOp
           if (Rational_Equal(-symOp(i)%Mat(1:3,1:3),identity)) then
              inversion = i
              exit
           end if
        end do

        select case(trim(laueClass))
           case ("-1") ! Triclinic
              if (inversion == 0) then
                  nGen = 1
                  ! Search for the onefold axis
                  call Get_Rotations(symOp(:),nSymOp,1,n,idd)
                  G(1) = symOp(idd(1,1))
              end if

           case ("2/m") ! Monoclinic
              nGen = 1
              ! Search for a twofold axis
              call Get_Rotations(symOp(:),nSymOp,2,n,idd)
              G(1) = symOp(idd(1,1))

           case ("mmm")! Orthorhombic
              nGen = 2
              !> Search for the two fold axes along [001] and [010]
              call Get_Rotations(symOP(:),nSymOp,2,n,idd)
              ngaux = 0
              do i = 1 , n
                 axis=Get_Rotation_Axis(symOp(idd(i,1))%Mat(1:3,1:3))
                 if ((axis(1) == (0//1) .and. axis(2) == (0//1) .and. axis(3) == (1//1)) .or. &
                    (axis(1) == (0//1) .and. axis(2) == (1//1) .and. axis(3) == (0//1))) then
                    ngaux = ngaux + 1
                    G(ngaux) = symOp(idd(i,1))
                    if (ngaux == 2) exit
                 end if
              end do

           case ("4/m","4/mmm") ! Tetragonal
              ! Search for the fourfold axis along [001]
              call Get_Rotations(symOp(:),nSymOp,4,n,idd)
              do i = 1 , n
                 axis=Get_Rotation_Axis(symOp(idd(i,1))%Mat(1:3,1:3))
                 if (axis(1) == (0//1) .and. axis(2) == (0//1) .and. axis(3) == (1//1)) then
                    if (Positive_SenseRot(symOp(idd(i,1))%Mat(1:3,1:3),axis)) then
                       G(1) = symOp(idd(i,1))
                       nGen = 1
                       exit
                    end if
                 end if
              end do
              
              !> Look for a possible twofold axis along [100]
              call Get_Rotations(symOp(:),nSymOp,2,n,idd)
              do i = 1 , n
                 axis=Get_Rotation_Axis(symOp(idd(i,1))%Mat(1:3,1:3))
                 if (axis(1) == (1//1) .and. axis(2) == (0//1) .and. axis(3) == (0//1)) then
                    G(2) = symOp(idd(i,1))
                    nGen = 2
                    exit
                 end if
              end do

           case ("-3","-3 R","-3m","-3m R","-3m1","-31m") ! Trigonal
              !> Search for the threefold axis along [001]
              call Get_Rotations(symOP(:),nSymOp,3,n,idd)
              do i = 1 , n
                 axis=Get_Rotation_Axis(symOp(idd(i,1))%Mat(1:3,1:3))
                 if (axis(1) == (0//1) .and. axis(2) == (0//1) .and. axis(3) == (1//1)) then
                    if (Positive_SenseRot(symOp(idd(i,1))%Mat(1:3,1:3),axis)) then
                       G(1) = symOp(idd(i,1))
                       nGen     = 1
                       exit
                    end if
                 end if
              end do
                
              !> Search for a possible twofold axis along [110] or [-110]
              call Get_Rotations(symOp(:),nSymOp,2,n,idd)
              do i = 1 , n
                 axis=Get_Rotation_Axis(symOp(idd(i,1))%Mat(1:3,1:3))
                 if ((axis(1) == (1//1) .and. axis(2) == (1//1) .and. axis(3) == (0//1)) .or. &
                    (axis(1) == (-1//1) .and. axis(2) == (1//1) .and. axis(3) == (0//1))) then
                    G(2) = symOp(idd(i,1))
                    nGen     = 2
                    exit
                 end if
              end do

            case ("6/m","6/mmm") ! Hexagonal
               !> Search for the sixfold axis along [001] in SGtarget
               call Get_Rotations(symOp(:),nSymOp,6,n,idd)
               do i = 1 , n
                  axis=Get_Rotation_Axis(symOp(idd(i,1))%Mat(1:3,1:3))
                  if (axis(1) == (0//1) .and. axis(2) == (0//1) .and. axis(3) == (1//1)) then
                     if (Positive_SenseRot(symOp(idd(i,1))%Mat(1:3,1:3),axis)) then
                        G(1) = symOp(idd(i,1))
                        nGen     = 1
                        exit
                     end if
                  end if
               end do
                
               !> Look for a possible twofold axis along [-110] in SGtarget
               call Get_Rotations(symOp(:),nSymOp,2,n,idd)
               do i = 1 , n
                  axis=Get_Rotation_Axis(symOp(idd(i,1))%Mat(1:3,1:3))
                  if (axis(1) == (-1//1) .and. axis(2) == (1//1) .and. axis(3) == (0//1)) then
                     G(2) = symOp(idd(i,1))
                     nGen         = 2
                     exit
                  end if
               end do

            case ("m3","m-3","m3m","m-3m") ! Cubic
               !> Search for the fourfold axis along [001] in SGtarget
               call Get_Rotations(symOp(:),nSymOp,4,n,idd)
               do i = 1 , n
                  axis=Get_Rotation_Axis(symOp(idd(i,1))%Mat(1:3,1:3))
                  if (axis(1) == (0//1) .and. axis(2) == (0//1) .and. axis(3) == (1//1)) then
                     if (Positive_SenseRot(symOp(idd(i,1))%Mat,axis)) then
                        G(1) = symOp(idd(i,1))
                        nGen = 1
                        exit
                     end if
                  end if
               end do
               
               if (nGen == 0) then
                  !> Search for the twofold axis along [001] in SGtarget
                  call Get_Rotations(symOp(:),nSymOp,2,n,idd)
                  do i = 1 , n
                     axis=Get_Rotation_Axis(symOp(idd(i,1))%Mat(1:3,1:3))
                     if (axis(1) == (0//1) .and. axis(2) == (0//1) .and. axis(3) == (1//1)) then
                        G(1) = symOp(idd(i,1))
                        nGen = 1
                        exit
                     end if
                  end do
               end if
               
               !> Search for a threefold axis along {111} in SGtarget
               call Get_Rotations(symOp(:),nSymOp,3,n,idd)
               do i = 1 , n
                  axis=Get_Rotation_Axis(symOp(idd(i,1))%Mat(1:3,1:3))
                  if (axis(1) == (1//1) .and. axis(2) == (1//1) .and. axis(3) == (1//1)) then
                     if (Positive_SenseRot(symOp(idd(i,1))%Mat(1:3,1:3),axis)) then
                        G(2) = symOp(idd(i,1))
                        nGen = 2
                        exit
                     end if
                  end if
               end do

            case default
               Err_CFML%Ierr = 1
               Err_CFML%Msg = "Get_Generators@SPACEG: Unknown Laue class"
               return

        end select

        if (inversion > 0) then
           ! Choose proper rotations if the spacegroup is centrosymmetric
           !do i = 1 , nGen
           !    det = rational_determ(G(i)%Mat(1:3,1:3))
           !    G(i)%Mat(1:3,1:3) = det * G(i)%Mat(1:3,1:3)
           !    !G(i)%time_inv     = symOp(inversion)%time_inv * G(i)%time_inv
           !    write(*,*) "Hola ",symOp(inversion)%time_inv,G(i)%time_inv,G(i)%time_inv*symOp(inversion)%time_inv
           !end do
           nGen = nGen + 1
           G(nGen) = symOp(inversion)
        end if
    End Subroutine Get_Generators
    
End SubModule SPG_038    