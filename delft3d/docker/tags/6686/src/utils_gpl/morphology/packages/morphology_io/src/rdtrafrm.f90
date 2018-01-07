module m_rdtrafrm
!----- GPL ---------------------------------------------------------------------
!                                                                               
!  Copyright (C)  Stichting Deltares, 2011-2016.                                
!                                                                               
!  This program is free software: you can redistribute it and/or modify         
!  it under the terms of the GNU General Public License as published by         
!  the Free Software Foundation version 3.                                      
!                                                                               
!  This program is distributed in the hope that it will be useful,              
!  but WITHOUT ANY WARRANTY; without even the implied warranty of               
!  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                
!  GNU General Public License for more details.                                 
!                                                                               
!  You should have received a copy of the GNU General Public License            
!  along with this program.  If not, see <http://www.gnu.org/licenses/>.        
!                                                                               
!  contact: delft3d.support@deltares.nl                                         
!  Stichting Deltares                                                           
!  P.O. Box 177                                                                 
!  2600 MH Delft, The Netherlands                                               
!                                                                               
!  All indications and logos of, and references to, "Delft3D" and "Deltares"    
!  are registered trademarks of Stichting Deltares, and remain the property of  
!  Stichting Deltares. All rights reserved.                                     
!                                                                               
!-------------------------------------------------------------------------------
!  $Id: rdtrafrm.f90 5717 2016-01-12 11:35:24Z mourits $
!  $HeadURL: https://svn.oss.deltares.nl/repos/delft3d/tags/6686/src/utils_gpl/morphology/packages/morphology_io/src/rdtrafrm.f90 $
!-------------------------------------------------------------------------------

private

public initrafrm
public rdtrafrm
public setpardef
public echotrafrm

interface setpardef
   module procedure setpardeflog
   module procedure setpardefint
   module procedure setpardefreal
end interface setpardef   

contains

subroutine initrafrm(lundia    ,error     ,lsedtot   ,trapar    )
!!--description-----------------------------------------------------------------
!
! Reads transport formula and parameters
!
!!--declarations----------------------------------------------------------------
    use precision
    use morphology_data_module, only: trapar_type, MAX_RP, MAX_IP, MAX_SP, WS_MAX_RP, WS_MAX_IP, WS_MAX_SP
    use message_module
    !
    implicit none
    !
! Call variables
    !
    integer                   , intent(in)   :: lundia
    logical                   , intent(out)  :: error
    integer                   , intent(in)   :: lsedtot !  Description and declaration in iidim.f90
    type (trapar_type)        , pointer      :: trapar
!
! Local variables
!
    integer                          , pointer :: max_integers
    integer                          , pointer :: max_reals
    integer                          , pointer :: max_strings
    integer                          , pointer :: max_integers_settle
    integer                          , pointer :: max_reals_settle
    integer                          , pointer :: max_strings_settle
    integer                          , pointer :: npar
    character(256)   , dimension(:)  , pointer :: dll_function_settle
    character(256)   , dimension(:)  , pointer :: dll_name_settle
    integer(pntrsize), dimension(:)  , pointer :: dll_handle_settle
    integer          , dimension(:)  , pointer :: dll_integers_settle
    real(hp)         , dimension(:)  , pointer :: dll_reals_settle
    character(256)   , dimension(:)  , pointer :: dll_strings_settle
    character(256)   , dimension(:)  , pointer :: dll_usrfil_settle
    integer          , dimension(:)  , pointer :: iform_settle
    real(fp)         , dimension(:,:), pointer :: par_settle
    character(256)   , dimension(:)  , pointer :: dll_function
    character(256)   , dimension(:)  , pointer :: dll_name
    integer(pntrsize), dimension(:)  , pointer :: dll_handle
    integer          , dimension(:)  , pointer :: dll_integers
    real(hp)         , dimension(:)  , pointer :: dll_reals
    character(256)   , dimension(:)  , pointer :: dll_strings
    character(256)   , dimension(:)  , pointer :: dll_usrfil
    character(256)   , dimension(:)  , pointer :: flstrn
    integer          , dimension(:)  , pointer :: iform
    character(256)   , dimension(:)  , pointer :: name
    real(fp)         , dimension(:,:), pointer :: par
    character(256)   , dimension(:,:), pointer :: parfil
    integer          , dimension(:,:), pointer :: iparfld
!
    integer                        :: istat
    character(256)                 :: errmsg
