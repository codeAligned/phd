!> \file
!! Writes the hyd file that determines everything for the Delwaq GUI
      subroutine wrwaqhyd ( filnam , itdate , tstart , tstop  , dt     , &
     &                      itwqff , itwqfl , itwqfi , nmax   , mmax   , &
     &                      kmax   , thick  , lsal   , ltem   , lsed   , &
     &                      chez   , nsrc   , mnksrc , namsrc , runid  , &
     &                      nowalk , iwlk   , aggre  , flaggr , zmodel , &
     &                      ilaggr , nd     , nlb    , nub    , mlb    , &
     &                      mub    , kfsmin , ksrwaq , noseg, noq1, noq2, &
     &                      noq3   , xz     , yz )
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
!  $Id: wrwaqhyd.f90 6277 2016-07-11 11:42:52Z jeuke_ml $
!  $HeadURL: https://svn.oss.deltares.nl/repos/delft3d/tags/6686/src/engines_gpl/flow2d3d/packages/io/src/output/wrwaqhyd.f90 $
!!--description-----------------------------------------------------------------
! NONE
!!--pseudo code and references--------------------------------------------------
! NONE
!!--declarations----------------------------------------------------------------
      use precision
      implicit none
!
!           Global variables
!
      character(*)  filnam             !<  Filename without extension
      integer       itdate             !<  reference time in YYYYMMDD
      real     (fp) tstart             !<  Flow start time in minutes
      real     (fp) tstop              !<  Flow stop time in minutes
      real     (fp) dt                 !<  Flow time step in minutes
      integer       itwqff             !<  first waq time step
      integer       itwqfl             !<  last  waq time step
      integer       itwqfi             !<  waq time step
      integer       nmax               !<  Dimension of first index in 2d arrays
      integer       mmax               !<  Dimension of second index in 2d arrays
      integer       kmax               !<  number of layers
      real     (fp) thick(kmax)        !<  Relative layer thickness sigma coords
      integer       lsal               !<  Substance number salinity
      integer       ltem               !<  Substance number temperature
      integer       lsed               !<  Number of substances for sediment
      logical       chez               !<  if true, then chezy values
      integer       nsrc               !<  number of sources
      integer       mnksrc(7,nsrc)     !<  location and type of sources
      character(20) namsrc(  nsrc)     !<  names of the sources
      character( *) runid              !<  name of the run
      integer       nowalk             !<  number of walking discharges
      integer       iwlk  (  nsrc)     !<  location of walking discharges
      integer       aggre              !<  1 if aggregation, 0 is condensation
      character( *) flaggr             !<  Name of aggregation file id aggre
      logical       zmodel             !<  true if z-model feature is used
      integer       ilaggr(kmax)       !<  vertical layer aggregation array
      integer       nd                 !<  number of domains
      integer(4)    nlb                !<  Lower bound of all n dimensions
      integer(4)    nub                !<  Upper bound of all n dimensions
      integer(4)    mlb                !<  Lower bound of all m dimensions
      integer(4)    mub                !<  Upper bound of all m dimensions
      integer  kfsmin(nlb:nub,mlb:mub) !<  Variable lowest active layer (z-model-only)
      integer(4)    ksrwaq(2*nsrc)     !<  stored value of nr of layers source locations
      integer(4)    noseg              !<  Total number of segments
      integer(4)    noq1               !<  Exchanges in first direction
      integer(4)    noq2               !<  Exchanges in second direction
      integer(4)    noq3               !<  Exchanges in third direction
      real(fp) , dimension(nlb:nub,mlb:mub) , intent(in) :: xz     !  Description and declaration in esm_alloc_real.f90
      real(fp) , dimension(nlb:nub,mlb:mub) , intent(in) :: yz     !  Description and declaration in esm_alloc_real.f90
