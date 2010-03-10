!!----
!!---- Copyleft(C) 1999-2009,              Version: 4.0
!!---- Juan Rodriguez-Carvajal & Javier Gonzalez-Platas
!!----
!!---- MODULE: CFML_IO_MESSAGES
!!----   INFO: Input / Output General Messages. It is convenient to use these intermediate procedures instead of
!!----         Fortran Write(*,*) or Print*, because it is much more simple to modify a program for making a GUI.
!!----         Usually GUI tools and libraries need special calls to dialog boxes for screen messages. These
!!----         calls may be implemented within this module using the same name procedures. The subroutines
!!----         ERROR_MESSAGE and INFO_MESSAGE are just wrappers for the actual calls.
!!--..
!!--..         NON-GRAPHICS ZONE
!!--..
!!---- HISTORY
!!----
!!----    Update: February - 2005
!!----            June    - 1999   Updated by JGP
!!----
!!---- DEPENDENCIES
!!----
!!---- VARIABLES
!!----
!!---- PROCEDURES
!!----    Functions:
!!----
!!----    Subroutines:
!!----       ERROR_MESSAGE
!!----       INFO_MESSAGE
!!----       PRINT_MESS
!!----       WAIT_MESS
!!----       WRITE_SCROLL_TEXT
!!----
!!
 Module CFML_IO_Messages
    !---- Use Modules ----!

    !---- Definitions ----!
    implicit none

    !---- List of public subroutines ----!
    public :: Info_Message, Error_Message, Print_Mess, Wait_Mess, write_scroll_text


 Contains

    !!----
    !!---- Subroutine Error_Message(line, Iunit, routine, fatal)
    !!----    character(len=*), intent(in)           :: line          !  In -> Error information
    !!----    integer,          intent(in), optional :: Iunit         !  In -> Write information on Iunit unit
    !!----    character(len=*), intent(in), optional :: routine       !  In -> The subroutine where the error occured
    !!----    logical,          intent(in), optional :: fatal         !  In -> Should the program stop here ?
    !!----
    !!----    Print an error message on the screen or in "Iunit" if present
    !!----    If "routine" is present the subroutine where the occured will be also displayed.
    !!----    If "fatal" is present and .True. the program will stop after the printing.
    !!----
    !!---- Update: January - 2010
    !!
    Subroutine Error_Message(Line, Iunit, Routine, Fatal)
       !---- Arguments ----!
       Character ( Len = * ), Intent(In)           :: Line
       Integer,               Intent(In), Optional :: Iunit
       Character ( Len = * ), Intent(In), Optional :: Routine
       Logical,               Intent(In), Optional :: Fatal

       !---- Local Variables ----!
       Integer :: Lun, Lenm, Lenr

       Lun = 6
       If (Present(Iunit)) Lun = Iunit

       Write(Unit = Lun, Fmt = "(1X,A)") "****"
       Write(Unit = Lun, Fmt = "(1X,A/)") "**** Error"

       If (Present(Routine)) Then
           Lenr = Len_Trim(Routine)
           Write(Unit = Lun, Fmt = "(1X,A)") "**** Subroutine: "//Routine(1:Lenr)
       End If

       Lenm = Len_Trim(Line)
       Write(Unit = Lun, Fmt = "(1X,A)") "**** Message: "//Line(1:Lenm)

       If (Present(Fatal)) Then
           If (Fatal) Then
               Write(Unit = Lun, Fmt = "(/1X,A)") "**** The Program Will Stop Here."
               Stop
           End If
       End If

       Write(Unit = Lun, Fmt = "(A/)") "****"

       Return

    End Subroutine Error_Message

    !!----
    !!---- Subroutine Info_Message(Line, Iunit)
    !!----    character(len=*), intent(in)           :: Line    !  In -> Info information
    !!----    integer,          intent(in), optional :: Iunit   !  In -> Write information on Iunit unit
    !!----
    !!----    Print an message on the screen or in "Iunit" if present
    !!----
    !!---- Update: February - 2005
    !!
    Subroutine Info_Message(line, iunit, scroll_window)
       !---- Arguments ----!
       character(len=*), intent(in)           :: line
       integer,          intent(in), optional :: iunit
       integer,          intent(in), optional :: scroll_window

       !---- Local Variables ----!
       integer :: lun

       lun=6
       if (present(iunit)) lun=iunit
       if (present(scroll_window)) lun=6
       write(unit=lun,fmt="(a)") "  "//line

       return
    End Subroutine Info_Message

    !!----
    !!---- Subroutine Print_Mess(Warning)
    !!----    character(len=*), intent(in)  :: Warning    !  In -> Print information
    !!----
    !!----    Print an message on the screen
    !!----
    !!---- Update: February - 2005
    !!
    Subroutine Print_Mess(Warning)
       !---- Arguments ----!
       character(len=*),intent(in) ::  Warning

       !---- Local Variables ----!
       integer :: lon

       lon=len_trim(Warning)
       if (lon == 0) then
          write(unit=*,fmt="(a)") "  "
       else
          if (warning(1:1) == "=" .or. warning(2:2) == "=") then
             write(unit=*,fmt="(a)") warning(1:lon)
          else
             write(unit=*,fmt="(a,a)")" =>", warning(1:lon)
          end if
       end if

       return
    End Subroutine Print_Mess

    !!----
    !!---- Subroutine Wait_Mess(Message)
    !!----    character(len=*), optional, intent(in) :: Message
    !!----
    !!----    Similar to Pause for Console version
    !!----
    !!---- Update: February - 2005
    !!
    Subroutine Wait_Mess(Message)
       !---- Argument ----!
       character(len=*), optional, intent(in) :: Message

       !---- Local variable ----!
       character(len=1) :: car

       write(unit=*,fmt="(a)") " "
       if (present(message)) write(unit=*,fmt="(a)", advance="no") message
       read(unit=*,fmt="(a)") car
       if( car == " ") return

       return
    End Subroutine Wait_Mess

    !!----
    !!---- SUBROUTINE WRITE_SCROLL_TEXT(Line)
    !!----    character(len=*), intent(in)           :: Line
    !!----
    !!----    Print the string in a the scroll window
    !!----
    !!---- Update: March - 2005
    !!
    Subroutine Write_Scroll_Text(Line)
       !---- Argument ----!
       character(len=*), intent(in) :: line

       write(unit=*, fmt="(a)") trim(line)

       return
    End Subroutine Write_Scroll_Text

 End Module CFML_IO_Messages
