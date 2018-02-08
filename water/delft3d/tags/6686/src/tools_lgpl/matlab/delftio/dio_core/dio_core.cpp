#include "dio_shm.h"
#include "mex.h"
#include "string.h"

/*----- LGPL --------------------------------------------------------------------
 *
 *   Copyright (C) 2011-2016 Stichting Deltares.
 *
 *   This library is free software; you can redistribute it and/or
 *   modify it under the terms of the GNU Lesser General Public
 *   License as published by the Free Software Foundation version 2.1.
 *
 *   This library is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *   Lesser General Public License for more details.
 *
 *   You should have received a copy of the GNU Lesser General Public
 *   License along with this library; if not, see <http://www.gnu.org/licenses/>.
 *
 *   contact: delft3d.support@deltares.nl
 *   Stichting Deltares
 *   P.O. Box 177
 *   2600 MH Delft, The Netherlands
 *
 *   All indications and logos of, and references to, "Delft3D" and "Deltares"
 *   are registered trademarks of Stichting Deltares, and remain the property of
 *   Stichting Deltares. All rights reserved.
 *
 *-------------------------------------------------------------------------------
 *   http://www.deltaressystems.com
 *   $HeadURL: https://svn.oss.deltares.nl/repos/delft3d/tags/6686/src/tools_lgpl/matlab/delftio/dio_core/dio_core.cpp $
 *   $Id: dio_core.cpp 5717 2016-01-12 11:35:24Z mourits $
 */

/********************************************************************
 *      Check and get string
 ********************************************************************/
char * chkGetString(const mxArray * mxA, const char * StrName)
{
  const int *dimarray;
  int StrLen = -1;
  int ndims = mxGetNumberOfDimensions(mxA);
  if (mxIsChar(mxA) & (ndims == 2)) {
    dimarray = mxGetDimensions(mxA);
    if (dimarray[0]==1)
      StrLen = dimarray[1];
  }

  if (StrLen < 0) {
    char * temp = (char*)mxCalloc(128,sizeof(char));
    strcat(temp,"Invalid ");
    strcat(temp,StrName);
    strcat(temp,".");
    mexErrMsgTxt(temp);
  }
  char * Name = mxArrayToString(mxA);
  if (Name == NULL) {
    mexErrMsgTxt("Memory allocation error.");
  }

/*
  FILE* fid = fopen("d:\stringlog.txt","a");
  fprintf(fid,"'%s'='%s'\n",StrName,Name);
  fclose(fid);
*/
  return Name;
}

/********************************************************************
 *      Process string to be returned
 ********************************************************************/
mxArray * ReturnString(const char * StrName)
{
  int numItems = strlen(StrName);
  void * Data;
  Data = mxCalloc(numItems,2*sizeof(char));
  char * Name = (char *)Data;
  for (int i=0; i<numItems; i++)
    Name[2*i] = StrName[i];

  int * dims = (int *)mxCalloc(2,2);
  dims[0] = 1; dims[1] = numItems;
  mxArray * Export = mxCreateNumericArray(2,dims,mxCHAR_CLASS,mxREAL);
  mxSetData(Export,Data);

  return Export;
}

/********************************************************************
 *      Check and get positive integer
 ********************************************************************/
int chkGetPosInt(const mxArray * mxA)
{
  const int *dimarray;
  int Value = -1;
  int ndims = mxGetNumberOfDimensions(mxA);
  if (mxIsDouble(mxA) & !mxIsComplex(mxA) & (ndims == 2)) {
    dimarray = mxGetDimensions(mxA);
    if ((dimarray[0]==1) & (dimarray[1]==1)) {
      double rValue = mxGetScalar(mxA);
      if (rValue >= 0.0)
        Value = (int)rValue;
    }
  }
  return Value;
}

/********************************************************************
 *      Check and get DioShmPart
 ********************************************************************/
DioShmPart GetDioPart(const mxArray * mxA)
{
  const int *dimarray;
  int StrLen = -1;
  int ndims = mxGetNumberOfDimensions(mxA);
  if (mxIsChar(mxA) & (ndims == 2)) {
    dimarray = mxGetDimensions(mxA);
    if (dimarray[0]==1)
      StrLen = dimarray[1];
  }
  if (StrLen < 0)
    mexErrMsgTxt("Invalid DelftIO Shared Memory Part Identifier");

  char * Name = mxArrayToString(mxA);
  if (Name == NULL)
    mexErrMsgTxt("Memory allocation error.");

  if (strcmp(Name,"header")==0) return DioShmHeaderPart;

  if (strcmp(Name,"data")==0)   return DioShmDataPart;

  mexErrMsgTxt("Invalid DelftIO Shared Memory Part Indentification String");
}

