Module CFML_Atomic_Data

  Integer, Dimension(:,:), Allocatable :: Common_OxStates_Table, OxStates_Table
  Real(kind=8), Dimension(:), Allocatable :: PaulingX

Contains

  Subroutine Set_Common_Oxidation_States_Table()

    If (.Not. Allocated(Common_OxStates_Table)) Allocate(Common_OxStates_Table(8,108))
    
    Common_OxStates_Table(:,  1) = (/ -1 ,  1 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:,  2) = (/  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:,  3) = (/  1 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:,  4) = (/  2 ,  1 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:,  5) = (/  3 ,  1 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:,  6) = (/ -4 , -3 , -2 , -1 ,  1 ,  2 ,  3 ,  4 /)
    Common_OxStates_Table(:,  7) = (/ -3 ,  3 ,  5 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:,  8) = (/ -2 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:,  9) = (/ -1 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 10) = (/  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 11) = (/  1 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 12) = (/  2 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 13) = (/  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 14) = (/ -4 ,  4 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 15) = (/ -3 ,  3 ,  5 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 16) = (/ -2 ,  2 ,  4 ,  6 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 17) = (/ -1 ,  1 ,  3 ,  5 ,  7 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 18) = (/  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 19) = (/  1 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 20) = (/  2 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 21) = (/  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 22) = (/  4 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 23) = (/  5 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 24) = (/  3 ,  6 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 25) = (/  2 ,  4 ,  7 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 26) = (/  2 ,  3 ,  6 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 27) = (/  2 ,  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 28) = (/  2 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 29) = (/  2 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 30) = (/  2 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 31) = (/  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 32) = (/ -4 ,  2 ,  4 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 33) = (/ -3 ,  3 ,  5 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 34) = (/ -2 ,  2 ,  4 ,  6 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 35) = (/ -1 ,  1 ,  3 ,  5 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 36) = (/  2 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 37) = (/  1 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 38) = (/  2 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 39) = (/  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 40) = (/  4 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 41) = (/  5 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 42) = (/  4 ,  6 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 43) = (/  4 ,  7 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 44) = (/  3 ,  4 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 45) = (/  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 46) = (/  2 ,  4 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 47) = (/  1 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 48) = (/  2 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 49) = (/  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 50) = (/ -4 ,  2 ,  4 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 51) = (/ -3 ,  3 ,  5 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 52) = (/ -2 ,  2 ,  4 ,  6 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 53) = (/ -1 ,  1 ,  3 ,  5 ,  7 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 54) = (/  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 55) = (/  1 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 56) = (/  2 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 57) = (/  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 58) = (/  3 ,  4 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 59) = (/  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 60) = (/  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 61) = (/  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 62) = (/  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 63) = (/  2 ,  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 64) = (/  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 65) = (/  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 66) = (/  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 67) = (/  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 68) = (/  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 69) = (/  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 70) = (/  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 71) = (/  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 72) = (/  4 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 73) = (/  5 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 74) = (/  4 ,  6 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 75) = (/  4 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 76) = (/  4 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 77) = (/  3 ,  4 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 78) = (/  2 ,  4 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 79) = (/  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 80) = (/  1 ,  2 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 81) = (/  1 ,  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 82) = (/  2 ,  4 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 83) = (/  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 84) = (/ -2 ,  2 ,  4 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 85) = (/ -1 ,  1 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 86) = (/  2 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 87) = (/  1 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 88) = (/  2 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 89) = (/  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 90) = (/  4 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 91) = (/  5 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 92) = (/  6 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 93) = (/  5 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 94) = (/  4 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 95) = (/  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 96) = (/  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 97) = (/  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 98) = (/  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:, 99) = (/  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:,100) = (/  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:,101) = (/  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:,102) = (/  2 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:,103) = (/  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:,104) = (/  4 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:,105) = (/  5 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:,106) = (/  6 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:,107) = (/  7 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    Common_OxStates_Table(:,108) = (/  8 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)

  End Subroutine Set_Common_Oxidation_States_Table

  Subroutine Set_Oxidation_States_Table()
    
    If (.Not. Allocated(OxStates_Table)) Allocate(OxStates_Table(11,108))

    OxStates_Table(:,  1) = (/ -1 ,  1 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:,  2) = (/  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:,  3) = (/  1 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:,  4) = (/  1 ,  2 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:,  5) = (/ -5 , -1 ,  1 ,  2 ,  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:,  6) = (/ -4 , -3 , -2 , -1 ,  1 ,  2 ,  3 ,  4 ,  0 ,  0 ,  0 /)
    OxStates_Table(:,  7) = (/ -3 , -2 , -1 ,  1 ,  2 ,  3 ,  4 ,  5 ,  0 ,  0 ,  0 /)
    OxStates_Table(:,  8) = (/ -2 , -1 ,  1 ,  2 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:,  9) = (/ -1 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 10) = (/  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 11) = (/ -1 ,  1 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 12) = (/  1 ,  2 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 13) = (/ -2 , -1 ,  1 ,  2 ,  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 14) = (/ -4 , -3 , -2 , -1 ,  1 ,  2 ,  3 ,  4 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 15) = (/ -3 , -2 , -1 ,  1 ,  2 ,  3 ,  4 ,  5 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 16) = (/ -2 , -1 ,  1 ,  2 ,  3 ,  4 ,  5 ,  6 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 17) = (/ -1 ,  1 ,  2 ,  3 ,  4 ,  5 ,  6 ,  7 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 18) = (/  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 19) = (/ -1 ,  1 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 20) = (/ -1 ,  1 ,  2 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 21) = (/  1 ,  2 ,  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 22) = (/ -2 , -1 ,  1 ,  2 ,  3 ,  4 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 23) = (/ -3 , -1 ,  1 ,  2 ,  3 ,  4 ,  5 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 24) = (/ -4 , -2 , -1 ,  1 ,  2 ,  3 ,  4 ,  5 ,  6 ,  0 ,  0 /)
    OxStates_Table(:, 25) = (/ -3 , -2 , -1 ,  1 ,  2 ,  3 ,  4 ,  5 ,  6 ,  7 ,  0 /)
    OxStates_Table(:, 26) = (/ -4 , -2 , -1 ,  1 ,  2 ,  3 ,  4 ,  5 ,  6 ,  0 ,  0 /)
    OxStates_Table(:, 27) = (/ -3 , -1 ,  1 ,  2 ,  3 ,  4 ,  5 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 28) = (/ -2 , -1 ,  1 ,  2 ,  3 ,  4 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 29) = (/ -2 ,  1 ,  2 ,  3 ,  4 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 30) = (/ -2 ,  1 ,  2 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 31) = (/ -5 , -4 , -2 , -1 ,  1 ,  2 ,  3 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 32) = (/ -4 , -3 , -2 , -1 ,  1 ,  2 ,  3 ,  4 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 33) = (/ -3 , -2 , -1 ,  1 ,  2 ,  3 ,  4 ,  5 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 34) = (/ -2 , -1 ,  1 ,  2 ,  3 ,  4 ,  5 ,  6 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 35) = (/ -1 ,  1 ,  3 ,  4 ,  5 ,  7 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 36) = (/  2 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 37) = (/ -1 ,  1 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 38) = (/  1 ,  2 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 39) = (/  1 ,  2 ,  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 40) = (/ -2 ,  1 ,  2 ,  3 ,  4 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 41) = (/ -3 , -1 ,  1 ,  2 ,  3 ,  4 ,  5 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 42) = (/ -4 , -2 , -1 ,  1 ,  2 ,  3 ,  4 ,  5 ,  6 ,  0 ,  0 /)
    OxStates_Table(:, 43) = (/ -3 , -1 ,  1 ,  2 ,  3 ,  4 ,  5 ,  6 ,  7 ,  0 ,  0 /)
    OxStates_Table(:, 44) = (/ -4 , -2 ,  1 ,  2 ,  3 ,  4 ,  5 ,  6 ,  7 ,  8 ,  0 /)
    OxStates_Table(:, 45) = (/ -3 , -1 ,  1 ,  2 ,  3 ,  4 ,  5 ,  6 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 46) = (/  1 ,  2 ,  3 ,  4 ,  5 ,  6 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 47) = (/ -2 , -1 ,  1 ,  2 ,  3 ,  4 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 48) = (/ -2 ,  1 ,  2 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 49) = (/ -5 , -2 , -1 ,  1 ,  2 ,  3 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 50) = (/ -4 , -3 , -2 , -1 ,  1 ,  2 ,  3 ,  4 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 51) = (/ -3 , -2 , -1 ,  1 ,  2 ,  3 ,  4 ,  5 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 52) = (/ -2 , -1 ,  1 ,  2 ,  3 ,  4 ,  5 ,  6 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 53) = (/ -1 ,  1 ,  3 ,  4 ,  5 ,  6 ,  7 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 54) = (/  2 ,  4 ,  6 ,  8 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 55) = (/ -1 ,  1 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 56) = (/  1 ,  2 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 57) = (/  1 ,  2 ,  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 58) = (/  2 ,  3 ,  4 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 59) = (/  2 ,  3 ,  4 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 60) = (/  2 ,  3 ,  4 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 61) = (/  2 ,  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 62) = (/  2 ,  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 63) = (/  2 ,  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 64) = (/  1 ,  2 ,  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 65) = (/  1 ,  2 ,  3 ,  4 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 66) = (/  2 ,  3 ,  4 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 67) = (/  2 ,  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 68) = (/  2 ,  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 69) = (/  2 ,  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 70) = (/  2 ,  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 71) = (/  2 ,  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 72) = (/ -2 ,  1 ,  2 ,  3 ,  4 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 73) = (/ -3 , -1 ,  1 ,  2 ,  3 ,  4 ,  5 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 74) = (/ -4 , -2 , -1 ,  1 ,  2 ,  3 ,  4 ,  5 ,  6 ,  0 ,  0 /)
    OxStates_Table(:, 75) = (/ -3 , -1 ,  1 ,  2 ,  3 ,  4 ,  5 ,  6 ,  7 ,  0 ,  0 /)
    OxStates_Table(:, 76) = (/ -4 , -2 , -1 ,  1 ,  2 ,  3 ,  4 ,  5 ,  6 ,  7 ,  8 /)
    OxStates_Table(:, 77) = (/ -3 , -1 ,  1 ,  2 ,  3 ,  4 ,  5 ,  6 ,  7 ,  8 ,  9 /)
    OxStates_Table(:, 78) = (/ -3 , -2 , -1 ,  1 ,  2 ,  3 ,  4 ,  5 ,  6 ,  0 ,  0 /)
    OxStates_Table(:, 79) = (/ -3 , -2 , -1 ,  1 ,  2 ,  3 ,  5 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 80) = (/ -2 ,  1 ,  2 ,  4 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 81) = (/ -5 , -2 , -1 ,  1 ,  2 ,  3 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 82) = (/ -4 , -2 , -1 ,  1 ,  2 ,  3 ,  4 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 83) = (/ -3 , -2 , -1 ,  1 ,  2 ,  3 ,  4 ,  5 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 84) = (/ -2 ,  2 ,  4 ,  5 ,  6 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 85) = (/ -1 ,  1 ,  3 ,  5 ,  7 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 86) = (/  2 ,  6 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 87) = (/  1 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 88) = (/  2 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 89) = (/  2 ,  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 90) = (/  1 ,  2 ,  3 ,  4 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 91) = (/  2 ,  3 ,  4 ,  5 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 92) = (/  1 ,  2 ,  3 ,  4 ,  5 ,  6 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 93) = (/  2 ,  3 ,  4 ,  5 ,  6 ,  7 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 94) = (/  1 ,  2 ,  3 ,  4 ,  5 ,  6 ,  7 ,  8 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 95) = (/  2 ,  3 ,  4 ,  5 ,  6 ,  7 ,  8 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 96) = (/  2 ,  3 ,  4 ,  6 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 97) = (/  2 ,  3 ,  4 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 98) = (/  2 ,  3 ,  4 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:, 99) = (/  2 ,  3 ,  4 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:,100) = (/  2 ,  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:,101) = (/  2 ,  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:,102) = (/  2 ,  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:,103) = (/  3 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:,104) = (/  4 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:,105) = (/  5 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:,106) = (/  6 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:,107) = (/  7 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)
    OxStates_Table(:,108) = (/  8 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 /)

  End Subroutine Set_Oxidation_States_Table

  Subroutine Set_Pauling_Electronegativity()

    If (.Not. Allocated(PaulingX)) Allocate(PaulingX(108))

    PaulingX(  1) = 2.20
    PaulingX(  2) = 0.00
    PaulingX(  3) = 0.98
    PaulingX(  4) = 1.57
    PaulingX(  5) = 2.04
    PaulingX(  6) = 2.55
    PaulingX(  7) = 3.04
    PaulingX(  8) = 3.44
    PaulingX(  9) = 3.98
    PaulingX( 10) = 0.00
    PaulingX( 11) = 0.93
    PaulingX( 12) = 1.31
    PaulingX( 13) = 1.61
    PaulingX( 14) = 1.90
    PaulingX( 15) = 2.19
    PaulingX( 16) = 2.58
    PaulingX( 17) = 3.16
    PaulingX( 18) = 0.00
    PaulingX( 19) = 0.82
    PaulingX( 20) = 1.00
    PaulingX( 21) = 1.36
    PaulingX( 22) = 1.54
    PaulingX( 23) = 1.63
    PaulingX( 24) = 1.66
    PaulingX( 25) = 1.55
    PaulingX( 26) = 1.83
    PaulingX( 27) = 1.88
    PaulingX( 28) = 1.91
    PaulingX( 29) = 1.90
    PaulingX( 30) = 1.65
    PaulingX( 31) = 1.81
    PaulingX( 32) = 2.01
    PaulingX( 33) = 2.18
    PaulingX( 34) = 2.55
    PaulingX( 35) = 2.96
    PaulingX( 36) = 3.00
    PaulingX( 37) = 0.82
    PaulingX( 38) = 0.95
    PaulingX( 39) = 1.22
    PaulingX( 40) = 1.33
    PaulingX( 41) = 1.60
    PaulingX( 42) = 2.16
    PaulingX( 43) = 1.90
    PaulingX( 44) = 2.20
    PaulingX( 45) = 2.28
    PaulingX( 46) = 2.20
    PaulingX( 47) = 1.93
    PaulingX( 48) = 1.69
    PaulingX( 49) = 1.78
    PaulingX( 50) = 1.96
    PaulingX( 51) = 2.05
    PaulingX( 52) = 2.10
    PaulingX( 53) = 2.66
    PaulingX( 54) = 2.60
    PaulingX( 55) = 0.79
    PaulingX( 56) = 0.89
    PaulingX( 57) = 1.10
    PaulingX( 58) = 1.12
    PaulingX( 59) = 1.13
    PaulingX( 60) = 1.14
    PaulingX( 61) = 1.13
    PaulingX( 62) = 1.17
    PaulingX( 63) = 1.20
    PaulingX( 64) = 1.20
    PaulingX( 65) = 1.10
    PaulingX( 66) = 1.22
    PaulingX( 67) = 1.23
    PaulingX( 68) = 1.24
    PaulingX( 69) = 1.25
    PaulingX( 70) = 1.10
    PaulingX( 71) = 1.27
    PaulingX( 72) = 1.30
    PaulingX( 73) = 1.50
    PaulingX( 74) = 2.36
    PaulingX( 75) = 1.90
    PaulingX( 76) = 2.20
    PaulingX( 77) = 2.20
    PaulingX( 78) = 2.28
    PaulingX( 79) = 2.54
    PaulingX( 80) = 2.00
    PaulingX( 81) = 1.62
    PaulingX( 82) = 1.87
    PaulingX( 83) = 2.02
    PaulingX( 84) = 2.00
    PaulingX( 85) = 2.20
    PaulingX( 86) = 2.20
    PaulingX( 87) = 0.70
    PaulingX( 88) = 0.90
    PaulingX( 89) = 1.10
    PaulingX( 90) = 1.30
    PaulingX( 91) = 1.50
    PaulingX( 92) = 1.38
    PaulingX( 93) = 1.36
    PaulingX( 94) = 1.28
    PaulingX( 95) = 1.13
    PaulingX( 96) = 1.28
    PaulingX( 97) = 1.30
    PaulingX( 98) = 1.30
    PaulingX( 99) = 1.30
    PaulingX(100) = 1.30
    PaulingX(101) = 1.30
    PaulingX(102) = 1.30
    PaulingX(103) = 1.30
    PaulingX(104) = 0.00
    PaulingX(105) = 0.00
    PaulingX(106) = 0.00
    PaulingX(107) = 0.00
    PaulingX(108) = 0.00

  End Subroutine Set_Pauling_Electronegativity

End Module CFML_Atomic_Data
