module time_module
   !----- LGPL --------------------------------------------------------------------
   !                                                                               
   !  Copyright (C)  Stichting Deltares, 2011-2016.                                
   !                                                                               
   !  This library is free software; you can redistribute it and/or                
   !  modify it under the terms of the GNU Lesser General Public                   
   !  License as published by the Free Software Foundation version 2.1.            
   !                                                                               
   !  This library is distributed in the hope that it will be useful,              
   !  but WITHOUT ANY WARRANTY; without even the implied warranty of               
   !  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU            
   !  Lesser General Public License for more details.                              
   !                                                                               
   !  You should have received a copy of the GNU Lesser General Public             
   !  License along with this library; if not, see <http://www.gnu.org/licenses/>. 
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
   !  $Id: time_module.f90 6493 2016-08-25 15:20:48Z jagers $
   !  $HeadURL: https://svn.oss.deltares.nl/repos/delft3d/tags/6686/src/utils_lgpl/deltares_common/packages/deltares_common/src/time_module.f90 $
   !!--description-----------------------------------------------------------------
   !
   !    Function: - Various time processing routines
   !
   !!--pseudo code and references--------------------------------------------------
   ! NONE
   !!--declarations----------------------------------------------------------------

   implicit none

   private

   public :: time_module_info
   public :: datetime2sec
   public :: sec2ddhhmmss
   public :: ymd2jul
   public :: jul2ymd
   public :: mjd2jul
   public :: jul2mjd
   public :: date2mjd
   public :: mjd2date
   public :: datetime_to_string
   public :: parse_ud_timeunit

   interface ymd2jul
      module procedure GregorianDateToJulianDateNumber
      module procedure GregorianYearMonthDayToJulianDateNumber
   end interface ymd2jul

   interface jul2ymd
      module procedure JulianDateNumberToGregorianDate
      module procedure JulianDateNumberToGregorianYearMonthDay
   end interface jul2ymd

   interface date2mjd
      module procedure ymd2mjd
      module procedure ymdhms2mjd
      module procedure datetime2mjd
   end interface date2mjd

   interface mjd2date
      module procedure mjd2datetime
      module procedure mjd2ymdhms
      module procedure mjd2ymd
   end interface mjd2date
   
   interface datetime_to_string
      module procedure datetime2string
      module procedure jul_frac2string
      module procedure mjd2string
   end interface datetime_to_string

   contains
      
      ! ------------------------------------------------------------------------------
      !   Subroutine: time_module_info
      !   Purpose:    Add info about this time module to the messages stack
      !   Summary:    Add id string and URL
      !   Arguments:
      !   messages    Stack of messages to add the info to
      ! ------------------------------------------------------------------------------
      subroutine time_module_info(messages)
          use message_module
          !
          ! Call variables
          !
          type(message_stack), pointer :: messages
          !
          !! executable statements ---------------------------------------------------
          !
          call addmessage(messages,'$Id: time_module.f90 6493 2016-08-25 15:20:48Z jagers $')
          call addmessage(messages,'$URL: https://svn.oss.deltares.nl/repos/delft3d/tags/6686/src/utils_lgpl/deltares_common/packages/deltares_common/src/time_module.f90 $')
      end subroutine time_module_info
      
      
      
      ! ------------------------------------------------------------------------------
      !   Subroutine: datetime2sec
      !   Purpose:    Convert a 6 integer datetime vector to a number of seconds
      !   Arguments:
      !   datetime    Integer array of length 6 containing date yr,mo,dy and time hr,mn,sc
      !   refdatetime Optional integer array of length 6 containing reference date yr,mo,dy and time hr,mn,sc
      !   sec         If refdatetime is specified: time difference in seconds
      !               Otherwise: time in seconds since julday = 0 (only to be used for time steps)
      ! ------------------------------------------------------------------------------
      function datetime2sec(datetime, refdatetime) result (sec)
          !
          ! Call variables
          !
          integer, dimension(6)           , intent(in)    :: datetime
          integer, dimension(6) , optional, intent(in)    :: refdatetime
          integer                                         :: sec
          !
          ! Local variables
          !
          integer :: jd    ! Julian date
          integer :: refjd ! Julian refernce date
          !
          !! executable statements ---------------------------------------------------
          !
          jd    = ymd2jul(datetime(1), datetime(2), datetime(3))
          !
          if (present(refdatetime)) then
             refjd = ymd2jul(refdatetime(1), refdatetime(2), refdatetime(3))
             ! difference in days
             sec   = jd - refjd
             ! difference in hours
             sec   = sec*24 + datetime(4) - refdatetime(4)
             ! difference in minutes
             sec   = sec*60 + datetime(5) - refdatetime(5)
             ! difference in seconds
             sec   = sec*60 + datetime(6) - refdatetime(6)
          else
             ! time in hours
             sec   = jd*24 + datetime(4)
             ! time in minutes
             sec   = sec*60 + datetime(5)
             ! time in seconds
             sec   = sec*60 + datetime(6)
          endif
      end function datetime2sec
      
      
      
      ! ------------------------------------------------------------------------------
      !   Subroutine: sec2ddhhmmss
      !   Purpose:    Convert a number of seconds to ddhhmmss integer
      !   Arguments:
      !   sec         Number of seconds
      !   ddhhmmss    Integer with days, hours, minutes and seconds formatted as ddhhmmss 
      ! ------------------------------------------------------------------------------
      function sec2ddhhmmss(sec) result (ddhhmmss)
          !
          ! Call variables
          !
          integer                         , intent(in)    :: sec
          integer                                         :: ddhhmmss
          !
          ! Local variables
          !
          integer :: dd ! days
          integer :: hh ! hours
          integer :: mm ! minutes
          integer :: ss ! seconds
          !
          !! executable statements ---------------------------------------------------
          !
          ! time in seconds
          dd = sec
          ss = mod(dd,60)
          ! time in minutes
          dd = (dd - ss)/60
          mm = mod(dd,60)
          ! time in hours
          dd = (dd - mm)/60
          hh = mod(dd,24)
          ! time in days
          dd = (dd - hh)/24
          !
          ddhhmmss = ss + 100*mm + 10000*hh + 1000000*dd
      end function sec2ddhhmmss

      ! =======================================================================
      
      !> Calculates the Julian Date Number from a Gregorian calender date.
      !! Returns 0 in case of failure.
      function GregorianDateToJulianDateNumber(yyyymmdd) result(jdn)
         integer             :: jdn      !< calculated Julian Date Number
         integer, intent(in) :: yyyymmdd !< Gregorian calender date
         !
         integer :: year  !< helper variable
         integer :: month !< helper variable
         integer :: day   !< helper variable
         !
         year = yyyymmdd/10000
         month = yyyymmdd/100 - year*100
         day = yyyymmdd - month*100 - year*10000
         jdn = GregorianYearMonthDayToJulianDateNumber(year, month, day)
      end function GregorianDateToJulianDateNumber
      
      ! =======================================================================
      
      !> Calculates the Julian Date Number from a Gregorian year, month and day.
      !! Returns 0 in case of failure.
      function GregorianYearMonthDayToJulianDateNumber(year, month, day) result(jdn)
         integer :: jdn               !< calculated Julian Date Number
         integer, intent(in) :: year  !< Gregorian year
         integer, intent(in) :: month !< Gregorian month
         integer, intent(in) :: day   !< Gregorian day
         !
         integer :: month1 !< helper variable
         integer :: y      !< helper variable
         integer :: m      !< helper variable
         integer :: d      !< helper variable
         !
         ! Calculate Julian day assuming the given month is correct
         !
         month1 = (month - 14)/12
         jdn = day - 32075 + 1461*(year + 4800 + month1)/4 &
                           + 367*(month - 2 - month1*12)/12 &
                           - 3*((year + 4900 + month1)/100)/4
         !
         ! Calculate backwards to test if the assumption is correct
         !
         call jul2ymd(jdn, y, m, d)
         !
         ! Test if calculation is correct
         !
         if ((y /= year) .or. (m /= month) .or. (d /= day)) then
            jdn = 0
         endif
      end function GregorianYearMonthDayToJulianDateNumber
      
      ! =======================================================================
      
      !> Calculates the Gregorian calender date from a Julian Date Number.
      subroutine JulianDateNumberToGregorianDate(jdn, yyyymmdd)
         integer, intent(in) :: jdn       !< Julian Date Number
         integer, intent(out) :: yyyymmdd !< calculated Gregorian calender date
         !
         integer :: year  !< helper variable
         integer :: month !< helper variable
         integer :: day   !< helper variable
         !
         call JulianDateNumberToGregorianYearMonthDay(jdn, year, month, day)
         yyyymmdd = year*10000 + month*100 + day
      end subroutine JulianDateNumberToGregorianDate
      
      ! =======================================================================
      
      !> Calculates the Gregorian year, month, day triplet from a Julian Date Number.
      subroutine JulianDateNumberToGregorianYearMonthDay(jdn, year, month, day)
         integer, intent(in)  :: jdn   !< Julian Date Number
         integer, intent(out) :: year  !< calculated Gregorian year
         integer, intent(out) :: month !< calculated Gregorian month
         integer, intent(out) :: day   !< calculated Gregorian day
         !
         integer :: j !< helper variable
         integer :: l !< helper variable
         integer :: m !< helper variable
         integer :: n !< helper variable
         !
         l      = jdn + 68569
         n      = 4 * l / 146097
         l      = l - (146097*n + 3)/4
         j      = 4000 * (l + 1) / 1461001
         l      = l - 1461*j/4 + 31
         m      = 80 * l / 2447
         day    = l - 2447*m/80
         l      = m / 11
         month  = m + 2 - 12*l
         year   = 100*(n-49) + j + l
      end subroutine JulianDateNumberToGregorianYearMonthDay

      ! =======================================================================
      
      !> Parses an UDUnit-conventions datetime unit string.
      !! TODO: replace this by calling C-API from UDUnits(-2).
      function parse_ud_timeunit(timeunitstr, iunit, iyear, imonth, iday, ihour, imin, isec) result(ierr)
         character(len=*), intent(in)  :: timeunitstr !< Time unit by UDUnits conventions, e.g. 'seconds since 2012-01-01 00:00:00.0 +0000'.
         integer,          intent(out) :: iunit       !< Unit in seconds, i.e. 'hours since..' has iunit=3600.
         integer,          intent(out) :: iyear       !< Year in reference datetime.
         integer,          intent(out) :: imonth      !< Month in reference datetime.
         integer,          intent(out) :: iday        !< Day in reference datetime.
         integer,          intent(out) :: ihour       !< Hour in reference datetime.
         integer,          intent(out) :: imin        !< Minute in reference datetime.
         integer,          intent(out) :: isec        !< Seconds in reference datetime.
         integer                       :: ierr        !< Error status, only 0 when successful.
         !
         integer          :: i
         integer          :: n
         integer          :: ifound
         integer          :: iostat
         character(len=7) :: unitstr
         !
         ierr    = 0
         unitstr = ' '
         !
         n = len_trim(timeunitstr)
         ifound = 0
         do i = 1,n
            if (timeunitstr(i:i) == ' ') then ! First space found
               if (timeunitstr(i+1:min(n, i+5)) == 'since') then
                  unitstr = timeunitstr(1:i-1)
                  ifound = 1
               else
                  ierr = 1
               end if
               exit ! Found or error, look no further.
            end if
         end do
         !
         if (ifound == 1) then
            select case(trim(unitstr))
            case('seconds')
               iunit = 1
            case('minutes')
               iunit = 60
            case('hours')
               iunit = 3600
            case('days')
               iunit = 86400
            case('weeks')
               iunit = 604800
            case default
               iunit = -1
            end select
            !
            read (timeunitstr(i+7:n), '(I4,1H,I2,1H,I2,1H,I2,1H,I2,1H,I2)', iostat = iostat) iyear, imonth, iday, ihour, imin, isec
         end if
      end function parse_ud_timeunit

