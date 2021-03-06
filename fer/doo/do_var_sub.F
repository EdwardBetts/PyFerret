	SUBROUTINE DO_VAR_SUB(	idim, com_lo, com_hi,
     .				com, com_mr, com_cx,
     .				res, res_mr, res_cx,
     .				box, stddev )

*
*
*  This software was developed by the Thermal Modeling and Analysis
*  Project(TMAP) of the National Oceanographic and Atmospheric
*  Administration''s (NOAA) Pacific Marine Environmental Lab(PMEL),
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
* (what about COSINE weighting along Y axis if in XY plane ??)
* determine the variance along the indicated axis
* nested with DO_VARIANCE in order to ease the dimension checking of box

* calculation is done in two passes to accomodate unequal weighting and
* to increase numerical stability 

* programmer - steve hankin
* NOAA/PMEL, Seattle, WA - Tropical Modeling and Analysis Program
* written for VAX computer under VMS operating system
*
* V230:   3/2/92
* V420: 11/95 - converted diff and mean to DP so variance is calc in DP
*	 2/96 - fix bug introduced in 11/95: CGRID_AXIS has wrong args
* V664:  8/10 - implement robust method for computing variances
* V672+: 1/12 - previous checkin had wrong indices for result. Return to 
*               divide by n, not n+1
*        2/12 *kms* Add E and F dimensions (use nferdims in tmap_dims.parm)
*
* v687  3/14  *acm* Option to return standard deviation

        IMPLICIT NONE
        include 'tmap_dims.parm'
	include	'ferret.parm'
	include	'interp_stack.parm'
	include	'xcontext.cmn'
	include	'xvariables.cmn'
	include	'xmem_subsc.cmn'

* internal variable declarations:
	LOGICAL stddev
	INTEGER CGRID_AXIS, i, j, k, l, m, n,
     .          grid, pt, lo, hi, axis, npt
	REAL	BOX_SIZE, bad_com, bad_res
	REAL*8	TM_WORLD, dsum, bsum, mean, diff
	REAL*8  x, xmean, xdelta


* calling argument declarations:
	INTEGER	idim, com_lo, com_hi, com_mr, com_cx, res_mr, res_cx
	REAL    com( m1lox:m1hix,m1loy:m1hiy,m1loz:m1hiz,
     .               m1lot:m1hit,m1loe:m1hie,m1lof:m1hif ),
     .          res( m2lox:m2hix,m2loy:m2hiy,m2loz:m2hiz,
     .               m2lot:m2hit,m2loe:m2hie,m2lof:m2hif ),
     .		box( com_lo:com_hi )

* --- end of introductory code ---

* initialize
	grid = mr_grid( com_mr )
	axis = CGRID_AXIS( idim, com_cx )
	pt   = cx_lo_ss( res_cx, idim )
	lo   = com_lo
	hi   = com_hi
	bad_com = mr_bad_data( com_mr )
	bad_res = mr_bad_data( res_mr )

* get and save grid box sizes (weights) just once for efficiency
* (end boxes may be only partially weighted)
	box(lo) = TM_WORLD(lo, grid, idim, box_hi_lim)
     .		- cx_lo_ww(idim,res_cx)
	DO 100 i = lo+1, hi-1
 100	box(i)  = BOX_SIZE( i, grid, idim )
	box(hi) = cx_hi_ww(idim,res_cx)
     .		- TM_WORLD(hi, grid, idim, box_lo_lim)

* ALONG X AXIS
	IF ( idim .EQ. x_dim ) THEN
	   DO 210 n = cx_lo_s6(com_cx), cx_hi_s6(com_cx)
	   DO 210 m = cx_lo_s5(com_cx), cx_hi_s5(com_cx)
	   DO 210 l = cx_lo_s4(com_cx), cx_hi_s4(com_cx)
	   DO 210 k = cx_lo_s3(com_cx), cx_hi_s3(com_cx)
	   DO 210 j = cx_lo_s2(com_cx), cx_hi_s2(com_cx)
* ... Pass #1: determine mean
              npt = 0
	      dsum = 0.0D0	! data
	      bsum = 0.0D0	! boxes
	      DO 200 i = cx_lo_s1(com_cx), cx_hi_s1(com_cx)
	         IF ( com(i,j,k,l,m,n) .EQ. bad_com ) GOTO 200
	         bsum = bsum + box(i)
	         dsum = dsum + box(i)*com(i,j,k,l,m,n)
                 npt = npt + 1
 200	      CONTINUE
	      IF ( npt .LE. 1 ) THEN
	         res(pt,j,k,l,m,n) = bad_res
                 GOTO 210
	      ELSE
                 mean = dsum / bsum
              ENDIF

