!!----
!!---- SUBMODULE CFML_Math_General
!!----
!!----
!!
Submodule (CFML_Math_General) CFML_MG_11
 Contains
 
    !!---- SUBROUTINE SPLINE
    !!----    Spline  N points
    !!----
    !!---- Update: February - 2005
    !!
    Module Pure Subroutine Spline(x,y,n,yp1,ypn,y2)    
       !---- Arguments ----!
       real(kind=cp), dimension(:), intent(in)  :: x               !  In -> Array X
       real(kind=cp), dimension(:), intent(in)  :: y               !  In -> Array Yi=F(Xi)
       integer ,                    intent(in)  :: n               !  In -> Dimension of X, Y
       real(kind=cp),               intent(in)  :: yp1             !  In -> Derivate of Point 1
       real(kind=cp),               intent(in)  :: ypn             !  In -> Derivate of Point N
       real(kind=cp), dimension(:), intent(out) :: y2              ! Out -> array containing second derivatives

       !---- Local Variables ----!
       integer                     :: i, k
       real(kind=cp), dimension(n) :: u
       real(kind=cp)               :: sig, p, qn, un

       if (yp1 > 1.0e+30) then
          y2(1)=0.0
          u(1)=0.0
       else
          y2(1)=-0.5
          u(1)=(3.0/(x(2)-x(1)))*((y(2)-y(1))/(x(2)-x(1))-yp1)
       end if

       do i=2,n-1
          sig=(x(i)-x(i-1))/(x(i+1)-x(i-1))
          p=sig*y2(i-1)+2.0
          y2(i)=(sig-1.0)/p
          u(i)=(6.0*((y(i+1)-y(i))/(x(i+1)-x(i))-(y(i)-y(i-1))/(x(i)-x(i-1)))  &
               /(x(i+1)-x(i-1))-sig*u(i-1))/p
       end do
       if (ypn > 1.0e+30) then
          qn=0.0
          un=0.0
       else
          qn=0.5
          un=(3.0/(x(n)-x(n-1)))*(ypn-(y(n)-y(n-1))/(x(n)-x(n-1)))
       end if
       y2(n)=(un-qn*u(n-1))/(qn*y2(n-1)+1.0)
       do k=n-1,1,-1
          y2(k)=y2(k)*y2(k+1)+u(k)
       end do

       return
    End Subroutine Spline
    
    !!---- SUBROUTINE  SPLINT
    !!----
    !!----    Spline Interpolation
    !!----
    !!---- Update: February - 2005
    !!
    Module Pure Function Splint(xa,ya,y2a,n,x) Result(y)    
       !---- Arguments ----!
       real(kind=cp), dimension(:), intent(in)  :: xa          !  In -> Array X
       real(kind=cp), dimension(:), intent(in)  :: ya          !  In -> Array Y=F(X)
       real(kind=cp), dimension(:), intent(in)  :: y2a         !  In -> Array Second Derivatives in X
       integer ,                    intent(in)  :: n           !  In -> Dimension of XA,YA,Y2A
       real(kind=cp),               intent(in)  :: x           !  In -> Point to evaluate
       real(kind=cp)                            :: y           ! Out -> Interpoled value

       !---- Local Variables ----!
       integer          :: klo, khi, k
       real(kind=cp)    :: h, a, b

       y=0.0_cp
       
       klo=1
       khi=n
       do
          if (khi-klo > 1) then
             k=(khi+klo)/2
             if (xa(k) > x) then
                khi=k
             else
                klo=k
             end if
             cycle
          else
             exit
          end if
       end do

       h=xa(khi)-xa(klo)
       a=(xa(khi)-x)/h
       b=(x-xa(klo))/h
       
       !>
       y=a*ya(klo)+b*ya(khi)+((a**3-a)*y2a(klo)+(b**3-b)* y2a(khi))*(h**2)/6.0

       return
    End Function Splint
    
    !!---- SUBROUTINE FIRST_DERIVATIVE
    !!----
    !!----    Calculate the First derivate values of the N points
    !!----
    !!---- Update: January - 2006
    !!
    Module Pure Subroutine First_Derivative(x,y,n,d2y,d1y)    
       !---- Arguments ----!
       real(kind=cp), dimension(:), intent(in)  :: x     ! Input vector
       real(kind=cp), dimension(:), intent(in)  :: y     ! Yi=F(xi)
       integer ,                    intent(in)  :: n     ! Dimension of X and Y
       real(kind=cp), dimension(:), intent(in)  :: d2y   ! Vector containing the second derivative in each point
       real(kind=cp), dimension(:), intent(out) :: d1y   ! Vector containing the first derivative in each point

       !---- Local Variables ----!
       integer       :: i
       real(kind=cp) :: step, x0, y0, y1, y2

       do i=1,n
          if (i /= n) then
             step = x(i+1)-x(i)
          end if
          x0 = x(i) - step/2.0
          y0 =splint(x,y, d2y, n, x0)
          y1 = y0
          x0 = x(i) + step/2
          y0 =splint(x,y, d2y, n, x0)
          y2 = y0
          d1y(i) = (y2 - y1) / step
       end do

       return
    End Subroutine First_Derivative
    
    !!---- SUBROUTINE SECOND_DERIVATIVE
    !!----
    !!----    Calculate the second derivate of N Points
    !!----
    !!---- Update: January - 2006
    !!
    Module Pure Subroutine Second_Derivative(x,y,n,d2y)    
       !---- Arguments ----!
       real(kind=cp), dimension(:), intent(in)  :: x    ! Input X vector
       real(kind=cp), dimension(:), intent(in)  :: y    ! Yi=F(xi)
       integer ,                    intent(in)  :: n    ! Number of Points
       real(kind=cp), dimension(:), intent(out) :: d2y  ! Second derivative

       !---- Local Variables ----!
       integer                     :: i, k
       real(kind=cp), dimension(n) :: u
       real(kind=cp)               :: yp1, ypn, sig, p, qn, un

       yp1=(y(2) - y(1))   / (x(2) - x(1))     ! derivative at point 1
       ypn=(y(n) - y(n-1)) / (x(n) - x(n-1))   ! derivative at point n

       d2y(1)=-0.5
       u(1)=(3.0/(x(2)-x(1)))*((y(2)-y(1))/(x(2)-x(1))-yp1)

       do i=2,n-1
          sig=(x(i)-x(i-1))/(x(i+1)-x(i-1))
          p=sig*d2y(i-1)+2.0
          d2y(i)=(sig-1.0)/p
          u(i)=(6.0*((y(i+1)-y(i))/(x(i+1)-x(i))-(y(i)-y(i-1))/(x(i)-x(i-1)))  &
               /(x(i+1)-x(i-1))-sig*u(i-1))/p
       end do

       qn=0.5
       un=(3.0/(x(n)-x(n-1)))*(ypn-(y(n)-y(n-1))/(x(n)-x(n-1)))
       d2y(n)=(un-qn*u(n-1))/(qn*d2y(n-1)+1.0)
       do k=n-1,1,-1
          d2y(k)=d2y(k)*d2y(k+1)+u(k)
       end do

       return
    End Subroutine Second_Derivative
    
End Submodule CFML_MG_11