!
!! executable statements -------------------------------------------------------
!
    max_integers         => trapar%max_integers
    max_reals            => trapar%max_reals
    max_strings          => trapar%max_strings
    max_integers_settle  => trapar%max_integers_settle
    max_reals_settle     => trapar%max_reals_settle
    max_strings_settle   => trapar%max_strings_settle
    npar                 => trapar%npar
    !
    istat = 0
    if (.not. associated(trapar%par)) then
                     allocate (trapar%par    (npar,lsedtot), stat = istat)
       if (istat==0) allocate (trapar%parfil (npar,lsedtot), stat = istat)
       if (istat==0) allocate (trapar%iparfld(npar,lsedtot), stat = istat)
       if (istat==0) allocate (trapar%iform       (lsedtot), stat = istat)
       if (istat==0) allocate (trapar%flstrn      (lsedtot), stat = istat)
       if (istat==0) allocate (trapar%name        (lsedtot), stat = istat)
       !
       max_integers = MAX_IP
       max_reals    = MAX_RP
       max_strings  = MAX_SP
       if (istat==0) allocate (trapar%dll_handle  (lsedtot), stat = istat)
       if (istat==0) allocate (trapar%dll_name    (lsedtot), stat = istat)
       if (istat==0) allocate (trapar%dll_function(lsedtot), stat = istat)
       if (istat==0) allocate (trapar%dll_usrfil  (lsedtot), stat = istat)
       if (istat==0) allocate (trapar%dll_integers(max_integers), stat = istat)
       if (istat==0) allocate (trapar%dll_reals   (max_reals   ), stat = istat)
       if (istat==0) allocate (trapar%dll_strings (max_strings ), stat = istat)
       !
       max_integers_settle = WS_MAX_IP
       max_reals_settle    = WS_MAX_RP
       max_strings_settle  = WS_MAX_SP
       if (istat==0) allocate (trapar%dll_handle_settle  (lsedtot), stat = istat)
       if (istat==0) allocate (trapar%dll_name_settle    (lsedtot), stat = istat)
       if (istat==0) allocate (trapar%dll_function_settle(lsedtot), stat = istat)
       if (istat==0) allocate (trapar%dll_usrfil_settle  (lsedtot), stat = istat)
       if (istat==0) allocate (trapar%dll_integers_settle(max_integers_settle), stat = istat)
       if (istat==0) allocate (trapar%dll_reals_settle   (max_reals_settle   ), stat = istat)
       if (istat==0) allocate (trapar%dll_strings_settle (max_strings_settle ), stat = istat)
       if (istat==0) allocate (trapar%iform_settle       (lsedtot), stat = istat)
       if (istat==0) allocate (trapar%par_settle         (npar,lsedtot), stat = istat)
       !
       if (istat/=0) then
          errmsg = 'IniTraFrm: memory alloc error'
          call write_error(errmsg, unit=lundia)
          error = .true.
          return
       endif
    endif
    !
    par           => trapar%par
    parfil        => trapar%parfil
    iparfld       => trapar%iparfld
    iform         => trapar%iform
    flstrn        => trapar%flstrn
    name          => trapar%name
    !
    iform   = -999
    flstrn  = ' '
    name    = ' '
    par     = 0.0_fp
    parfil  = ' '
    iparfld = 0
    !
    dll_function  => trapar%dll_function
    dll_name      => trapar%dll_name
    dll_handle    => trapar%dll_handle
    dll_usrfil    => trapar%dll_usrfil
    dll_integers  => trapar%dll_integers
    dll_reals     => trapar%dll_reals
    dll_strings   => trapar%dll_strings
    !
    dll_function  = ' '
    dll_name      = ' '
    dll_handle    = 0
    dll_usrfil    = ' '
    dll_integers  = 0
    dll_reals     = 0.0_hp
    dll_strings   = ' '
    !
    dll_function_settle  => trapar%dll_function_settle
    dll_name_settle      => trapar%dll_name_settle
    dll_handle_settle    => trapar%dll_handle_settle
    dll_usrfil_settle    => trapar%dll_usrfil_settle
    dll_integers_settle  => trapar%dll_integers_settle
    dll_reals_settle     => trapar%dll_reals_settle
    dll_strings_settle   => trapar%dll_strings_settle
    iform_settle         => trapar%iform_settle
    par_settle           => trapar%par_settle
    !
    dll_function_settle  = ' '
    dll_name_settle      = ' '
    dll_handle_settle    = 0
    dll_usrfil_settle    = ' '
    dll_integers_settle  = 0
    dll_reals_settle     = 0.0_hp
    dll_strings_settle   = ' '
    iform_settle         = 0
    par_settle           = 0.0_fp
end subroutine initrafrm


subroutine rdtrafrm(lundia    ,error     ,filtrn    ,lsedtot   , &
                  & ipardef   ,rpardef   ,npardef   ,trapar    , &
                  & sedtyp    ,sedblock  ,dims      )
!!--description-----------------------------------------------------------------
!
! Reads transport formula and parameters
!
!!--declarations----------------------------------------------------------------
    use precision
    use sediment_basics_module, only: SEDTYP_COHESIVE
    use morphology_data_module
    use properties, only: tree_data
    use grid_dimens_module 
    !
    implicit none
    !
    ! Call variables
    !
    integer                      , intent(in)   :: npardef
    integer                      , intent(in)   :: lundia
    logical                      , intent(out)  :: error
    integer                      , intent(in)   :: lsedtot !  Description and declaration in iidim.f90
    type (trapar_type)           , target       :: trapar
    character(*)                 , intent(in)   :: filtrn
    integer, dimension(2,npardef), intent(in)   :: ipardef
    real(fp), dimension(npardef) , intent(in)   :: rpardef
    integer, dimension(:)        , intent(in)   :: sedtyp
    type(tree_data), dimension(:), intent(in)   :: sedblock
    type (griddimtype), target   , intent(in)   :: dims    !  grid dimensions