!---------------------------------------------------------------------------------------------
! implements interface datetime_to_string
!---------------------------------------------------------------------------------------------
      !> Creates a string representation of a date time, in the ISO 8601 format.
      !! Example: 2015-08-07T18:30:27Z
      !! 2015-08-07T18:30:27+00:00
      !! Performs no check on validity of input numbers!
      function datetime2string(iyear, imonth, iday, ihour, imin, isec, ierr) result(datetimestr)
         integer,           intent(in)  :: iyear, imonth, iday
         integer, optional, intent(in)  :: ihour, imin, isec !< Time is optional, will be printed as 00:00:00 if omitted.
         integer, optional, intent(out) :: ierr !< Error status, 0 if success, nonzero in case of format error.

         character(len=20) :: datetimestr !< The resulting date time string. Considering using trim() on it.

         integer :: ihour_, imin_, isec_, ierr_
         if (.not. present(ihour)) then
            ihour_ = 0
         else
            ihour_ = ihour
         end if
         if (.not. present(imin)) then
            imin_ = 0
         else
            imin_ = imin
         end if
         if (.not. present(isec)) then
            isec_ = 0
         else
            isec_ = isec
         end if

         write (datetimestr, '(i4,"-",i2.2,"-",i2.2,"T",i2.2,":",i2.2,":",i2.2,"Z")', iostat=ierr_) &
                               iyear, imonth, iday, ihour_, imin_, isec_

         if (present(ierr)) then
            ierr = ierr_
         end if
      end function datetime2string
      
      function jul_frac2string(jul, dayfrac, ierr) result(datetimestr)
         use precision_basics
         implicit none
         integer           , intent(in)  :: jul
         real(hp), optional, intent(in)  :: dayfrac
         integer , optional, intent(out) :: ierr        !< Error status, 0 if success, nonzero in case of format error.
         character(len=20)               :: datetimestr !< The resulting date time string. Considering using trim() on it.

         real(hp) :: days
         real(hp) :: dayfrac_
         integer  :: ierr_
         
         if (present(dayfrac)) then
             dayfrac_ = dayfrac
         else
             dayfrac_ = 0.0_hp
         end if
         datetimestr = mjd2string(jul2mjd(jul,dayfrac_), ierr_)
         if (present(ierr)) then
            ierr = ierr_
         end if
      end function jul_frac2string
      
      function mjd2string(days, ierr) result(datetimestr)
         use precision_basics
         implicit none
         real(hp)          , intent(in)  :: days
         integer , optional, intent(out) :: ierr        !< Error status, 0 if success, nonzero in case of format error.
         character(len=20)               :: datetimestr !< The resulting date time string. Considering using trim() on it.

         integer  :: iyear, imonth, iday, ihour, imin, isec
         real(hp) :: second
         integer  :: ierr_
         
         ierr_ = -1
         if (mjd2datetime(days,iyear,imonth,iday,ihour,imin,second)/=0) then
            isec = nint(second) ! unfortunately rounding instead of truncating requires all of the following checks
            if (isec == 60) then
               imin = imin+1
               isec = 0
            endif
            if (imin == 60) then
               ihour = ihour+1
               imin = 0
            endif
            if (ihour == 24) then
               iday = iday+1
               ihour = 0
            endif
            select case(imonth)
            case (1,3,5,7,8,10) ! 31 days
               if (iday == 32) then
                  imonth = imonth+1
                  iday = 1
               endif
            case (12) ! 31 days
               if (iday == 32) then
                  iyear = iyear+1
                  imonth = 1
                  iday = 1
               endif
            case (4,6,9,11) ! 30 days
               if (iday == 31) then
                  imonth = imonth+1
                  iday = 1
               endif
            case default ! February
                if ((iyear/4)*4==iyear .and. (.not.(iyear/100)*100==iyear .or. &
                                              &    (iyear/400)*400==iyear)) then ! leap year, 29 days
                   if (iday == 30) then
                      imonth = 3
                      iday = 1
                   endif
                else ! 28 days
                   if (iday == 29) then
                      imonth = 3
                      iday = 1
                   endif
                endif
            end select
            datetimestr = datetime2string(iyear, imonth, iday, ihour, imin, isec, ierr_)
         else
            ierr_ = -1
            datetimestr = ' '
         endif
         if (present(ierr)) then
            ierr = ierr_
         end if
      end function mjd2string


