	INTEGER FUNCTION TM_FERRET_VARTYPE (ncvtype)

*  This software was developed by the Thermal Modeling and Analysis
*  Project(TMAP) of the National Oceanographic and Atmospheric
*  Administration's (NOAA) Pacific Marine Environmental Lab(PMEL),
*  hereafter referred to as NOAA/PMEL/TMAP.
*
*  Access and use of this software shall impose the following
*  obligations and understandings on the user. The user is granted the
*  right, without any fee or cost, to use, copy, modify, alter, enhance
*  and distribute this software, and any derivative works thereof, and
*  its supporting documentation for any purpose whatsoever, provided
*  that this entire notice appears in all copies of the software,
*  derivative works and supporting documentation.  Further, the user
*  agrees to credit NOAA/PMEL/TMAP in any publications that result from
*  the use of this software or in any product that includes this
*  software. The names TMAP, NOAA and/or PMEL, however, may not be used
*  in any advertising or publicity to endorse or promote any products
*  or commercial entity unless specific written permission is obtained
*  from NOAA/PMEL/TMAP. The user also understands that NOAA/PMEL/TMAP
*  is not obligated to provide the user with any support, consulting,
*  training or assistance of any kind with regard to the use, operation
*  and performance of this software nor to provide the user with any
*  updates, revisions, new versions or "bug fixes".
*
*  THIS SOFTWARE IS PROVIDED BY NOAA/PMEL/TMAP "AS IS" AND ANY EXPRESS
*  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
*  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
*  ARE DISCLAIMED. IN NO EVENT SHALL NOAA/PMEL/TMAP BE LIABLE FOR ANY SPECIAL,
*  INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER
*  RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF
*  CONTRACT, NEGLIGENCE OR OTHER TORTUOUS ACTION, ARISING OUT OF OR IN
*  CONNECTION WITH THE ACCESS, USE OR PERFORMANCE OF THIS SOFTWARE. 
*
*
* Given a netCDF variable type return the corresponding Ferret parameter

* V533 *sh* 6/01
* V540 *acm* per SH email of 10/19/01  For datasets with datatype "short"
*            Ferret translates the "short" to "float" but the new code 
*            made it think that the variable is, indeed, of type short.
* V65  *acm* 1/10  Change all netcdf2-style calls and parameter names to 
*                  netcdf3-style calls, which are also consistent with netcdf4.
* V6.74 3/12 *acm* cleanup ifdefs and unnecessary include files

	include 'tmap_dtypes.parm'
        include 'netcdf.inc'

* input arguments
	INTEGER	ncvtype

	IF (ncvtype .EQ. NF_FLOAT) THEN
	  TM_FERRET_VARTYPE =  ptype_float
	ELSEIF (ncvtype .EQ. NF_CHAR) THEN
	  TM_FERRET_VARTYPE =  ptype_string
	ELSEIF (ncvtype .EQ. NF_DOUBLE) THEN
	  TM_FERRET_VARTYPE =  ptype_double
	ELSEIF (ncvtype .EQ. NF_INT) THEN
	  TM_FERRET_VARTYPE =  ptype_int4
	ELSEIF (ncvtype .EQ. NF_SHORT) THEN
	  TM_FERRET_VARTYPE =  ptype_int2
	ELSEIF (ncvtype .EQ. NF_BYTE) THEN
	  TM_FERRET_VARTYPE =  ptype_int1
	ELSE
	  CALL WARN('Internal err: unknown data type')
	  TM_FERRET_VARTYPE = ptype_float
	ENDIF

* full data type support not implemented as-of 10/01. 
* cd_read will convert all numeric data to float

       IF ( ncvtype .NE. NF_CHAR) TM_FERRET_VARTYPE =  ptype_float

	RETURN
	END