!
! Local variables
!
    integer                        , pointer :: max_integers
    integer                        , pointer :: max_reals
    integer                        , pointer :: max_strings
    integer                        , pointer :: max_integers_settle
    integer                        , pointer :: max_reals_settle
    integer                        , pointer :: max_strings_settle
    integer                        , pointer :: npar
    integer                        , pointer :: nparfld
    character(256), dimension(:)   , pointer :: dll_name
    character(256), dimension(:)   , pointer :: dll_function
    integer(pntrsize), dimension(:), pointer :: dll_handle
    integer       , dimension(:)   , pointer :: dll_integers
    real(hp)      , dimension(:)   , pointer :: dll_reals
    character(256), dimension(:)   , pointer :: dll_strings
    character(256), dimension(:)   , pointer :: dll_usrfil
    character(256), dimension(:)   , pointer :: flstrn
    integer,        dimension(:)   , pointer :: iform
    character(256), dimension(:)   , pointer :: name
    real(fp),       dimension(:,:) , pointer :: par
    character(256), dimension(:,:) , pointer :: parfil
    integer,        dimension(:,:) , pointer :: iparfld
    !
    integer           :: i
    integer           :: iform1tmp
    integer           :: iformdef
    integer           :: ll
    character(256)    :: errmsg
!
!! executable statements -------------------------------------------------------
!
    max_integers         => trapar%max_integers
    max_reals            => trapar%max_reals
    max_strings          => trapar%max_strings
    max_integers_settle  => trapar%max_integers_settle
    max_reals_settle     => trapar%max_reals_settle
    max_strings_settle   => trapar%max_strings_settle
    npar                 => trapar%npar
    nparfld              => trapar%nparfld
    !
    iform         => trapar%iform
    flstrn        => trapar%flstrn
    name          => trapar%name
    par           => trapar%par
    parfil        => trapar%parfil
    iparfld       => trapar%iparfld
    !
    dll_name      => trapar%dll_name
    dll_function  => trapar%dll_function
    dll_handle    => trapar%dll_handle
    dll_usrfil    => trapar%dll_usrfil
    dll_integers  => trapar%dll_integers
    dll_reals     => trapar%dll_reals
    dll_strings   => trapar%dll_strings
    !
    error = .false.
    !
    write (lundia, *)
    write (lundia, '(a)') 'Determining transport formulation(s)'
    !
    ! for cohesive sediment fractions formula -3 (Partheniades-Krone) is the default formula
    !
    do ll=1, lsedtot
       if (sedtyp(ll)==SEDTYP_COHESIVE .and. iform(ll)==-999) iform(ll) = -3
    enddo
    !
    ! back=up value of iform(1) because the first index will be used to load
    ! the default sediment transport settings.
    !
    iform1tmp = iform(1)
    if (filtrn == ' ') then
       ! keyword not specified, using Van Rijn (1993) as default
       iform(1) = -1
    else
       write (lundia, '(a,a)') 'Reading: ',trim(filtrn)
    endif
    call rdtrafrm0(lundia    ,error     ,iform     ,npar      ,par       , &
                 & parfil    ,iparfld   ,nparfld   ,0         , &
                 & filtrn    ,name      ,dll_handle,dll_name  ,dll_function, &
                 & dll_usrfil,ipardef   ,rpardef   ,npardef   ,sedblock  )
    iformdef = iform(1)
    do ll=2, lsedtot
       if (iform(ll)==-999 .and. flstrn(ll)==' ') then
          name        (ll) = name(1)
          dll_handle  (ll) = dll_handle(1)
          dll_function(ll) = dll_function(1)
          dll_usrfil  (ll) = dll_usrfil(1)
          do i = 1,npar
             par(i,ll)     = par(i,1)
             parfil(i,ll)  = parfil(i,1)
             iparfld(i,ll) = iparfld(i,1)
          enddo
       endif
    enddo
    !
    ! restore the iform(1) value if it had a specified value
    !
    iform(1) = iform1tmp
    if (iform1tmp/=-999 .or. flstrn(1)/=' ') then
       name(1) = ' '
       dll_handle(1) = 0
       dll_function(1) = ' '
       dll_usrfil(1) = ' '
       par(:,1) = 0.0_fp
       parfil(:,1) = ' '
       iparfld(:,1) = 0
    endif
    !
    do ll = 1,lsedtot
       if (flstrn(ll) /= ' ') write (lundia, '(a,a)') 'Reading: ',trim(flstrn(ll))
       if (flstrn(ll) /= ' ' .or. iform(ll)/=-999) then
          call rdtrafrm0(lundia    ,error     ,iform     ,npar      ,par       , &
                       & parfil    ,iparfld   ,nparfld   ,ll        , &
                       & flstrn(ll),name      ,dll_handle,dll_name  ,dll_function, &
                       & dll_usrfil,ipardef   ,rpardef   ,npardef   ,sedblock  )
       else
          iform(ll) = iformdef
       endif
       if (error) return
    enddo
    !
    call rdtraparfld(lundia    ,error     ,lsedtot   ,trapar    , &
                   & dims      )
    write (lundia, *)
    !
end subroutine rdtrafrm