* ... Pass #2: determine variance or std dev

* Compute variance. See http://en.wikipedia.org/wiki/Algorithms_for_calculating_variance

* On-line algorithm with mean subtracted first. Noted as the most robust.
* Since we always compute the mean first anyway, use it.

	      npt = 0
              xmean = 0.D0
              dsum = 0.D0
              DO 205 i = cx_lo_s1(com_cx), cx_hi_s1(com_cx)
	         x = com(i,j,k,l,m,n)
                 IF ( x .NE. bad_com ) THEN
                    npt = npt + 1
		    x = x - mean
                    xdelta = x - xmean
                    xmean = xmean + xdelta/ FLOAT(npt)
                    dsum = dsum + xdelta*(x - xmean)  ! This expression uses the new value of mean
                  ENDIF
 205          CONTINUE
* because of checking above, npt .GT. 1
	      IF (stddev) THEN
                 res(pt,j,k,l,m,n) = SQRT( dsum / FLOAT(npt) )
	      ELSE
                 res(pt,j,k,l,m,n) = dsum / FLOAT(npt)
	      ENDIF
 210	   CONTINUE

* ALONG Y AXIS
	ELSEIF ( idim .EQ. y_dim ) THEN

	   DO 310 n = cx_lo_s6(com_cx), cx_hi_s6(com_cx)
	   DO 310 m = cx_lo_s5(com_cx), cx_hi_s5(com_cx)
	   DO 310 l = cx_lo_s4(com_cx), cx_hi_s4(com_cx)
	   DO 310 k = cx_lo_s3(com_cx), cx_hi_s3(com_cx)
	   DO 310 i = cx_lo_s1(com_cx), cx_hi_s1(com_cx)
* ... Pass #1: determine mean
              npt = 0
	      dsum = 0.0D0	! data
	      bsum = 0.0D0	! boxes
	      DO 300 j = cx_lo_s2(com_cx), cx_hi_s2(com_cx)
	         IF ( com(i,j,k,l,m,n) .EQ. bad_com ) GOTO 300
	         bsum = bsum + box(j)
	         dsum = dsum + box(j)*com(i,j,k,l,m,n)
                 npt = npt + 1
 300	      CONTINUE
	      IF ( npt .LE. 1 ) THEN
	         res(i,pt,k,l,m,n) = bad_res
                 GOTO 310
	      ELSE
                 mean = dsum / bsum
              ENDIF

* ... Pass #2: determine variance or std dev

* Compute variance. See http://en.wikipedia.org/wiki/Algorithms_for_calculating_variance

* On-line algorithm with mean subtracted first. Noted as the most robust.
* Since we always compute the mean first anyway, use it.

	      npt = 0
              xmean = 0.D0
              dsum = 0.D0
              DO 305 j = cx_lo_s2(com_cx), cx_hi_s2(com_cx)
	         x = com(i,j,k,l,m,n)
                 IF ( x .NE. bad_com ) THEN
	            npt = npt + 1
		    x = x - mean
                    xdelta = x - xmean
                    xmean = xmean + xdelta/ FLOAT(npt)
                    dsum = dsum + xdelta*(x - xmean)  ! This expression uses the new value of mean
                  ENDIF
 305          CONTINUE
* because of checking above, npt .GT. 1
	      IF (stddev) THEN
                 res(i,pt,k,l,m,n)  = SQRT( dsum / FLOAT(npt) )
	      ELSE
                 res(i,pt,k,l,m,n) = dsum / FLOAT(npt)
	      ENDIF
 310	   CONTINUE


* ALONG Z AXIS
	ELSEIF ( idim .EQ. z_dim ) THEN
	   DO 410 n = cx_lo_s6(com_cx), cx_hi_s6(com_cx)
	   DO 410 m = cx_lo_s5(com_cx), cx_hi_s5(com_cx)
	   DO 410 l = cx_lo_s4(com_cx), cx_hi_s4(com_cx)
	   DO 410 j = cx_lo_s2(com_cx), cx_hi_s2(com_cx)
	   DO 410 i = cx_lo_s1(com_cx), cx_hi_s1(com_cx)
