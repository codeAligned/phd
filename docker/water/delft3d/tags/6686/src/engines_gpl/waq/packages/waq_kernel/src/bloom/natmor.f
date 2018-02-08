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
!  *********************************************************************
!  *     SUBROUTINE TO SET,CALCULATE OR CALIBRATE NATURAL MORTALITY    *
!  *                       RATE CONSTANT                               *
!  *********************************************************************
!
!  971217 MvdV extra mortality above critical temp for ulvae
!  0895 MvdV output of grazer biomass extended for multiple grazer types

      SUBROUTINE NATMOR(DEATH,ZOOD,TEMP,LCOUPL)
      IMPLICIT REAL*8 (A-H,O-Z)
      INCLUDE 'blmdim.inc'
      INCLUDE 'size.inc'
      INCLUDE 'phyt2.inc'
      INCLUDE 'cal1.inc'
      INCLUDE 'graas.inc'
      INCLUDE 'ioblck.inc'
      REAL*8 ZOOD(0:MG)
!
!  IF LCAL=1 DEATH IS PUT EQUAL TO THE INPUT VALUE
!
!  IF LCAL=4 DEATH IS CALCULATED AS RMORT1(I) * RMORT2(I) ** TEMP
!
!  DETERMINE HOW DEATH IS TO BE ESTABLISHED
!
      IF (LCAL .EQ. 4) GO TO 70
!
!  LCAL=1
!
      DO 10 I = 1,NUSPEC
   10 RMORT(I) = DEATH
      IF (NREP .GT. 1) GO TO 110
      IF (FLUSH .LT. 1.0D-6) GO TO 30
      IF (IDUMP .EQ. 1) WRITE(IOU(6),20) FLUSH
   20 FORMAT(2X,'Input mortality rates +',2X,F6.2,2X,'are used')
      GO TO 50
   30 CONTINUE
      IF (IDUMP .EQ. 1) WRITE(IOU(6),40)
   40 FORMAT(2X,'Input natural mortality rates are used')
   50 CONTINUE
      GO TO 110
!
!  LCAL=4. STORE MAXIMUM DEATH RATE IN DEATH.
!  Compute mortatlity rate constant or set to BASMOR if option TEMPLIM
!  is on and TEMP is below TEMLIM.
!
   70 CONTINUE
      TEMP2 = TEMP
      IF (LTLIM .EQ. 0) GO TO 90
      IF (TEMP .GE. TEMLIM) GO TO 90
      IF ((NREP .EQ. 1).AND.(LCOUPL.EQ.0)) THEN
         TEMP2 = TEMP + 5.0
         GO TO 90
      END IF
         DO 80 I = 1,NUSPEC
         RMORT(I) = BASMOR
   80    CONTINUE
         DEATH = BASMOR
         GO TO 110
   90 DEATH = 0.0
      DO 100 I = 1,NUSPEC
!       MvdV 971217 addition for ulvae
!       critical temperature in RMORT2
!       RMORT2 (temperature correction) = 1.0
!       temperature muliplication factor in RMORT3
        IF (RMORT2(I).GE.0) THEN
          TMPCOR = RMORT2(I)
        ELSE
          TMPCOR = 1.0
        ENDIF
        RMORT(I) = RMORT1(I) * TMPCOR ** TEMP2
        IF ((RMORT2(I).LT.0.).AND.(TEMP.GT.-1.*RMORT2(I)))
     1    RMORT(I) = MAX(RMORT(I),(TEMP+RMORT2(I)) * RMORT3(I))
        IF (RMORT(I) .GT. DEATH) DEATH = RMORT(I)
  100 CONTINUE
  110 CONTINUE
      RETURN
      END