subroutine rdtrafrm0(lundia    ,error     ,iform     ,npar      ,par       , &
                   & parfil    ,iparfld   ,nparfld   ,ifrac     , &
                   & flname    ,name      ,dll_handle,dll_name  ,dll_func  , &
                   & dll_usrfil,ipardef   ,rpardef   ,npardef   ,sedblock  )
!!--description-----------------------------------------------------------------
!
! Reads transport formula and parameters
!
!!--declarations----------------------------------------------------------------
    use precision
    use properties
    use string_module
    use message_module
    use system_utils, only:SHARED_LIB_EXTENSION
    !
    implicit none
!
! Call variables
!
    integer                       , intent(in)   :: npardef
    integer                                      :: lundia  !  Description and declaration in inout.igs
    logical                       , intent(out)  :: error
    integer, dimension(:)                        :: iform
    integer                       , intent(in)   :: npar
    integer(pntrsize), dimension(:)              :: dll_handle
    real(fp)    , dimension(:,:)                 :: par
    character(*), dimension(:,:)                 :: parfil
    integer     , dimension(:,:)                 :: iparfld
    integer                                      :: nparfld
    integer                       , intent(in)   :: ifrac
    character(*)                                 :: flname
    character(*), dimension(:)                   :: name
    character(*), dimension(:)                   :: dll_name
    character(*), dimension(:)                   :: dll_func
    character(*), dimension(:)                   :: dll_usrfil
    integer, dimension(2,npardef) , intent(in)   :: ipardef
    real(fp), dimension(npardef)  , intent(in)   :: rpardef
    type(tree_data), dimension(:) , intent(in)   :: sedblock
!
! Local variables
!
    integer                        :: i
    integer                        :: inp
    integer                        :: iost
    integer                        :: istat
    integer                        :: l
    integer                        :: lfile
    integer                        :: nparreq
    integer                        :: nparopt
    integer                        :: version
    integer        , external      :: newunit
    integer        , external      :: open_shared_library
    logical                        :: lex
    real(fp)                       :: nodef
    real(fp)       , dimension(30) :: pardef
    character(3)                   :: key
    character(25)  , dimension(30) :: parkeyw
    character(10)                  :: versionstring
    character(80)                  :: string
    character(256)                 :: errmsg
    character(256)                 :: rec
    character(256)                 :: parfile
    type(tree_data), pointer       :: tran_ptr
    type(tree_data), pointer       :: sed_ptr
