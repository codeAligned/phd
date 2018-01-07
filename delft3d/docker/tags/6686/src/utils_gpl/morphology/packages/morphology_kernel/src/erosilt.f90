subroutine erosilt(thick    ,kmax      ,ws        ,lundia   , &
                 & thick0   ,thick1    ,fixfac    ,srcmax   , &
                 & frac     ,oldmudfrac,flmd2l    ,iform    , &
                 & par      ,numintpar ,numrealpar,numstrpar, &
                 & dllfunc  ,dllhandle ,intpar    ,realpar  , &
                 & strpar   ,iflufflyr ,mflufftot ,fracf    , &
                 & maxslope ,wetslope  , &
! output:
                 & error    ,wstau     ,sinktot   ,sourse   , &
                 & sourf    )
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
!  $Id: erosilt.f90 5717 2016-01-12 11:35:24Z mourits $
!  $HeadURL: https://svn.oss.deltares.nl/repos/delft3d/tags/6686/src/utils_gpl/morphology/packages/morphology_kernel/src/erosilt.f90 $
!!--description-----------------------------------------------------------------
!
!    Function: Computes sediment fluxes for cohesive sediment fractions
!              at the bed and the fluff layer. Internally implemented
!              are the Partheniades-Krone formulations, optional external
!              lib may be used.
!
!!--pseudo code and references--------------------------------------------------
! NONE
!!--declarations----------------------------------------------------------------
    use precision
    use sediment_basics_module
    use morphology_data_module, only: RP_TAUB
    use message_module, only: write_error
    !
    implicit none
    !
    integer                             , intent(in)    :: iform
    integer                             , intent(in)    :: iflufflyr
    integer                             , intent(in)    :: numintpar
    integer                             , intent(in)    :: numrealpar
    integer                             , intent(in)    :: numstrpar
    integer                             , intent(in)    :: kmax
    integer                                             :: lundia   !  Description and declaration in inout.igs
    integer       , dimension(numintpar), intent(inout) :: intpar
    integer(pntrsize)                   , intent(in)    :: dllhandle
    !
    real(fp)                            , intent(in)    :: fixfac
    real(fp)                            , intent(in)    :: frac
    real(fp)                            , intent(in)    :: fracf
    real(fp)                            , intent(in)    :: maxslope
    real(fp)                            , intent(in)    :: mflufftot
    real(fp)     , dimension(30)        , intent(inout) :: par
    real(fp)                            , intent(out)   :: sinktot
    real(fp)                            , intent(out)   :: sourf
    real(fp)                            , intent(out)   :: sourse
    real(fp)                            , intent(in)    :: srcmax
    real(fp)       , dimension(kmax)    , intent(in)    :: thick
    real(fp)                            , intent(in)    :: thick0
    real(fp)                            , intent(in)    :: thick1
    real(fp)                            , intent(in)    :: wetslope
    real(fp)       , dimension(0:kmax)  , intent(in)    :: ws
    real(fp)                            , intent(out)   :: wstau
    !
    real(hp)     , dimension(numrealpar), intent(inout) :: realpar
    !
    logical                             , intent(out)   :: error
    logical                             , intent(in)    :: flmd2l
    logical                             , intent(in)    :: oldmudfrac
    character(256), dimension(numstrpar), intent(inout) :: strpar
    character(256)                      , intent(in)    :: dllfunc
!
! Local variables
!
    integer  :: k
    real(fp) :: betaslope
    real(fp) :: sour
    real(fp) :: sour_fluff
    real(fp) :: sink
    real(fp) :: taub
    real(fp) :: taum
    real(fp) :: entr
    real(fp) :: taucrmin
    real(fp) :: tcrdep
    real(fp) :: tcrero
    real(fp) :: eropar
    real(fp) :: tcrflf
    real(fp) :: parfl0
    real(fp) :: parfl1
    real(fp) :: depeff
    !
    ! Interface to dll is in High precision!
    !
    real(hp)                    :: sink_dll
    real(hp)                    :: sour_dll
    integer(pntrsize)           :: ierror_ptr
    integer(pntrsize), external :: perf_function_erosilt
    character(1024)             :: errmsg
    character(256)              :: message     ! Contains message from user dll