!
!           Local  variables
!
      real     (fp) timsec
      integer       julday, idate, itime ! waq handles julian times better !!!
      integer       i, ilay            !! loop variables
      integer       l                  !! counter nr of sediment substances
      integer       il                 !! counter inlet-outlet
      integer       n, m, nl           !! grid indices
      real     ( 4) anl                !! for waq layers
      integer  ( 4) kfmin, kfmax       !! help variables z-model
      character(256) version_full      !! Delft3D FLOW version information
      character(20)  rundat            !! Current date and time containing a combination of DATE and TIME
      character(21)  datetime          !! Date/time to be filled in the header
      character(256) filstring, file1, file2
      character(5) sf                  !! character variable for s(ediment)f(iles)
      integer, external :: newunit
      integer(4)    lunout1 !! write hyd file for structured grid needed for delpar
      integer(4)    lunout2 !! write hyd-file for DeltaShell (unstructured format)
!
!! executable statements -------------------------------------------------------
!
      lunout1 = newunit()
      file1 = trim(filnam)//'.hyd'
      open  ( lunout1 , file=trim(file1) )
      lunout2 = newunit()
      file2 = trim(filnam)//'_unstructured.hyd'
      open  ( lunout2 , file=trim(file2) )

      version_full  = ' '
      call getfullversionstring_flow2d3d(version_full)
      write(lunout1,'(A,A)') 'file-created-by  '//trim(version_full)
      write(lunout2,'(A,A)') 'file-created-by  '//trim(version_full)

      call dattim(rundat)
      datetime = rundat(1:4)//'-'//rundat(6:7)//'-'//rundat(9:10)//','//rundat(11:19)
      write(lunout1,'(A,A)') 'file-creation-date  '//datetime
      write(lunout2,'(A,A)') 'file-creation-date  '//datetime

      write ( lunout1 , '(A      )' ) 'task      full-coupling'
      write ( lunout2 , '(A      )' ) 'task      full-coupling'
      if (zmodel) then
         write ( lunout1 , '(A      )' ) 'geometry  curvilinear-grid  z-layers'
         write ( lunout2 , '(A      )' ) 'geometry  unstructured  z-layers'
      else
         write ( lunout1 , '(A      )' ) 'geometry  curvilinear-grid'
         write ( lunout2 , '(A      )' ) 'geometry  unstructured'
      end if
      if ( aggre .lt. 0 ) then
         write ( lunout1 , '(A,A    )' ) 'horizontal-aggregation       ','no'
         write ( lunout2 , '(A,A    )' ) 'horizontal-aggregation       ','no'
      end if 
      if ( aggre .eq. 0 ) then
         write ( lunout1 , '(A,A    )' ) 'horizontal-aggregation       ','automatic'
         write ( lunout2 , '(A,A    )' ) 'horizontal-aggregation       ','automatic'
      end if 
      if ( aggre .gt. 0 ) then
         write ( lunout1 , '(A,A    )' ) 'horizontal-aggregation       ','yes'
         write ( lunout2 , '(A,A    )' ) 'horizontal-aggregation       ','yes'
      end if 
      write ( lunout1 , '(A,A    )' ) 'minimum-vert-diffusion-used  ','no'
      write ( lunout2 , '(A,A    )' ) 'minimum-vert-diffusion-used  ','no'
      write ( lunout1 , '(A,A    )' ) 'vertical-diffusion           ','calculated'
      write ( lunout2 , '(A,A    )' ) 'vertical-diffusion           ','calculated'
      write ( lunout1 , '(A      )' ) 'description'
      write ( lunout2 , '(A      )' ) 'description'
      write ( lunout1 , '(A      )' ) '''                                                            '''
      write ( lunout2 , '(A      )' ) '''                                                            '''
      write ( lunout1 , '(A      )' ) '''                                                            '''
      write ( lunout2 , '(A      )' ) '''                                                            '''
      write ( lunout1 , '(A      )' ) '''                                                            '''
      write ( lunout2 , '(A      )' ) '''                                                            '''
      write ( lunout1 , '(A      )' ) 'end-description'
      write ( lunout2 , '(A      )' ) 'end-description'
      call juldat ( itdate, julday )
      write ( lunout1 , '(A,I8,A )' ) 'reference-time           ''',itdate,'000000'''
      write ( lunout2 , '(A,I8,A )' ) 'reference-time           ''',itdate,'000000'''
      timsec = tstart*60.0
      call timdat( julday, timsec, idate, itime )
      write ( lunout1 , '(A,I8,I6.6,A)') 'hydrodynamic-start-time  ''',idate,itime,''''
      write ( lunout2 , '(A,I8,I6.6,A)') 'hydrodynamic-start-time  ''',idate,itime,''''
      timsec = tstop *60.0
      call timdat( julday, timsec, idate, itime )
      write ( lunout1 , '(A,I8,I6.6,A)') 'hydrodynamic-stop-time   ''',idate,itime,''''
      write ( lunout2 , '(A,I8,I6.6,A)') 'hydrodynamic-stop-time   ''',idate,itime,''''
      timsec = dt    *60.0
      call timdat( julday, timsec, idate, itime )
      write ( lunout1 , '(A,I6.6,A )' ) 'hydrodynamic-timestep    ''00000000',itime,''''
      write ( lunout2 , '(A,I6.6,A )' ) 'hydrodynamic-timestep    ''00000000',itime,''''
      write ( lunout1 , '(A,I8,A )' ) 'conversion-ref-time      ''',itdate,'000000'''
      write ( lunout2 , '(A,I8,A )' ) 'conversion-ref-time      ''',itdate,'000000'''
      timsec = itwqff*dt*60.0
      call timdat( julday, timsec, idate, itime )
      write ( lunout1 , '(A,I8,A )' ) 'conversion-start-time    ''',idate,'000000'''
      write ( lunout2 , '(A,I8,A )' ) 'conversion-start-time    ''',idate,'000000'''
      timsec = itwqfl*dt*60.0
      call timdat( julday, timsec, idate, itime )
      write ( lunout1 , '(A,I8,I6.6,A)') 'conversion-stop-time     ''',idate,itime,''''
      write ( lunout2 , '(A,I8,I6.6,A)') 'conversion-stop-time     ''',idate,itime,''''
      timsec = itwqfi*dt*60.0
      call timdat( julday, timsec, idate, itime )
      idate = idate - itdate
      write ( lunout1 , '(A,I8.8,I6.6,A )' ) 'conversion-timestep      ''',idate,itime,''''
      write ( lunout2 , '(A,I8.8,I6.6,A )' ) 'conversion-timestep      ''',idate,itime,''''
      
      write ( lunout1 , '(A,I7   )' ) 'grid-cells-first-direction              ', mmax
      write ( lunout2 , '(A,I7   )' ) 'grid-cells-first-direction              ', mmax
      write ( lunout1 , '(A,I7   )' ) 'grid-cells-second-direction             ', nmax
      write ( lunout2 , '(A,I7   )' ) 'grid-cells-second-direction             ', nmax
      write ( lunout1 , '(A,I7   )' ) 'number-hydrodynamic-layers              ', kmax
      write ( lunout2 , '(A,I7   )' ) 'number-hydrodynamic-layers              ', kmax
      
      write ( lunout2 , '(A,I7   )' ) 'number-horizontal-exchanges             ', noq1+noq2
      write ( lunout2 , '(A,I7   )' ) 'number-vertical-exchanges               ', noq3
      write ( lunout2 , '(A,I7   )' ) 'number-water-quality-segments-per-layer ', noseg/ilaggr(kmax)

      write ( lunout1 , '(A,I7   )' ) 'number-water-quality-layers             ', ilaggr(kmax)
      write ( lunout2 , '(A,I7   )' ) 'number-water-quality-layers             ', ilaggr(kmax)
      filstring = ''''//trim(filnam)//'.dat'''
      write ( lunout1 , '(A,A    )' ) 'hydrodynamic-file        ',trim(filstring)
      write ( lunout2 , '(A,A    )' ) 'hydrodynamic-file        ',trim(filstring)
      if ( aggre .le. 0 ) then
         write ( lunout1 , '(A,A    )' ) 'aggregation-file         none'
         write ( lunout2 , '(A,A    )' ) 'aggregation-file         none'
      else
         filstring = ''''//flaggr(1:len_trim(flaggr))//''''
         write ( lunout1 , '(A,A    )' ) 'aggregation-file         ',trim(filstring)
         write ( lunout2 , '(A,A    )' ) 'aggregation-file         ',trim(filstring)
      endif
      
      filstring = ''''//trim(filnam)//'.lga'''
      write ( lunout1 , '(A,A    )' ) 'grid-indices-file        ',trim(filstring)
      write ( lunout2 , '(A,A    )' ) 'grid-indices-file        ',trim(filstring)
      filstring = ''''//trim(filnam)//'.bnd'''
      write ( lunout2 , '(A,A    )' ) 'boundaries-file          ',trim(filstring)
      
      filstring = ''''//trim(filnam)//'.cco'''
      write ( lunout1 , '(A,A    )' ) 'grid-coordinates-file    ',trim(filstring)
      write ( lunout2 , '(A,A    )' ) 'grid-coordinates-file    ',trim(filstring)
      filstring = ''''//trim(filnam)//'_waqgeom.nc'''
      write ( lunout2 , '(A,A    )' ) 'waqgeom-file             ',trim(filstring)

      filstring = ''''//trim(filnam)//'.vol'''
      write ( lunout1 , '(A,A    )' ) 'volumes-file             ',trim(filstring)
      write ( lunout2 , '(A,A    )' ) 'volumes-file             ',trim(filstring)

      filstring = ''''//trim(filnam)//'.are'''
      write ( lunout1 , '(A,A    )' ) 'areas-file               ',trim(filstring)
      write ( lunout2 , '(A,A    )' ) 'areas-file               ',trim(filstring)

      filstring = ''''//trim(filnam)//'.flo'''
      write ( lunout1 , '(A,A    )' ) 'flows-file               ',trim(filstring)
      write ( lunout2 , '(A,A    )' ) 'flows-file               ',trim(filstring)

      filstring = ''''//trim(filnam)//'.poi'''
      write ( lunout1 , '(A,A    )' ) 'pointers-file            ',trim(filstring)
      write ( lunout2 , '(A,A    )' ) 'pointers-file            ',trim(filstring)

      filstring = ''''//trim(filnam)//'.len'''
      write ( lunout1 , '(A,A    )' ) 'lengths-file             ',trim(filstring)
      write ( lunout2 , '(A,A    )' ) 'lengths-file             ',trim(filstring)

      if ( lsal .gt. 0 ) then
         filstring = ''''//trim(filnam)//'.sal'''
      else
         filstring = 'none'
      endif
      write ( lunout1 , '(A,A    )' ) 'salinity-file            ',trim(filstring)
      write ( lunout2 , '(A,A    )' ) 'salinity-file            ',trim(filstring)
      if ( ltem .gt. 0 ) then
         filstring = ''''//trim(filnam)//'.tem'''
      else
         filstring = 'none'
      endif
      write ( lunout1 , '(A,A    )' ) 'temperature-file         ',trim(filstring)
      write ( lunout2 , '(A,A    )' ) 'temperature-file         ',trim(filstring)
      do l = 1, lsed
         sf = ".sed00"
         write( sf(4:5), '(i2.2)' ) l
         filstring = ''''//trim(filnam)//sf//''''
         write ( lunout1 , '(A,A )' ) 'sediment-file            ',trim(filstring)
         write ( lunout2 , '(A,A )' ) 'sediment-file            ',trim(filstring)
      enddo
      if ( ilaggr(kmax) .gt. 1 ) then
         filstring = ''''//trim(filnam)//'.vdf'''
      else
         filstring = 'none'
      endif
      write ( lunout1 , '(A,A    )' ) 'vert-diffusion-file      ',trim(filstring)
      write ( lunout2 , '(A,A    )' ) 'vert-diffusion-file      ',trim(filstring)

      filstring = ''''//trim(filnam)//'.srfold'''
      write ( lunout1 , '(A,A    )' ) 'surfaces-file            ',trim(filstring)
      filstring = ''''//trim(filnam)//'.srf'''
      write ( lunout2 , '(A,A    )' ) 'horizontal-surfaces-file ',trim(filstring)

      filstring = ''''//trim(filnam)//'.dps'''
      write ( lunout1 , '(A,A    )' ) 'depths-file              ',trim(filstring)
      write ( lunout2 , '(A,A    )' ) 'depths-file              ',trim(filstring)

      filstring = ''''//trim(filnam)//'.lgt'''
      write ( lunout1 , '(A,A    )' ) 'total-grid-file          ',trim(filstring)
      ! write ( lunout2 , '(A,A    )' ) 'total-grid-file          ',trim(filstring) ! not needed for unstructured

      filstring = ''''//trim(filnam)//'.src'''
      write ( lunout1 , '(A,A    )' ) 'discharges-file          ',trim(filstring)
      write ( lunout2 , '(A,A    )' ) 'discharges-file          ',trim(filstring)

      if ( chez ) then
         filstring = ''''//trim(filnam)//'.chz'''
      else
         filstring = 'none'
      endif
      write ( lunout1 , '(A,A    )' ) 'chezy-coefficients-file  ',trim(filstring)
      write ( lunout2 , '(A,A    )' ) 'chezy-coefficients-file  ',trim(filstring)

      filstring = ''''//trim(filnam)//'.tau'''
      write ( lunout1 , '(A,A    )' ) 'shear-stresses-file      ',trim(filstring)
      write ( lunout2 , '(A,A    )' ) 'shear-stresses-file      ',trim(filstring)

      filstring = ''''//trim(filnam)//'.wlk'''
      write ( lunout1 , '(A,A    )' ) 'walking-discharges-file  ',trim(filstring)
      write ( lunout2 , '(A,A    )' ) 'walking-discharges-file  ',trim(filstring)

      filstring = ''''//trim(filnam)//'.atr'''
      write ( lunout1 , '(A,A    )' ) 'attributes-file          ',trim(filstring)
      write ( lunout2 , '(A,A    )' ) 'attributes-file          ',trim(filstring)

      if ( ilaggr(kmax) .gt. 1 ) then
         write ( lunout1 , '(A,A    )' ) 'minimum-vert-diffusion   '
         write ( lunout2 , '(A,A    )' ) 'minimum-vert-diffusion   '
         write ( lunout1 , '(A,E13.4)' ) '   upper-layer    ',   0.0000E+00
         write ( lunout2 , '(A,E13.4)' ) '   upper-layer    ',   0.0000E+00
         write ( lunout1 , '(A,E13.4)' ) '   lower-layer    ',   0.0000E+00
         write ( lunout2 , '(A,E13.4)' ) '   lower-layer    ',   0.0000E+00
         write ( lunout1 , '(A,E13.4)' ) '   interface-depth',   0.0000E+00
         write ( lunout2 , '(A,E13.4)' ) '   interface-depth',   0.0000E+00
         write ( lunout1 , '(A      )' ) 'end-minimum-vert-diffusion'
         write ( lunout2 , '(A      )' ) 'end-minimum-vert-diffusion'
      endif
      write ( lunout1 , '(A      )' ) 'constant-dispersion       '
      write ( lunout2 , '(A      )' ) 'constant-dispersion       '
      write ( lunout1 , '(A,E13.4)' ) '   first-direction ',   0.1000E+01
      write ( lunout2 , '(A,E13.4)' ) '   first-direction ',   0.1000E+01
      write ( lunout1 , '(A,E13.4)' ) '   second-direction',   0.1000E+01
      write ( lunout2 , '(A,E13.4)' ) '   second-direction',   0.1000E+01
      write ( lunout1 , '(A,E13.4)' ) '   third-direction ',   0.1000E-06
      write ( lunout2 , '(A,E13.4)' ) '   third-direction ',   0.1000E-06
      write ( lunout1 , '(A      )' ) 'end-constant-dispersion'
      write ( lunout2 , '(A      )' ) 'end-constant-dispersion'
      write ( lunout1 , '(A      )' ) 'hydrodynamic-layers'
      write ( lunout2 , '(A      )' ) 'hydrodynamic-layers'
      do i = 1,kmax
         write ( lunout1 , '(F15.3  )' ) thick(i)
         write ( lunout2 , '(F15.3  )' ) thick(i)
      enddo
      write ( lunout1 , '(A      )' ) 'end-hydrodynamic-layers'
      write ( lunout2 , '(A      )' ) 'end-hydrodynamic-layers'
      write ( lunout1 , '(A      )' ) 'water-quality-layers   '
      write ( lunout2 , '(A      )' ) 'water-quality-layers   '
      anl = 1.000
      do i = 1,kmax-1
         if ( ilaggr(i+1) .ne. ilaggr(i) ) then
            write ( lunout1 , '(F13.3  )' ) anl
            write ( lunout2 , '(F13.3  )' ) anl
            anl = 1.000
         else
            anl = anl + 1.000
         endif
      enddo
      write ( lunout1 , '(F13.3  )' ) anl
      write ( lunout2 , '(F13.3  )' ) anl
      write ( lunout1 , '(A      )' ) 'end-water-quality-layers'
      write ( lunout2 , '(A      )' ) 'end-water-quality-layers'
      write ( lunout1 , '(A      )' ) 'discharges'
      write ( lunout2 , '(A      )' ) 'discharges'
      nowalk = 0
      il     = 1
      do i = 1,nsrc
         if (mnksrc(3,i) == -1) cycle ! awkward disabling of discharges outside partition when running parallel
         m = mnksrc(1,i)
         n = mnksrc(2,i)
         filstring = ''''//trim(namsrc(i))//''''//' normal'
         if ( mnksrc(7,i) .eq. 1 ) then
            filstring = ''''//trim(namsrc(i))//''''//' walking'
            nowalk = nowalk + 1
            iwlk(nowalk) = i
         endif
         if ( mnksrc(7,i) .eq. 2 ) then
            filstring = ''''//'INLET    '
                              write ( filstring(7:7),'(I1)' ) il
            if ( il .gt.  9 ) write ( filstring(7:8),'(I2)' ) il
            if ( il .gt. 99 ) write ( filstring(7:9),'(I3)' ) il
            filstring = trim(filstring)//' '//trim(namsrc(i))//''''//' inlet'
            il = il + 1
         endif
         if ( mnksrc(7,i) .eq. 3 ) then
            filstring = ''''//'INLET    '
                              write ( filstring(7:7),'(I1)' ) il
            if ( il .gt.  9 ) write ( filstring(7:8),'(I2)' ) il
            if ( il .gt. 99 ) write ( filstring(7:9),'(I3)' ) il
            filstring = trim(filstring)//' '//trim(namsrc(i))//''''//' culvert-inlet'
            il = il + 1
         endif
         if ( zmodel ) then
            kfmin     = kfsmin(n,m)
            ksrwaq(i) = ilaggr(kmax-kfmin+1)     ! store value with source index
            if ( mnksrc(3,i) .eq. 0 ) then ! uniform source over depth
               do ilay = 1, ksrwaq(i)
                  write ( lunout1 , '(3(i0,3x),a)' ) n, m, ilay, trim(filstring)
                  write ( lunout2 , '(2es15.7,1x,i0,1x,a)' ) xz(n,m), yz(n,m), ilay, trim(filstring)
               enddo
            else
               nl = ilaggr(kmax-max(kfmin,mnksrc(3,i))+1)
               write ( lunout1 , '(3(i0,3x),a)' ) n, m, nl, trim(filstring)
               write ( lunout2 , '(2es15.7,1x,i0,1x,a)' ) xz(n,m), yz(n,m), nl, trim(filstring)
            endif
         else
            if ( mnksrc(3,i) .eq. 0 ) then
               write ( lunout1 , '(3(I0,3X),A)' ) n, m, 0, trim(filstring)
               write ( lunout2 , '(2es15.7,1x,i0,1x,a)' ) xz(n,m), yz(n,m), 0, trim(filstring)
            else
               write ( lunout1 , '(3(I0,3X),A)' ) n, m, ilaggr(mnksrc(3,i)), trim(filstring)
               write ( lunout2 , '(2es15.7,1x,i0,1x,a)' ) xz(n,m), yz(n,m), ilaggr(mnksrc(3,i)), trim(filstring)
            endif
         endif
      enddo
      il = 1
      do i = 1,nsrc
         if ( mnksrc(3,i) ==  -1 ) cycle ! awkward disabling of discharges outside partition when running parallel
         if ( mnksrc(7,i) .le. 1 ) cycle
         m = mnksrc(4,i)
         n = mnksrc(5,i)
         if ( mnksrc(7,i) .eq. 2 ) then
            filstring = ''''//'OUTLET    '
                              write ( filstring(8: 8),'(I1)' ) il
            if ( il .gt.  9 ) write ( filstring(8: 9),'(I2)' ) il
            if ( il .gt. 99 ) write ( filstring(8:10),'(I3)' ) il
            filstring = trim(filstring)//' '//trim(namsrc(i))//''''//' outlet'
            il = il + 1
         endif
         if ( mnksrc(7,i) .eq. 3 ) then
            filstring = ''''//'OUTLET    '
                              write ( filstring(8: 8),'(I1)' ) il
            if ( il .gt.  9 ) write ( filstring(8: 9),'(I2)' ) il
            if ( il .gt. 99 ) write ( filstring(8:10),'(I3)' ) il
            filstring = trim(filstring)//' '//trim(namsrc(i))//''''//' culvert-outlet'
            il = il + 1
         endif
         if ( zmodel ) then
            kfmin     = kfsmin(n,m)
            ksrwaq(nsrc+i) = ilaggr(kmax-kfmin+1)     ! store value with source index
            if ( mnksrc(6,i) .eq. 0 ) then ! uniform source over depth
               do ilay = 1, ksrwaq(nsrc+i)
                  write ( lunout1 , '(3(I0,3X),A)' ) n, m, ilay, trim(filstring)
                  write ( lunout2 , '(2es15.7,1x,i0,1x,a)' ) xz(n,m), yz(n,m), ilay, trim(filstring)
               enddo
            else
               nl = ilaggr(kmax-max(kfmin,mnksrc(6,i))+1)
               write ( lunout1 , '(3(I0,3X),A)' ) n, m, nl, trim(filstring)
               write ( lunout2 , '(2es15.7,1x,i0,1x,a)' ) xz(n,m), yz(n,m), nl, trim(filstring)
            endif
         else 
            if ( mnksrc(6,i) .eq. 0 ) then
               write ( lunout1 , '(3(I0,3X),A)' ) n, m, 0, trim(filstring)
               write ( lunout2 , '(2es15.7,1x,i0,1x,a)' ) xz(n,m), yz(n,m), 0, trim(filstring)
            else
               write ( lunout1 , '(3(I0,3X),A)' ) n, m, ilaggr(mnksrc(6,i)), trim(filstring)
               write ( lunout2 , '(2es15.7,1x,i0,1x,a)' ) xz(n,m), yz(n,m), ilaggr(mnksrc(6,i)), trim(filstring)
            endif
         endif
      enddo
      write ( lunout1 , '(A      )' ) 'end-discharges'
      write ( lunout2 , '(A      )' ) 'end-discharges'
      close ( lunout1 )
      close ( lunout2 )
      end subroutine wrwaqhyd