!
!! executable statements -------------------------------------------------------
!
    ! ifrac will be 0 for the default transport formula, put data in 1 index instead
    !
    l = max(ifrac,1)
    allocate(sed_ptr)
    sed_ptr = sedblock(l)
    !
    if (flname == ' ') then
       ! don't read any file, just use defaults
       version = -1
    else
       write (lundia, '(a,a)') '    Input file                   : ',trim(flname)
       call remove_leading_spaces(flname, lfile)
       !
       inquire (file = flname(1:lfile), exist = lex)
       !
       if (.not.lex) then
          errmsg = 'TraFrm file '//trim(flname)//' does not exist'
          call write_error(errmsg, unit=lundia)
          error = .true.
          return
       endif
       !
       ! Create TransportFormula branch in input tree
       !
       call tree_create( 'TransportFormula Input', tran_ptr )
       call tree_put_data( tran_ptr, transfer(trim(flname),node_value), 'STRING' )
       !
       ! Put trafrm-file in input tree
       !
       call prop_file('ini',trim(flname),tran_ptr,istat)
       if (istat /= 0) then
          select case (istat)
          case(1)
             errmsg = FILE_NOT_FOUND // trim(flname)
             call write_error(errmsg, unit=lundia)
          case(3)
             errmsg = PREMATURE_EOF // trim(flname)
             call write_error(errmsg, unit=lundia)
          case default
             errmsg = FILE_READ_ERROR // trim(flname)
             call write_error(errmsg, unit=lundia)
          endselect
          error = .true.
          return
       endif
       !
       ! Check version number of trafrm-file
       !
       version = 0
       versionstring = '00.00'
       call prop_get_string(tran_ptr,'TransportFormulaFileInformation','FileVersion',versionstring)
       if (trim(versionstring) == '01.00') then
          write (lundia, '(a,a)') '    Version number of input file  : ', trim(versionstring)
          version = 1
          !
          rec  = ' '
          call prop_get_string(tran_ptr,'TransportFormula','DLL',rec)
          dll_name(l) = rec
          if (rec /= ' ') then
             name(l) = ' '
             call prop_get_string(tran_ptr,'TransportFormula','Name',name(l))
             !
             iform(l) = 15
             rec(len_trim(rec)+1:) = SHARED_LIB_EXTENSION
             !
             ! Get handle to the DLL
             !
             istat = 0
             istat = open_shared_library(dll_handle(l), rec)
             if (istat /= 0) then
                errmsg = 'Can not open shared library '//trim(rec)
                call write_error(errmsg, unit=lundia)
                error = .true.
                return
             endif
             dll_func(l) = ' '
             call prop_get_string(tran_ptr,'TransportFormula','function',dll_func(l))
             !
             dll_usrfil(l) = ' '
             call prop_get_string(tran_ptr,'TransportFormula','InputFile',dll_usrfil(l))
          else
             iform(l) = -999
             call prop_get(tran_ptr,'TransportFormula','Number',iform(l))
             if (iform(l) == -999) then
                errmsg = 'Unable to find transport formula information in '//trim(flname)
                call write_error(errmsg, unit=lundia)
                error = .true.
                return
             endif
             write (lundia, '(a,i3)') '    Transport formula used =', iform(l)
          endif
       else
          write (lundia, '(a)') '    File in traditional MOR-format.'
          !
          inp = newunit()
          open (inp, file = flname(1:lfile),status = 'old', iostat = iost)
          if (iost/=0) then
             errmsg = FILE_NOT_FOUND // flname(1:lfile)
             call write_error(errmsg, unit=lundia)
             error = .true.
             return
          endif
          string = ' '
          read (inp, '(a)', iostat = iost) string
          do while (index(string, 'IFORM')==0 .and. iost==0)
             read (inp, '(a)', iostat = iost) string
          enddo
          if (iost==0) then
             backspace (inp)
             read (inp, *, iostat = iost) iform(l)
          endif
          if (iost/=0) then
             errmsg = 'Unable to locate transport formula number IFORM'
             call write_error(errmsg, unit=lundia)
             error = .true.
             return
          endif
          !
          if (iform(l)>=0 .and. iform(l)<10) then
             write (key, '(a,i1)') '#', iform(l)
          else
             write (key, '(a,i2)') '#', iform(l)
          endif
          read (inp, '(a)', iostat = iost) string
          do while (index(string, key)==0 .and. iost==0)
             read (inp, '(a)', iostat = iost) string
          enddo
          if (iost/=0 .and. iform(l)>0) then
             errmsg = 'Transport formula parameters not found'
             call write_error(errmsg, unit=lundia)
             error = .true.
             return
          endif
       endif
    endif
    !
    ! Get transport formula name, parameter names and default values
    !
    call traparams(iform(l),name(l),nparreq   ,nparopt   ,parkeyw   , &
                 & pardef    ,nodef     )
    if (name(l) == ' ') then
       error      = .true.
       write(errmsg,'(A,I0,A)') 'Transport formula number ',iform(l),' is not implemented'
       call write_error(errmsg, unit=lundia)
       return
    endif
    !
    ! Overrule default values with values read from mor file
    !
    call getpardef(ipardef   ,rpardef   ,npardef   ,iform(l),pardef    )
    !
    par(:,l) = 0
    if (version==0) then
       do i = 1, nparreq
          read (inp, *) par(10+i,l)
       enddo
    else
       nparopt = nparreq+nparopt
       nparreq = 0
    endif
    do i = nparreq+1, nparreq+nparopt
       if (version==0) then
          read(inp,*,iostat=iost) par(10+i,l)
          if (iost/=0) par(10+i,l) = pardef(i)
       elseif (version==1) then
          par(10+i,l) = pardef(i)
          !
          parfile = ' '
          call prop_get(tran_ptr,'TransportFormula',parkeyw(i),parfile)
          if (parfile /= ' ') then
             call combinepaths(flname, parfile)
             inquire (file = parfile, exist = lex)
             if (lex) then
                parfil(10+i,l) = parfile
                nparfld = nparfld+1
                iparfld(10+i,l) = nparfld
             else
                call prop_get(tran_ptr,'TransportFormula',parkeyw(i),par(10+i,l))
             endif
          elseif (associated(sed_ptr%node_name)) then
             ! parameter not in transport file, now check sedblock
             call prop_get(sed_ptr,'Sediment',parkeyw(i),parfile)
             if (parfile /= ' ') then
                call combinepaths(flname, parfile)
                inquire (file = parfile, exist = lex)
                if (lex) then
                   parfil(10+i,l) = parfile
                   nparfld = nparfld+1
                   iparfld(10+i,l) = nparfld
                else
                   call prop_get(sed_ptr,'Sediment',parkeyw(i),par(10+i,l))
                endif
             endif
          endif
       else
          par(10+i,l) = pardef(i)
          !
          parfile = ' '
          if (ifrac>0 .and. associated(sed_ptr%node_name)) then
             ! try to locate parameter in sedblock
             call prop_get(sed_ptr,'Sediment',parkeyw(i),parfile)
             if (parfile /= ' ') then
                call combinepaths(flname, parfile)
                inquire (file = parfile, exist = lex)
                if (lex) then
                   parfil(10+i,l) = parfile
                   nparfld = nparfld+1
                   iparfld(10+i,l) = nparfld
                else
                   call prop_get(sed_ptr,'Sediment',parkeyw(i),par(10+i,l))
                endif
             endif
          endif
       endif
       if (comparereal(par(10+i,l),nodef)==0 .and. iparfld(10+i,l)==0) then
          error  = .true.
          errmsg = 'No value obtained for parameter '//trim(parkeyw(i))//' without default value.'
          call write_error(errmsg, unit=lundia)
       endif
    enddo
    !
    if (version==0) then
       close(inp)
    endif
    if (version>=0) then
       call tree_destroy( tran_ptr )
    endif
    deallocate(sed_ptr)
end subroutine rdtrafrm0


subroutine rdtraparfld(lundia    ,error     ,lsedtot   ,trapar    , &
                     & dims      )