* ... Pass #1: determine mean
              npt = 0
	      dsum = 0.0D0	! data
	      bsum = 0.0D0	! boxes
	      DO 400 k = cx_lo_s3(com_cx), cx_hi_s3(com_cx)
	         IF ( com(i,j,k,l,m,n) .EQ. bad_com ) GOTO 400
	         bsum = bsum + box(k)
	         dsum = dsum + box(k)*com(i,j,k,l,m,n)
                 npt = npt + 1
 400	      CONTINUE
	      IF ( npt .LE. 1 ) THEN
	         res(i,j,pt,l,m,n) = bad_res
                 GOTO 410
	      ELSE
                 mean = dsum / bsum
              ENDIF

* ... Pass #2: determine variance or std dev

* Compute variance. See http://en.wikipedia.org/wiki/Algorithms_for_calculating_variance

* On-line algorithm with mean subtracted first. Noted as the most robust.
* Since we always compute the mean first anyway, use it.

	      npt = 0
              xmean = 0.D0
              dsum = 0.D0
	      DO 405 k = cx_lo_s3(com_cx), cx_hi_s3(com_cx)
	         x = com(i,j,k,l,m,n)
                 IF ( x .NE. bad_com ) THEN
	            npt = npt + 1
		    x = x - mean
                    xdelta = x - xmean
                    xmean = xmean + xdelta/ FLOAT(npt)
                    dsum = dsum + xdelta*(x - xmean)  ! This expression uses the new value of mean
                  ENDIF
 405          CONTINUE
* because of checking above, npt .GT. 1
	      IF (stddev) THEN
                 res(i,j,pt,l,m,n)  = SQRT( dsum / FLOAT(npt) )
	      ELSE
                 res(i,j,pt,l,m,n) = dsum / FLOAT(npt)
	      ENDIF
 410	   CONTINUE

* ALONG T AXIS
	ELSEIF ( idim .EQ. t_dim ) THEN
	   DO 510 n = cx_lo_s6(com_cx), cx_hi_s6(com_cx)
	   DO 510 m = cx_lo_s5(com_cx), cx_hi_s5(com_cx)
	   DO 510 k = cx_lo_s3(com_cx), cx_hi_s3(com_cx)
	   DO 510 j = cx_lo_s2(com_cx), cx_hi_s2(com_cx)
	   DO 510 i = cx_lo_s1(com_cx), cx_hi_s1(com_cx)
* ... Pass #1: determine mean
              npt = 0
	      dsum = 0.0D0	! data
	      bsum = 0.0D0	! boxes
	      DO 500 l = cx_lo_s4(com_cx), cx_hi_s4(com_cx)
	         IF ( com(i,j,k,l,m,n) .EQ. bad_com ) GOTO 500
	         bsum = bsum + box(l)
	         dsum = dsum + box(l)*com(i,j,k,l,m,n)
                 npt = npt + 1
 500	      CONTINUE
	      IF ( npt .LE. 1 ) THEN
	         res(i,j,k,pt,m,n) = bad_res
                 GOTO 510
	      ELSE
                 mean = dsum / bsum
              ENDIF

* ... Pass #2: determine variance or std dev

* Compute variance. See http://en.wikipedia.org/wiki/Algorithms_for_calculating_variance

* On-line algorithm with mean subtracted first. Noted as the most robust.
* Since we always compute the mean first anyway, use it.

	      npt = 0
              xmean = 0.D0
              dsum = 0.D0
	      DO 505 l = cx_lo_s4(com_cx), cx_hi_s4(com_cx)
	         x = com(i,j,k,l,m,n)
                 IF ( x .NE. bad_com ) THEN
		    npt = npt + 1
		    x = x - mean
                    xdelta = x - xmean
                    xmean = xmean + xdelta/ FLOAT(npt)
                    dsum = dsum + xdelta*(x - xmean)  ! This expression uses the new value of mean
                  ENDIF
 505          CONTINUE
* because of checking above, npt .GT. 1
	      IF (stddev) THEN
                 res(i,j,k,pt,m,n)  = SQRT( dsum / FLOAT(npt) )
	      ELSE
                 res(i,j,k,pt,m,n) = dsum / FLOAT(npt)
	      ENDIF
 510	   CONTINUE

* ALONG E AXIS
	ELSEIF ( idim .EQ. e_dim ) THEN
	   DO 610 n = cx_lo_s6(com_cx), cx_hi_s6(com_cx)
	   DO 610 l = cx_lo_s4(com_cx), cx_hi_s4(com_cx)
	   DO 610 k = cx_lo_s3(com_cx), cx_hi_s3(com_cx)
	   DO 610 j = cx_lo_s2(com_cx), cx_hi_s2(com_cx)
	   DO 610 i = cx_lo_s1(com_cx), cx_hi_s1(com_cx)