!
!! executable statements ------------------
!
    error  = .false.
    !
    ! Calculate total (possibly wave enhanced) roughness
    !
    taub   = real(realpar(RP_TAUB), fp)
    !
    ! Bed transport following Partheniades and Krone
    ! but in case of fluid mud, source term is determined by
    ! fluid mud part (sourmu). Information is passed via entr()
    ! maximum erosion is sediment available at bed (ignores sediment
    ! settling during the current morphological timestep)
    ! In case of fluid mud the maximum erosion is determined in sourmu
    ! of the fluid mud module. So ignore this check when fluid mud.
    ! Also, taum is not required in the formulation since whether or not
    ! and how much entrainment occurs is entirely handled by the sourmu
    ! routine.
    !
    ! calculation both for mud and floc
    !
    if (flmd2l) then
       entr   = par(11)
       tcrdep = par(12)
       !
       ! maximum erosion is sediment available at bed
       ! (ignores sediment settling during the current morphological timestep)
       !
       sour = entr
       if (tcrdep > 0.0_fp) then
          sink = max(0.0_fp , 1.0_fp-taub/tcrdep)
       else
          sink = 0.0
       endif
    else
       if (iform == -3) then
          eropar = par(11)
          tcrdep = par(12)
          tcrero = par(13)
          tcrflf = par(14)
          parfl0 = par(15)
          parfl1 = par(16)
          depeff = par(17)
          !
          ! Default Partheniades-Krone formula
          !
          if (maxslope>wetslope) then
             !
             ! Maximum bed slope in surrounding velocity points exceeds WetSlope
             ! Decrease critical shear stress for erosion
             !
             taucrmin  = 0.1_fp
             betaslope = 2.0_fp
             tcrero = ((taucrmin - tcrero)/(betaslope*wetslope - wetslope))*taub + tcrero - ((taucrmin - tcrero)/(betaslope*wetslope - wetslope))*wetslope
             tcrero = max(tcrero, taucrmin)
          endif
          !
          taum = max(0.0_fp, taub/tcrero - 1.0_fp)
          sour = eropar * taum
          !
          ! Erosion from fluff layer
          !
          if (iflufflyr>0) then
            taum       = max(0.0_fp, taub - tcrflf)
            sour_fluff = min(mflufftot*parfl1,parfl0)*taum
          else
            sour_fluff = 0.0_fp
          endif
          !
          if (comparereal(depeff,-1.0_fp)==0) then
             if (tcrdep > 0.0_fp) then
                sink = max(0.0_fp , 1.0_fp-taub/tcrdep)
             else
                sink = 0.0_fp
             endif
          else
             sink = max(0.0_fp,min(depeff,1.0_fp))
          endif
       elseif (iform == 15) then
          !
          ! Initialisation of output variables of user defined transport formulae
          !
          sink_dll    = 0.0_hp
          sour_dll    = 0.0_hp
          message     = ' '
          !
          ! psem/vsem is used to be sure this works fine in DD calculations
          !
          call psemlun
          ierror_ptr = 0
          ierror_ptr = perf_function_erosilt(dllhandle       , dllfunc           , &
                                             intpar          , numintpar         , &
                                             realpar         , numrealpar        , &
                                             strpar          , numstrpar         , &
                                             sink_dll        , sour_dll          , &
                                             message)
          call vsemlun
          if (ierror_ptr /= 0) then
             errmsg = 'Cannot find function "'//trim(dllfunc)//'" in dynamic library.'
             call write_error(errmsg, unit=lundia)
             error = .true.
             return
          endif
          if (message /= ' ') then
             errmsg = 'Message from user defined erosion/deposition formulae '//trim(dllfunc)//' :'
             call write_error(errmsg, unit=lundia)
             write (lundia,'(a,a  )') '          ', trim(message)
             write (lundia,'(a    )') ' '
             error = .true.
             return
          endif
          !
          ! Output parameters
          !
          sour       = real(sour_dll,fp)
          sink       = real(sink_dll,fp)
          sour_fluff = 0.0_fp
       else
          write (errmsg,'(a,i0,a)') 'Invalid transport formula ',iform,' for mud fraction.'
          call write_error(errmsg, unit=lundia)
       endif
    endif
    !
    wstau         = ws(kmax) * sink ! used for flmd2l
    !
    if (.not.flmd2l) then
       if (oldmudfrac) then
          sour       = fixfac * sour
          sour_fluff = 0.0_fp
       else
          sour       = fixfac * frac  * sour
          sour_fluff =          fracf * sour_fluff
       endif
    endif
    !
    sour    = min(sour, srcmax)
    !
    sourf   = sour_fluff / thick0
    sourse  = sour       / thick0
    sinktot = wstau      / thick1
end subroutine erosilt
