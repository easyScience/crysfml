!!----
!!---- SUBMODULE CFML_Math_General
!!----
!!----
!!
Submodule (CFML_Maths) CFML_Math_001
 Contains

    !!----
    !!---- MODULO_LAT
    !!----    Reduces a real vector to another with components in
    !!----    the interval [0,1)
    !!----
    !!---- 28/03/2019
    !!
    Module Pure Function Modulo_Lat(v) result(u)
       !---- Argument ----!
       real(kind=cp), dimension(:), intent( in) :: v
       real(kind=cp), dimension(1:size(v))      :: u

       u=mod(v+10.0_cp,1.0_cp)

       return
    End Function Modulo_Lat

End Submodule CFML_Math_001
