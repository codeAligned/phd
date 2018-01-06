!!  Copyright (C)  Stichting Deltares, 2012-2016.
!!
!!  This program is free software: you can redistribute it and/or modify
!!  it under the terms of the GNU General Public License version 3,
!!  as published by the Free Software Foundation.
!!
!!  This program is distributed in the hope that it will be useful,
!!  but WITHOUT ANY WARRANTY; without even the implied warranty of
!!  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
!!  GNU General Public License for more details.
!!
!!  You should have received a copy of the GNU General Public License
!!  along with this program. If not, see <http://www.gnu.org/licenses/>.
!!
!!  contact: delft3d.support@deltares.nl
!!  Stichting Deltares
!!  P.O. Box 177
!!  2600 MH Delft, The Netherlands
!!
!!  All indications and logos of, and references to registered trademarks
!!  of Stichting Deltares remain the property of Stichting Deltares. All
!!  rights reserved.

!
! Integer function to obtain the length of a character string.
! The non-significant characters are initially set to a space and
! a comma, but can be reset by function SETDLM.
!
      INTEGER FUNCTION LENSTR (SOURCE,MAXLEN)
      CHARACTER*1 SOURCE(*)
      CHARACTER*255 RESULT
      INTEGER GETS, POS
!
      POS = 1
      DO 10 I = 1,MAXLEN
      IF (GETS(SOURCE,POS,MAXLEN,255,RESULT,LENOUT) .NE. 0) GO TO 20
10    CONTINUE
20    CONTINUE
      LENSTR = POS - 1
      RETURN
      END
