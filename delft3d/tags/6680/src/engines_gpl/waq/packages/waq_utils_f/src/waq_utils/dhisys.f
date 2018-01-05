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

      SUBROUTINE DHISYS ( ISYSI , ISYSN )
!
!     Deltares     SECTOR WATERRESOURCES AND ENVIRONMENT
!
!     CREATED             : march 97 by Jan van Beek
!
!     FUNCTION            : Initialise constant array from common block
!
!     LOGICAL UNITNUMBERS : -
!
!     SUBROUTINES CALLED  : -
!
!     PARAMETERS          : -
!
!     NAME    KIND     LENGTH     FUNCT.  DESCRIPTION
!     ----    -----    ------     ------- -----------
!     ISYSI   INTEGER       *     OUTPUT  copy of the SYSI common block
!     ISYSN   INTEGER       *     OUTPUT  copy of the SYSI common block
!
!     declarations
!
      INTEGER       ISYSI(*), ISYSN(*)
!
!     COMMON  /  SYSN   /   System characteristics
!
      INCLUDE 'sysn.inc'
!
!     COMMON  /  SYSI  /    Timer characteristics
!
      INCLUDE 'sysi.inc'
!
!     input structure for boot-file
!
      INTEGER             IN(INSIZE)       , II(IISIZE)
      EQUIVALENCE       ( IN(1)  , NOSEG ) , ( II(1), ITSTRT  )
!
!     Fill the array's
!
      CALL DHIMOV( II    , ISYSI , IISIZE )
      CALL DHIMOV( IN    , ISYSN , INSIZE )
!
      RETURN
      END
