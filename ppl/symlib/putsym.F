	SUBROUTINE PUTSYM(STR,LABEL,NC,IER)
*
*
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
C**    @(#)putsym.F	1.2    5/26/88
C**
C**
C***********************************************************************
C**
C**		    PLOT+ Scientific Graphics System
C**
C***********************************************************************
C**
C**
C**	Subprogram called:
C**		CALL PUTSYM(STR,LABEL,NC,IER)
C**
C**	Parameters:
C**		STR -- Symbol name (char*120)
C**		LABEL -- Value of symbol (char*2048)
C**		NC -- length of LABEL
C**		IER -- error code
C**			0 = sucess
C**			1 = error other than symbol not found
C**
C**	Description:
C**		Updates or creates the value for symbol STR.
C**
C**	History:
C**	    Written:
C**		15-DEC-1985	by Donald W. Denbo
C**	    Modified:
C**
C**
C *kob* 04/07/96 passed in character strings had to be declared 
C                with "*(*)" for the linux port 
C* v552 *acm* 3/03 Longer strings: changes for multi-line labels
* V686 *acm* 11/13 Allow symbol names to be up to 120 characters long

	INCLUDE 'SYSTEM.INC'
	INCLUDE 'SYMKEY.INC'

	LOGICAL SYS
	INTEGER LUN
	CHARACTER STR*(*),LABEL*(*)
	
	INTEGER symlen
	PARAMETER (symlen = 120)

	CALL SYMCNV(STR,SYS)
	IER=0
	LUN=KEYLN1
	ilen=lnblk(str,symlen)
	IF(SYS)GOTO 100
	IF(SMKEY2)LUN=KEYLN2
100	call dbmstore(lun,str,ilen,label,nc,ier)
	RETURN
	END