!---------------------------------------------------------------------------------------------
! implements interface date2mjd
!---------------------------------------------------------------------------------------------
      function ymd2mjd(ymd) result(days)
         use precision_basics
         implicit none
         integer, intent(in)       :: ymd
         real(hp)                  :: days
         integer  :: year, month, day, hour, minute
         real(hp) :: second
         year   = int(ymd/10000)
         month  = int(mod(ymd,10000)/100)
         day    = mod(ymd,100)
         days = datetime2mjd(year,month,day,0,0,0.d0)
      end function

      function ymdhms2mjd(ymd,hms) result(days)
         use precision_basics
         implicit none
         integer, intent(in)       :: ymd
         real(hp), intent(in)      :: hms
         real(hp)                  :: days
         integer  :: year, month, day, hour, minute
         real(hp) :: second
         year   = int(ymd/10000)
         month  = int(mod(ymd,10000)/100)
         day    = mod(ymd,100)
         hour   = int(hms/10000)
         minute = int(mod(hms,10000.d0)/100)
         second = mod(hms,100.d0)
         days = datetime2mjd(year,month,day,hour,minute,second)
      end function

      function datetime2mjd(year,month,day,hour,minute,second) result(days)
         use precision_basics
         implicit none
         integer, intent(in)	:: year, month, day	
         integer, intent(in)	:: hour, minute
         real(hp):: second
         real(hp) :: days
         real(hp) :: dayfrac
         dayfrac = (hour*3600+minute*60+second)/(24*3600)
         days = jul2mjd(GregorianYearMonthDayToJulianDateNumber(year,month,day),dayfrac)
      end function datetime2mjd