!!--description-----------------------------------------------------------------
!
! Reads spatially varying transport formula parameters
!
!!--declarations----------------------------------------------------------------
    use precision
    use morphology_data_module
    use grid_dimens_module 
    !
    implicit none
    !
    ! Call variables
    !
    integer                      , intent(in)   :: lundia
    logical                      , intent(out)  :: error
    integer                      , intent(in)   :: lsedtot !  Description and declaration in iidim.f90
    type (trapar_type)           , target       :: trapar
    type (griddimtype), target   , intent(in)   :: dims    !  grid dimensions
!
! Local variables
!
    integer                        , pointer :: npar
    integer                        , pointer :: nparfld
    character(256), dimension(:,:) , pointer :: parfil
    integer,        dimension(:,:) , pointer :: iparfld
    real(fp),       dimension(:,:) , pointer :: parfld
    !
    integer           :: i
    integer           :: istat
    integer           :: j
    integer           :: ll
    character(256)    :: filename
    character(11)     :: fmttmp
!
!! executable statements -------------------------------------------------------
!
    npar          => trapar%npar
    nparfld       => trapar%nparfld
    parfil        => trapar%parfil
    iparfld       => trapar%iparfld
    !
    error  = .false.
    fmttmp = 'formatted'
    istat  = 0
    !
    allocate(trapar%parfld(dims%nmlb:dims%nmub,nparfld), stat=istat)
    if (istat/=0) then
       error = .true.
       return
    endif
    parfld        => trapar%parfld
    !
    do ll = 1, lsedtot
       do i = 1, npar
          j = trapar%iparfld(i,ll)
          if (j>0) then
             filename = trapar%parfil(i,ll)
             write (lundia, '(a,a)') 'Reading: ',trim(filename)
             call depfil(lundia     ,error      ,filename   ,fmttmp    , &
                       & parfld(:,j),1          ,1          ,dims      )
             if (error) return
          endif
       enddo
    enddo
end subroutine rdtraparfld


subroutine setpardeflog(ipardef   ,rpardef   ,npardef   ,iform     , &
                      & ipar      ,val       )
!!--description-----------------------------------------------------------------
!
!
!
!!--declarations----------------------------------------------------------------
    use precision
    !
    implicit none
!
! Call variables
!
    integer                       , intent(in)    :: npardef
    integer, dimension(2,npardef) , intent(inout) :: ipardef
    integer                       , intent(in)    :: iform
    integer                       , intent(in)    :: ipar
    real(fp), dimension(npardef)  , intent(inout) :: rpardef
    logical                       , intent(in)    :: val
!
! Local variables
!
    real(fp)                                      :: rval
!
!! executable statements -------------------------------------------------------
!
    rval = 0.0_fp
    if (val) rval = 1.0_fp
    call setpardefreal(ipardef   ,rpardef   ,npardef   ,iform     , &
                     & ipar      ,rval      )
end subroutine setpardeflog


subroutine setpardefint(ipardef   ,rpardef   ,npardef   ,iform     , &
                      & ipar      ,val       )
!!--description-----------------------------------------------------------------
!
!
!
!!--declarations----------------------------------------------------------------
    use precision
    !
    implicit none
!
! Call variables
!
    integer                       , intent(in)    :: npardef
    integer, dimension(2,npardef) , intent(inout) :: ipardef
    integer                       , intent(in)    :: iform
    integer                       , intent(in)    :: ipar
    real(fp), dimension(npardef)  , intent(inout) :: rpardef
    integer                       , intent(in)    :: val
!
! Local variables
!
    real(fp)                                      :: rval
!
!! executable statements -------------------------------------------------------
!
    rval = real(val,fp)
    call setpardefreal(ipardef   ,rpardef   ,npardef   ,iform     , &
                     & ipar      ,rval      )
end subroutine setpardefint


subroutine setpardefreal(ipardef   ,rpardef   ,npardef   ,iform     , &
                       & ipar      ,val       )
!!--description-----------------------------------------------------------------
!
!
!
!!--declarations----------------------------------------------------------------
    use precision
    !
    implicit none
!
! Call variables
!
    integer                       , intent(in)    :: npardef
    integer, dimension(2,npardef) , intent(inout) :: ipardef
    integer                       , intent(in)    :: iform
    integer                       , intent(in)    :: ipar
    real(fp), dimension(npardef)  , intent(inout) :: rpardef
    real(fp)                      , intent(in)    :: val
!
! Local variables
!
    integer                                       :: i
!
!! executable statements -------------------------------------------------------
!
    do i = 1,npardef
       if (ipardef(1,i) == 0) then
          ipardef(1,i) = iform
          ipardef(2,i) = ipar
          rpardef(i)   = val
          return
       endif
    enddo
end subroutine setpardefreal


subroutine getpardef(ipardef   ,rpardef   ,npardef   ,iform     ,pardef    )
!!--description-----------------------------------------------------------------
!
!
!
!!--declarations----------------------------------------------------------------
    use precision
    !
    implicit none
!
! Call variables
!
    integer                       , intent(in)    :: npardef
    integer, dimension(2,npardef) , intent(in)    :: ipardef
    integer                       , intent(in)    :: iform
    real(fp), dimension(npardef)  , intent(in)    :: rpardef
    real(fp), dimension(*)        , intent(inout) :: pardef
