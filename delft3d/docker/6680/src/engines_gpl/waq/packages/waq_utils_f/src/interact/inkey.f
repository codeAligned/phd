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

! Subroutine INKEY to check keyboard input.
! Calls assembler program CHKKEY.
! To provide compatability with previous versions, the scan key info
! is discarded!
!
      SUBROUTINE INKEY (KEY)
      INTEGER KEY, KKEY
10    KEY = 1
      CALL CHKKEY (KEY)
      IF (KEY .EQ. 0) GO TO 10
      KKEY = MOD(KEY,256)
      IF (KKEY .EQ. 0) RETURN
      KEY = KKEY
      RETURN
      END
      SUBROUTINE CHKKEY(KEY)
      INTEGER KEY
      KEY = 1
      RETURN
      END
