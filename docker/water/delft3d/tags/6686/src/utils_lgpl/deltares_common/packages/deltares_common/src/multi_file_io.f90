! opening, reading and closing files from gfortran.
! permits multiple, independent handles to the same file 
! in conjunction with CUTIL_MF_OPEN en CUTIL_MF_READ in cutil.c

      module multi_file_io
      implicit none 

      private
        
      public :: mf_open                 ! open existing file, obtain file handle  
      public :: mf_read                 ! read from file by file handle 
      public :: mf_backspace            ! fortran's backspace 
      public :: mf_rewind               !           rewind file 
      public :: mf_close                ! close a file handle 
!     public :: mf_inquire              ! mimics fortran's inquire
      public :: mf_eof                  ! end-of_file reached ??
      
      integer(kind=4) :: max_open_files              = 2048    ! max nr. of open files (high value needed for
                                                               ! models with many boundaries/laterals)
      logical         :: max_open_files_has_been_set = .false. ! has max nr. of open files been increased?
 
      contains 

        function mf_open(fname) result (fptr)
        implicit none 
        integer(kind=8)             ::      fptr 
        character(len=*),intent(in) ::      fname 
        integer(kind=4)             :: CUTIL_MF_SETMAXSTDIO
        integer(kind=4)             :: ret_val
        integer(kind=8)             :: CUTIL_MF_OPEN
        logical :: exist

        fptr=0
        if (.not. max_open_files_has_been_set) then
           ret_val = CUTIL_MF_SETMAXSTDIO(max_open_files)
           if (ret_val /= max_open_files) then
              max_open_files_has_been_set = .true.
              return
           endif
        endif

        inquire(file=trim(fname),exist=exist)

        if (exist) then 
          fptr = CUTIL_MF_OPEN(trim(fname)//achar(0)) 
        endif 
        end function mf_open

        subroutine mf_rewind(fptr)
        implicit none 
        integer(kind=8),intent(in)  ::      fptr    
        integer  ::  res
        integer :: CUTIL_MF_REWIND
        res = CUTIL_MF_REWIND(fptr)
        end subroutine mf_rewind

        subroutine mf_backspace(fptr, currentpos)
        implicit none 
        integer(kind=8),intent(in)  ::      fptr    
        integer(kind=8),intent(in)  ::      currentpos    
        integer  ::  res
        integer :: CUTIL_MF_BACKSPACE
        res = CUTIL_MF_BACKSPACE(fptr,currentpos)
        end subroutine mf_backspace

        subroutine mf_read(fptr,strout,savepos)
        implicit none 
        integer(kind=8),            intent(in)       ::  fptr    
        character(len=*),           intent(out)      ::  strout
        integer(kind=8), optional,  intent(out)      ::  savepos
        integer :: res 
        integer :: CUTIL_MF_READ
        integer :: strlen, lfindex, crindex 
        integer :: lastpos 
        strout = '     '
        if (present(savepos)) then 
           res = CUTIL_MF_READ(fptr,strout,savepos)        ! pass the starting position of read back to the caller   
        else 
           res = CUTIL_MF_READ(fptr,strout,lastpos)        ! disregard starting position of read 
        endif 
        lfindex = index(strout,achar(10))
        crindex = index(strout,achar(13))
        strlen=len_trim(strout)
        if (lfindex>0) then 
           strlen=min(strlen,lfindex) 
        endif 
        if (crindex>0) then 
           strlen=min(strlen,crindex) 
        endif 
        strout=strout(1:strlen-1)
        end subroutine mf_read


        subroutine mf_close(fptr)
        implicit none 
        integer(kind=8),intent(in)  ::      fptr    
        integer :: res 
        integer :: CUTIL_MF_CLOSE
        res = CUTIL_MF_CLOSE(fptr)
        end subroutine mf_close


!        
!  inquiry of files to be added later       
!        

        !subroutine mf_inquire(fptr,iostat,err,opened,exist)
        !implicit none 
        !integer,            intent(in)      ::      fptr 
        !integer, optional,  intent(out)     ::      iostat
        !integer, optional,  intent(out)     ::      err
        !integer, optional,  intent(out)     ::      opened
        !integer, optional,  intent(out)     ::      exist
        !
        !if (present(iostat)) then 
        !endif 
        !
        !if (present(err)) then 
        !endif 
        !
        !if (present(opened)) then 
        !endif 
        !
        !if (present(exist)) then 
        !endif 
        !end subroutine mf_inquire 
        !

        function  mf_eof(fptr) result (is_eof)
        implicit none 
        logical                     ::      is_eof
        integer(kind=8),intent(in)  ::      fptr    
        integer  ::  CUTIL_MF_EOF
        is_eof = (CUTIL_MF_EOF(fptr)/=0)
        end function mf_eof
        
      end module multi_file_io