!
! Local variables
!
    integer                                       :: i
!
!! executable statements -------------------------------------------------------
!
    do i = 1, npardef
       if (ipardef(1,i) == iform) then
          pardef(ipardef(2,i)) = rpardef(i)
       elseif (ipardef(1,i) == 0) then
          return
       endif
    enddo
end subroutine getpardef


subroutine echotrafrm(lundia    ,trapar      ,ifrac     )
!!--description-----------------------------------------------------------------
!
! Report transport formula and associated parameters to diag file
!
!!--declarations----------------------------------------------------------------
    use precision
    use morphology_data_module, only: trapar_type
    !
    implicit none
!
! Call variables
!
    integer                                      :: lundia  !  Description and declaration in inout.igs
    type(trapar_type)              , intent(in)  :: trapar
    integer                        , intent(in)  :: ifrac
!
! Local variables
!
    integer                        :: i
    integer                        :: nparreq
    integer                        :: nparopt
    real(fp)                       :: nodef
    real(fp)       , dimension(30) :: pardef
    character(25)  , dimension(30) :: parkeyw
    character(60)                  :: dummy
!
!! executable statements -------------------------------------------------------
!
    write (lundia, '(a,a)') '    Formula name              : ',trim(trapar%name(ifrac))
    if (trapar%iform(ifrac)==15) then
       write (lundia, '(a,a)') '    Dynamic library           : ',trim(trapar%dll_name(ifrac))
       write (lundia, '(a,a)') '    Function in library       : ',trim(trapar%dll_function(ifrac))
       if (trapar%dll_usrfil(ifrac) /= ' ') then
          write (lundia, '(a,a)') '    Input file for function   : ',trim(trapar%dll_usrfil(ifrac))
       endif
    else
       write (lundia, '(a,i3)') '    Transport formula used    :', trapar%iform(ifrac)
       call traparams(trapar%iform(ifrac),dummy, &
                    & nparreq   ,nparopt   ,parkeyw   ,pardef    ,nodef     )
       !
       if (nparreq>0 .or. nparopt>0) then
          do i = 1, nparreq+nparopt
             if (trapar%iparfld(10+i,ifrac)==0) then
                write (lundia, '(3a,e12.4)') '    ',parkeyw(i),' :',trapar%par(10+i,ifrac)
             else
                write (lundia, '(4a)') '    ',parkeyw(i),' : ',trim(trapar%parfil(10+i,ifrac))
             endif
          enddo
       endif
    endif
end subroutine echotrafrm


subroutine traparams(iform     ,name      ,nparreq   ,nparopt   ,parkeyw   , &
                   & pardef    ,nodef     )
!!--description-----------------------------------------------------------------
!
! Provides characteristics of built-in transport formulae
!
!!--declarations----------------------------------------------------------------
    use precision
    !
    implicit none
!
! Call variables
!
    integer                       , intent(in)  :: iform
    character(*)                  , intent(out) :: name
    integer                       , intent(out) :: nparreq
    integer                       , intent(out) :: nparopt
    real(fp)       , dimension(30), intent(out) :: pardef
    character(*)   , dimension(30), intent(out) :: parkeyw
    real(fp)                      , intent(out) :: nodef