/********************************************************************
 *      Get data share pointer
 ********************************************************************/
DioShmDs * GetDs(const mxArray * mxA)
{
  int dsh = chkGetPosInt(mxA);
  if (dsh < 0)
    mexErrMsgTxt("Invalid data share handle.");
  return (DioShmDs *) dsh;
}

/********************************************************************
 *      Main Program
 ********************************************************************/
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  DioShmDs * ds;

  /*
   *    Default diopart = data part of stream
   */
   DioShmPart diopart = DioShmDataPart;
  /*
   *    Obtain DelftIO command
   */
  if (nrhs<1)
    mexErrMsgTxt("Missing DelftIO command.");
  else if ( mxIsChar(prhs[0]) != 1)
    mexErrMsgTxt("Missing DelftIO command.");
  char * cmdStr = chkGetString(prhs[0],"DelftIO command");

  /******************************************************************
   *    Compare command string with implemented commands
   ******************************************************************/
  if (strcmp(cmdStr,"newput")==0) {
   /*****************************************************************
    *   NEWPUT
    *****************************************************************/
    if (nlhs != 1)
      mexErrMsgTxt("Invalid number of output arguments.");
    else if ((nrhs != 3) & (nrhs != 4))
      mexErrMsgTxt("Invalid number of input arguments.");
    else {
      int nBytesHdr = 0;
      int nBytesData = 0;
      int idx = 1;
      if (nrhs == 3) {
       /*
        * Header size = 0
        * Data size   = user specified
        */

        nBytesData = chkGetPosInt(prhs[1]);
        if (nBytesData < 0)
          mexErrMsgTxt("Invalid data size.");

        idx = 1;
      } else {
       /*
        * Header size = user specified
        * Data size   = user specified
        */

        nBytesHdr = chkGetPosInt(prhs[1]);
        if (nBytesHdr < 0)
          mexErrMsgTxt("Invalid header size.");

        nBytesData = chkGetPosInt(prhs[2]);
        if (nBytesData < 0)
          mexErrMsgTxt("Invalid data size.");

        idx = 2;
      }

      char * DioName = chkGetString(prhs[idx+1],"DelftIO share name");

      ds = new DioShmDs(nBytesHdr, nBytesData, DioShmSharedMem, DioName);
      int dsh = (int) ds;

      plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
      *mxGetPr(plhs[0])=(double)(dsh);
    }
  }
  else if (strcmp(cmdStr,"newget")==0) {
   /*****************************************************************
    *   NEWGET
    *****************************************************************/
    if (nlhs != 1)
      mexErrMsgTxt("Invalid number of output arguments.");
    else if (nrhs != 2)
      mexErrMsgTxt("Invalid number of input arguments.");
    else {
      char * DioName = chkGetString(prhs[1],"DelftIO share name");

      ds = new DioShmDs(DioShmSharedMem, DioName);
      int dsh = (int) ds;

      plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
      *mxGetPr(plhs[0])=(double)(dsh);
    }
  }
  else if (strcmp(cmdStr,"getname")==0) {
   /*****************************************************************
    *   GETNAME
    *****************************************************************/
    if (nlhs != 1)
      mexErrMsgTxt("Invalid number of output arguments.");
    else if (nrhs != 2)
      mexErrMsgTxt("Invalid number of input arguments.");
    else {
      DioShmDs * ds = GetDs(prhs[1]);

      char * DioName = ds->GetName();

      plhs[0] = ReturnString(DioName);

    }
  }
  else if (strcmp(cmdStr,"startwrite")==0) {
   /*****************************************************************
    *   STARTWRITE
    *****************************************************************/
    if (nlhs != 1)
      mexErrMsgTxt("Invalid number of output arguments.");
    else if ((nrhs != 2) & (nrhs != 3))
      mexErrMsgTxt("Invalid number of input arguments.");
    else {
      DioShmDs * ds = GetDs(prhs[1]);

      if (nrhs == 3)
        diopart = GetDioPart(prhs[2]);

      int okay = ds->StartWrite(diopart);

      plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
      *mxGetPr(plhs[0])=(double)(okay);
    }
  }
  else if (strcmp(cmdStr,"startread")==0) {
   /*****************************************************************
    *   STARTREAD
    *****************************************************************/
    if (nlhs != 1)
      mexErrMsgTxt("Invalid number of output arguments.");
    else if ((nrhs != 2) & (nrhs != 3))
      mexErrMsgTxt("Invalid number of input arguments.");
    else {
      DioShmDs * ds = GetDs(prhs[1]);

      if (nrhs == 3)
        diopart = GetDioPart(prhs[2]);

      int okay = ds->StartRead(diopart);

      plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
      *mxGetPr(plhs[0])=(double)(okay);
    }
  }
  else if (strcmp(cmdStr,"getsize")==0) {
   /*****************************************************************
    *   GETSIZE
    *****************************************************************/
    if (nlhs != 1)
      mexErrMsgTxt("Invalid number of output arguments.");
    else if ((nrhs != 2) & (nrhs != 3))
      mexErrMsgTxt("Invalid number of input arguments.");
    else {
      DioShmDs * ds = GetDs(prhs[1]);

      if (nrhs == 3)
        diopart = GetDioPart(prhs[2]);

      int size = ds->GetSize(diopart);

      plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
      *mxGetPr(plhs[0])=(double)(size);
    }
  }
  else if (strcmp(cmdStr,"getremainingsize")==0) {
   /*****************************************************************
    *   GETREMAININGSIZE
    *****************************************************************/
    if (nlhs != 1)
      mexErrMsgTxt("Invalid number of output arguments.");
    else if ((nrhs != 2) & (nrhs != 3))
      mexErrMsgTxt("Invalid number of input arguments.");
    else {
      DioShmDs * ds = GetDs(prhs[1]);

      if (nrhs == 3)
        diopart = GetDioPart(prhs[2]);

      int size = ds->GetRemainingSize(diopart);

      plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
      *mxGetPr(plhs[0])=(double)(size);
    }
  }
  else if (strcmp(cmdStr,"write")==0) {
   /*****************************************************************
    *   WRITE
    *****************************************************************/
    if (nlhs != 0)
      mexErrMsgTxt("Invalid number of output arguments.");
    else if ((nrhs != 3) & (nrhs != 4))
      mexErrMsgTxt("Invalid number of input arguments.");
    else {
      DioShmDs * ds = GetDs(prhs[1]);

     /*
      * Prepare for Writing Data
      */
      int nBytes = 1;
      if (mxIsChar(prhs[2])) {
        nBytes = 2;
      }
      else if (mxIsLogical(prhs[2])) {
        nBytes = 1;
      }
      else if ((mxIsUint8(prhs[2])) | (mxIsInt8(prhs[2]))) {
        nBytes = 1;
      }
      else if ((mxIsUint16(prhs[2])) | (mxIsInt16(prhs[2]))) {
        nBytes = 2;
      }
      else if ((mxIsUint32(prhs[2])) | (mxIsInt32(prhs[2]))) {
        nBytes = 4;
      }
      else if ((mxIsUint64(prhs[2])) | (mxIsInt64(prhs[2]))) {
        nBytes = 8;
      }
      else if (mxIsSingle(prhs[2])) {
        nBytes = 4;
      }
      else if (mxIsDouble(prhs[2])) {
        nBytes = 8;
      }
      else
        mexErrMsgTxt("Cannot transfer supplied data.");

      int numItems = 1;
      int ndims=mxGetNumberOfDimensions(prhs[2]);

      const int *dimarray;
      dimarray = mxGetDimensions(prhs[2]);
      int d;
      for (d=0; d<ndims; d++)
        numItems=numItems * dimarray[d];

      if (nrhs == 4)
        diopart = GetDioPart(prhs[3]);

     /*
      * Write Data
      */
      char * Data =(char*) mxGetData(prhs[2]);
      int numWrite = numItems*nBytes;
      int remSize = ds->GetRemainingSize(diopart);
      if (numWrite > remSize) {
        mexWarnMsgTxt("Data buffer too small. Data transfer will be incomplete.");
        numWrite = (remSize/nBytes)*nBytes;
      }
      ds->Write(diopart, numWrite, Data);
    }
  }
  else if (strcmp(cmdStr,"read")==0) {
   /*****************************************************************
    *   READ
    *****************************************************************/
    if (nlhs != 2)
      mexErrMsgTxt("Invalid number of output arguments.");
    else if ((nrhs != 4) & (nrhs != 5))
      mexErrMsgTxt("Invalid number of input or output arguments.");
    else {
      DioShmDs * ds = GetDs(prhs[1]);

      int numItems = chkGetPosInt(prhs[2]);
      if (numItems < 0)
        mexErrMsgTxt("Invalid number of items.");

      char * dFormat = chkGetString(prhs[3],"data format argument");

     /*
      * Prepare for Reading Data
      */
      int okay = 0;
      int nBytes = 1;
      mxClassID classid = mxUINT8_CLASS;
      void * Data;
      if (strcmp(dFormat,"char")==0) {
        nBytes = 2;
        classid=mxCHAR_CLASS;
      }
      else if (strcmp(dFormat,"logical")==0) {
        nBytes = 1;
        classid=mxLOGICAL_CLASS;
      }
      else if (strcmp(dFormat,"int8")==0) {
        nBytes = 1;
        classid=mxINT8_CLASS;
      }
      else if (strcmp(dFormat,"uint8")==0) {
        nBytes = 1;
        classid=mxUINT8_CLASS;
      }
      else if (strcmp(dFormat,"int16")==0) {
        nBytes = 2;
        classid=mxINT16_CLASS;
      }
      else if (strcmp(dFormat,"uint16")==0) {
        nBytes = 2;
        classid=mxUINT16_CLASS;
      }
      else if (strcmp(dFormat,"int32")==0) {
        nBytes = 4;
        classid=mxINT32_CLASS;
      }
      else if (strcmp(dFormat,"uint32")==0) {
        nBytes = 4;
        classid=mxUINT32_CLASS;
      }
      else if (strcmp(dFormat,"int64")==0) {
        nBytes = 8;
        classid=mxINT64_CLASS;
      }
      else if (strcmp(dFormat,"uint64")==0) {
        nBytes = 8;
        classid=mxUINT64_CLASS;
      }
      else if ((strcmp(dFormat,"single")==0) | (strcmp(dFormat,"float32")==0)) {
        nBytes = 4;
        classid=mxSINGLE_CLASS;
      }
      else if ((strcmp(dFormat,"double")==0) | (strcmp(dFormat,"float64")==0)) {
        nBytes = 8;
        classid=mxDOUBLE_CLASS;
      }
      else
        mexErrMsgTxt("Requested data type invalid or not yet implemented.");

      if (nrhs == 5)
        diopart = GetDioPart(prhs[4]);

     /*
      * Read Data
      */
      Data = mxCalloc(numItems,nBytes);
      int numRead = numItems*nBytes;
      int remSize = ds->GetRemainingSize(diopart);
      if (numRead > remSize) {
        mexWarnMsgTxt("Data buffer too small. Obtained data will be incomplete.");
        numRead = (remSize/nBytes)*nBytes;
      }
      okay = ds->Read(diopart, numRead, (char *)Data);

     /*
      * Return Data
      */
      int * dims = (int *)mxCalloc(2,sizeof(int));
      dims[0] = 1; dims[1] = numItems;
      if (classid == mxCHAR_CLASS) {
        plhs[0] = mxCreateCharArray(2,dims);
	  }
	  else if (classid == mxLOGICAL_CLASS) {
        plhs[0] = mxCreateLogicalArray(2,dims);
	  }
	  else {
        plhs[0] = mxCreateNumericArray(2,dims,classid,mxREAL);
      }
      mxSetData(plhs[0],Data);

     /*
      * Return flag of correct reading
      */
      plhs[1] = mxCreateDoubleMatrix(1,1,mxREAL);
      *mxGetPr(plhs[1])=(double)(okay);
    }
  }
  else if (strcmp(cmdStr,"endwrite")==0) {
   /*****************************************************************
    *   ENDWRITE
    *****************************************************************/
    if (nlhs != 0)
      mexErrMsgTxt("Invalid number of output arguments.");
    else if ((nrhs != 2) & (nrhs != 3))
      mexErrMsgTxt("Invalid number of input arguments.");
    else {
      DioShmDs * ds = GetDs(prhs[1]);

      if (nrhs == 3)
        diopart = GetDioPart(prhs[2]);

      ds->EndWrite(diopart);
    }
  }
  else if (strcmp(cmdStr,"endread")==0) {
   /*****************************************************************
    *   ENDREAD
    *****************************************************************/
    if (nlhs != 0)
      mexErrMsgTxt("Invalid number of output arguments.");
    else if ((nrhs != 2) & (nrhs != 3))
      mexErrMsgTxt("Invalid number of input arguments.");
    else {
      DioShmDs * ds = GetDs(prhs[1]);

      if (nrhs == 3)
        diopart = GetDioPart(prhs[2]);

      ds->EndRead(diopart);
    }
  }
  else if (strcmp(cmdStr,"delete")==0) {
   /*****************************************************************
    *   DELETE
    *****************************************************************/
    if (nlhs != 0)
      mexErrMsgTxt("Invalid number of output arguments.");
    else if (nrhs != 2)
      mexErrMsgTxt("Invalid number of input arguments.");
    else {
      DioShmDs * ds = GetDs(prhs[1]);
      delete ds;
    }
  }
  else {
   /*****************************************************************
    *   Unrecognized command.
    *****************************************************************/
    mexErrMsgTxt("Unrecognized DelftIO command.");
  }
}