* ... Pass #1: determine mean
              npt = 0
	      dsum = 0.0D0	! data
	      bsum = 0.0D0	! boxes
	      DO 600 m = cx_lo_s5(com_cx), cx_hi_s5(com_cx)
	         IF ( com(i,j,k,l,m,n) .EQ. bad_com ) GOTO 600
	         bsum = bsum + box(m)
	         dsum = dsum + box(m)*com(i,j,k,l,m,n)
                 npt = npt + 1
 600	      CONTINUE
	      IF ( npt .LE. 1 ) THEN
	         res(i,j,k,l,pt,n) = bad_res
                 GOTO 610
	      ELSE
                 mean = dsum / bsum
              ENDIF

* ... Pass #2: determine variance or std dev

* Compute variance. See http://en.wikipedia.org/wiki/Algorithms_for_calculating_variance

* On-line algorithm with mean subtracted first. Noted as the most robust.
* Since we always compute the mean first anyway, use it.

	      npt = 0
              xmean = 0.D0
              dsum = 0.D0
	      DO 605 m = cx_lo_s5(com_cx), cx_hi_s5(com_cx)
	         x = com(i,j,k,l,m,n)
                 IF ( x .NE. bad_com ) THEN
		    npt = npt + 1
		    x = x - mean
                    xdelta = x - xmean
                    xmean = xmean + xdelta/ FLOAT(npt)
                    dsum = dsum + xdelta*(x - xmean)  ! This expression uses the new value of mean
                  ENDIF
 605          CONTINUE
* because of checking above, npt .GT. 1
	      IF (stddev) THEN
                 res(i,j,k,l,pt,n)  = SQRT( dsum / FLOAT(npt) )
	      ELSE
                 res(i,j,k,l,pt,n) = dsum / FLOAT(npt)
	      ENDIF
 610	   CONTINUE

* ALONG F AXIS
	ELSEIF ( idim .EQ. f_dim ) THEN
	   DO 710 m = cx_lo_s5(com_cx), cx_hi_s5(com_cx)
	   DO 710 l = cx_lo_s4(com_cx), cx_hi_s4(com_cx)
	   DO 710 k = cx_lo_s3(com_cx), cx_hi_s3(com_cx)
	   DO 710 j = cx_lo_s2(com_cx), cx_hi_s2(com_cx)
	   DO 710 i = cx_lo_s1(com_cx), cx_hi_s1(com_cx)
* ... Pass #1: determine mean
              npt = 0
	      dsum = 0.0D0	! data
	      bsum = 0.0D0	! boxes
	      DO 700 n = cx_lo_s6(com_cx), cx_hi_s6(com_cx)
	         IF ( com(i,j,k,l,m,n) .EQ. bad_com ) GOTO 700
	         bsum = bsum + box(n)
	         dsum = dsum + box(n)*com(i,j,k,l,m,n)
                 npt = npt + 1
 700	      CONTINUE
	      IF ( npt .LE. 1 ) THEN
	         res(i,j,k,l,m,pt) = bad_res
                 GOTO 710
	      ELSE
                 mean = dsum / bsum
              ENDIF

* ... Pass #2: determine variance or std dev

* Compute variance. See http://en.wikipedia.org/wiki/Algorithms_for_calculating_variance

* On-line algorithm with mean subtracted first. Noted as the most robust.
* Since we always compute the mean first anyway, use it.

	      npt = 0
              xmean = 0.D0
              dsum = 0.D0
	      DO 705 n = cx_lo_s6(com_cx), cx_hi_s6(com_cx)
	         x = com(i,j,k,l,m,n)
                 IF ( x .NE. bad_com ) THEN
		    npt = npt + 1
		    x = x - mean
                    xdelta = x - xmean
                    xmean = xmean + xdelta/ FLOAT(npt)
                    dsum = dsum + xdelta*(x - xmean)  ! This expression uses the new value of mean
                  ENDIF
 705          CONTINUE
* because of checking above, npt .GT. 1
	      IF (stddev) THEN
                 res(i,j,k,l,m,pt) = SQRT( dsum / FLOAT(npt) )
	      ELSE
                 res(i,j,k,l,m,pt) = dsum / FLOAT(npt)
	      ENDIF
 710	   CONTINUE

	ENDIF

* success
	RETURN
	END
