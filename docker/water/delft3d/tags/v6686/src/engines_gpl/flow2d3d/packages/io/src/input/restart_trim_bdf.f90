subroutine restart_trim_bdf(lundia   ,nmaxus   ,mmax     ,bdfh     , &
                          & bdfhread ,bdfl     ,bdflread ,gdp      )
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
!  $Id: restart_trim_bdf.f90 6486 2016-08-24 14:42:28Z jagers $
!  $HeadURL: https://svn.oss.deltares.nl/repos/delft3d/tags/6686/src/engines_gpl/flow2d3d/packages/io/src/input/restart_trim_bdf.f90 $
!!--description-----------------------------------------------------------------
! Reads initial field condition records from a trim-file
!!--pseudo code and references--------------------------------------------------
! NONE
!!--declarations----------------------------------------------------------------
    use precision
    use globaldata
    use rdarray, only: rdarray_nm
    use nan_check_module
    !
    implicit none
    !
    type(globdat),target :: gdp
    !
    integer       , dimension(:,:)       , pointer :: iarrc
    integer       , dimension(:)         , pointer :: mf
    integer       , dimension(:)         , pointer :: ml
    integer       , dimension(:)         , pointer :: nf
    integer       , dimension(:)         , pointer :: nl
    !
    integer                              , pointer :: i_restart
    integer                              , pointer :: fds
    integer                              , pointer :: filetype
    character(256)                       , pointer :: filename
    !
    ! Global variables
    !
    integer                                                                    , intent(in)  :: lundia
    integer                                                                    , intent(in)  :: mmax
    integer                                                                    , intent(in)  :: nmaxus
    logical                                                                    , intent(out) :: bdfhread
    logical                                                                    , intent(out) :: bdflread
    real(fp), dimension(gdp%d%nlb:gdp%d%nub, gdp%d%mlb:gdp%d%mub)              , intent(out) :: bdfh
    real(fp), dimension(gdp%d%nlb:gdp%d%nub, gdp%d%mlb:gdp%d%mub)              , intent(out) :: bdfl
    !
    ! Local variables
    !
    integer                               :: ierror
    character(16)                         :: grnam
    !
    !! executable statements -------------------------------------------------------
    !
    mf                  => gdp%gdparall%mf
    ml                  => gdp%gdparall%ml
    nf                  => gdp%gdparall%nf
    nl                  => gdp%gdparall%nl
    iarrc               => gdp%gdparall%iarrc
    !
    i_restart           => gdp%gdrestart%i_restart
    fds                 => gdp%gdrestart%fds
    filetype            => gdp%gdrestart%filetype
    filename            => gdp%gdrestart%filename
    !
    bdfhread = .false.
    bdflread = .false.
    !
    if (filetype == -999) return
    !
    ! element 'DUNEHEIGHT'
    !
    grnam = 'map-sed-series'
    call rdarray_nm(fds, filename, filetype, grnam, i_restart, &
                 & nf, nl, mf, ml, iarrc, gdp, &
                 & ierror, lundia, bdfh, 'DUNEHEIGHT')
    if (ierror /= 0) then
       !
       ! In the research version, DUNEHEIGHT was stored in the map-series group.
       ! For the time being remain compatible with that version.
       !
       grnam = 'map-series'
       call rdarray_nm(fds, filename, filetype, grnam, i_restart, &
                    & nf, nl, mf, ml, iarrc, gdp, &
                    & ierror, lundia, bdfh, 'DUNEHEIGHT')
    endif
    if (ierror == 0) then
       write(lundia, '(a)') 'Bed form height read from restart file.'
       bdfhread = .true.
    endif
    !
    ! element 'DUNELENGTH'
    !
    call rdarray_nm(fds, filename, filetype, grnam, i_restart, &
                 & nf, nl, mf, ml, iarrc, gdp, &
                 & ierror, lundia, bdfl, 'DUNELENGTH')
    if (ierror == 0) then
       write(lundia, '(a)') 'Bed form length read from restart file.'
       bdflread = .true.
    endif
end subroutine restart_trim_bdf