!---------------------------------------------------------------------------------------------
      function mjd2jul(days,frac) result(jul)
         use precision_basics
         implicit none
         real(hp)          , intent(in)  :: days
         real(hp), optional, intent(out) :: frac
         integer                         :: jul

         jul = int(days+2400001.0_hp) ! should use 2400000.5_hp ?
         if (present(frac)) then
             frac = mod(days,1.0_hp)  ! should use days + 0.5_hp ?
         endif
      end function mjd2jul

      function jul2mjd(jul,frac) result(days)
         use precision_basics
         implicit none
         integer           , intent(in)  :: jul
         real(hp), optional, intent(in)  :: frac
         real(hp)                        :: days

         days = real(jul,hp)-2400001.0_hp ! should use 2400000.5_hp ?
         if (present(frac)) then
             days = days + frac
         endif
      end function jul2mjd

!---------------------------------------------------------------------------------------------
! implements interface mjd2date
!---------------------------------------------------------------------------------------------
      function mjd2ymd(days,ymd) result(success)
         use precision_basics
         implicit none
         real(hp), intent(in)       :: days
         integer, intent(out)       :: ymd
         integer  :: year, month, day, hour, minute
         real(hp) :: second
         integer  :: success
         
         success = 0
         if (mjd2datetime(days,year,month,day,hour,minute,second)==0) return
         ymd = year*10000 + month*100 + day
         success = 1
      end function mjd2ymd

      function mjd2ymdhms(days,ymd,hms) result(success)
         use precision_basics
         implicit none
         real(hp), intent(in)       :: days
         integer, intent(out)       :: ymd
         real(hp), intent(out)      :: hms
         integer  :: year, month, day, hour, minute
         real(hp) :: second
         integer  :: success
         
         success = 0
         if (mjd2datetime(days,year,month,day,hour,minute,second)==0) return
         ymd = year*10000 + month*100 + day
         hms = hour*10000 + minute*100 + second
         success = 1
      end function mjd2ymdhms

      function mjd2datetime(days,year,month,day,hour,minute,second) result(success)
         use precision_basics
         implicit none
         real(hp), intent(in)  :: days
         integer,  intent(out) :: year, month, day	
         integer,  intent(out) :: hour, minute
         real(hp), intent(out) :: second
         real(hp) :: dayfrac
         integer  :: jul
         integer  :: success
         
         success = 0
         jul = mjd2jul(days,dayfrac)
         call JulianDateNumberToGregorianYearMonthDay(jul,year,month,day)
         hour = int(dayfrac*24)
         minute = int(mod(dayfrac*24*60,60.d0))
         second = mod(dayfrac*24*60*60,60.d0)
         success = 1
      end function mjd2datetime
      
end module time_module