!
! Local variables
!
!
!! executable statements -------------------------------------------------------
!
    nodef   = -999999.0_fp
    !
    if (iform /= 15) name = ' '
    nparreq = 0
    nparopt = 0
    parkeyw = ' '
    pardef  = nodef
    if (iform == -3) then
       name       = 'Partheniades-Krone'
       nparreq    = 3
       parkeyw(1) = 'EroPar'
       pardef(1)  = 0.0_fp
       parkeyw(2) = 'TcrSed'
       pardef(2)  = 0.0_fp
       parkeyw(3) = 'TcrEro'
       pardef(3)  = 0.0_fp
       nparopt    = 4
       parkeyw(4) = 'TcrFluff'
       pardef(4)  = 0.0_fp
       parkeyw(5) = 'ParFluff0'
       pardef(5)  = 0.0_fp
       parkeyw(6) = 'ParFluff1'
       pardef(6)  = 0.0_fp
       parkeyw(7) = 'DepEff'
       pardef(7)  = -1.0_fp
    elseif (iform == -2) then
       name       = 'Van Rijn (2007): TRANSPOR2004'
       nparopt    = 7
       parkeyw(1) = 'IopSus'
       pardef(1)  = 0.0_fp
       parkeyw(2) = 'Pangle'
       pardef(2)  = 0.0_fp
       parkeyw(3) = 'Fpco'
       pardef(3)  = 1.0_fp
       parkeyw(4) = 'Subiw'
       pardef(4)  = 51.0_fp
       parkeyw(5) = 'EpsPar'
       pardef(5)  = 0.0_fp ! false
       parkeyw(6) = 'GamTcr'
       pardef(6)  = 1.5_fp
       parkeyw(7) = 'SalMax'
       pardef(7)  = 0.0_fp
    elseif (iform == -1) then
       name       = 'Van Rijn (1993)'
       nparopt    = 7
       parkeyw(1) = 'IopSus'
       pardef(1)  = 0.0_fp
       parkeyw(2) = 'AksFac'
       pardef(2)  = 1.0_fp
       parkeyw(3) = 'RWave'
       pardef(3)  = 2.0_fp
       parkeyw(4) = 'RDC'
       pardef(4)  = 0.01_fp
       parkeyw(5) = 'RDW'
       pardef(5)  = 0.02_fp
       parkeyw(6) = 'IopKCW'
       pardef(6)  = 1.0_fp
       parkeyw(7) = 'EpsPar'
       pardef(7)  = 0.0_fp ! false
    elseif (iform == 1) then
       name       = 'Engelund-Hansen (1967)'
       nparreq    = 1
       parkeyw(1) = 'ACal'
       nparopt    = 2
       parkeyw(2) = 'RouKs'
       pardef(2)  = 1.0_fp
       parkeyw(3) = 'SusFac'
       pardef(3)  = 0.0_fp
    elseif (iform == 2) then
       name       = 'Meyer-Peter-Mueller (1948)'
       nparreq    = 1
       parkeyw(1) = 'ACal'
    elseif (iform == 3) then
       name       = 'Swanby / Ackers-White'
       nparreq    = 1
       parkeyw(1) = 'ACal'
       nparopt    = 1
       parkeyw(2) = 'RouKs'
       pardef(2)  = 1.0_fp
    elseif (iform == 4) then
       name       = 'General formula'
       nparreq    = 5
       parkeyw(1) = 'ACal'
       parkeyw(2) = 'PowerB'
       parkeyw(3) = 'PowerC'
       parkeyw(4) = 'RipFac'
       parkeyw(5) = 'ThetaC'
    elseif (iform == 5) then
       name       = 'Bijker (1971)'
       nparreq    = 9
       parkeyw(1) = 'CalBs'
       parkeyw(2) = 'CalBd'
       parkeyw(3) = 'CritCs'
       parkeyw(4) = 'CritCd'
       parkeyw(5) = '[dummy]' !don't remove: backward compatibility!
       pardef(5)  = 1.0_fp
       parkeyw(6) = 'RouKs'
       parkeyw(7) = 'WSettle'
       parkeyw(8) = 'Porosity'
       parkeyw(9) = 'TWave'
    !elseif (iform == 6) then
    !   name       = 'Bailard'
    !   nparreq    = 10
    elseif (iform == 7) then
       name       = 'Van Rijn (1984)'
       nparreq    = 4
       parkeyw(1) = 'ACal'
       parkeyw(2) = '[dummy]' !don't remove: backward compatibility!
       pardef(2)  = 1.0_fp
       parkeyw(3) = 'Aks'
       parkeyw(4) = 'WSettle'
       nparopt    = 1
       parkeyw(5) = 'BetaM'
       pardef(5)  = 0.0_fp
    !elseif (iform == 8) then
    !   name       = 'Van Rijn / Ribberink (1994)'
    !   nparreq    = 14
    !elseif (iform == 9) then
    !   name       = 'Partheniades / Krone'
    !elseif (iform == 10) then
    !   name       = 'Ashida & Michiue'
    !   nparreq    = 3
    elseif (iform == 11) then
       name       = 'Soulsby / Van Rijn'
       nparreq    = 3
       parkeyw(1) = 'ACal'
       parkeyw(2) = 'RatioD90D50'
       parkeyw(3) = 'RouZ0'
    elseif (iform == 12) then
       name       = 'Soulsby'
       nparreq    = 3
       parkeyw(1) = 'ACal'
       parkeyw(2) = 'ModInd'
       parkeyw(3) = 'RatioD50Z0'
    elseif (iform == 13) then
       name       = 'Wang / Fredsoe'
       nparreq    = 2
       parkeyw(1) = 'VicMol'
       parkeyw(2) = 'ACal' ! Don't move up: historical order!
    elseif (iform == 14) then
       name       = 'Ashida-Michiue (1974)'
       nparreq    = 5   
       parkeyw(1) = 'ACal'
       parkeyw(2) = 'ThetaC'
       parkeyw(3) = 'PowerM'
       parkeyw(4) = 'PowerP'
       parkeyw(5) = 'PowerQ'
    elseif (iform == 15) then
       if (name == ' ') name = 'External subroutine'
       nparreq    = 0
    elseif (iform == 16) then
       name       = 'Wilcock-Crowe (2003)'
       nparopt    = 1
       parkeyw(1) = 'ACal'
       pardef(1)  = 1.0_fp
    elseif (iform == 17) then
       name       = 'Gaeuman et. al. (2009) lab calibration'
       nparreq    = 2
       parkeyw(1) = 'ThetaC0'
       pardef(1)  = 0.021_fp
       parkeyw(2) = 'Alpha0'
       pardef(2)  = 0.33_fp
    elseif (iform == 18) then
       name       = 'Gaeuman et. al. (2009) Trinity River'
       nparreq    = 2
       parkeyw(1) = 'ThetaC0'
       pardef(1)  = 0.03_fp
       parkeyw(2) = 'Alpha0'
       pardef(2)  = 0.3_fp
    endif
end subroutine traparams

end module m_rdtrafrm
