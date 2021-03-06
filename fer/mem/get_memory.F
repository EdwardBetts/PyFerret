	SUBROUTINE GET_MEMORY ( num_words, grid_blocks, mblk, num_blocks, status )

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
* find and reserve a section of contiguous memory sufficient to hold grid_blocks 
* procedure:
* first check the list of free memory regions to see if there is one big enough
* if not then delete variables working from the tail of the priority chain
* when an adequate region is found pluck what it needed of it from the free list

* programmer - steve hankin
* NOAA/PMEL, Seattle, WA - Tropical Modeling and Analysis Program
* written for VAX computer under VMS operating system
*
* revision 0.0 - 3/31/86
* revision 0.1 - 7/21/88 - no special call to "CLAIM_MEMORY" since FIND_MEMORY
*			   claims it, too, now
* V200:  6/12/89 - delete priorities handled through linked lists
*		 - eliminated FIND_MEMORY
*	  4/5/90 - spruced up error message
* V230:  4/30/92 - added coaching to error message
* V500:  3.20.99 Make sure num_words >= 0 (absurdly large grids can overflow
*                integer) js
* V520: 6/00 *sh* - improved error message
* V522: 7/00 *sh* corrected typo in previous ... 
* V530: 5/01 - further improved error mesages (for 9999999 words)
* v553: 9/03 *kob* - need to update error calls to include alternate return
*                    label.  Bug showed up on IRIX with missing elements
*		     of error statement
*        2/12 *kms* Add E and F dimensions (use nferdims in tmap_dims.parm)
* V685 *acm*  6/13 Increase nominal length of abstract axis
* V69+ *acm*  9/14 Ticket 1758. Memory request uses number of blocks not words
* V697 *acm*  1/16 Ticket 2354. Never adjusted for double-precision Ferret. Also
*                  round up the integer value of needed Mwords shown.

        IMPLICIT NONE
        include 'tmap_dims.parm'
	include 'errmsg.parm'
	include	'ferret.parm'
	include 'xvariables.cmn'

* calling argument declarations:
	INTEGER	num_words, grid_blocks, mblk, num_blocks, status

* internal variable declarations:
	INTEGER	mr, next, prev, size, new_mblk, num_slen
	REAL	rgrid_blocks
	CHARACTER  LEFINT*12, num_str*12

* Check for unspecified limits on abstract axis
	IF ( num_words .EQ. 99999999 ) GOTO 5100

* LOOK FOR A MEMORY REGION ALREADY AVAILABLE
* ... use linked list into free memory regions
	mblk = mblk_flink( 0 )

* ... nothing more to check ?
 100	IF ( mblk .EQ. 0 ) GOTO 200

* ... another region to check out - is it big enough ?
	size = mblk_size ( mblk )
	IF ( size .LT. grid_blocks ) THEN
	   mblk = mblk_flink( mblk )
	   GOTO 100
	ELSE
	   GOTO 500
	ENDIF
	   
* NOTHING BIG ENOUGH IS AVAILABLE AT PRESENT
* delete from tail of deletion priority chain looking for something big enough
 200	mr = mr_del_blink(0)
	IF ( mr .EQ. 0 ) GOTO 5200
	CALL DELETE_VARIABLE( mr )
	size = mr_del_last_size
	IF ( size .LT. grid_blocks ) THEN
	   GOTO 200
	ELSE
	   mblk = mr_del_last_mblk
	ENDIF

* WE HAVE GOT A REGION AT LEAST BIG ENOUGH
 500	prev = mblk_blink( mblk )
	next = mblk_flink( mblk )

	IF ( size .EQ. grid_blocks ) THEN
* ... perfect size - remove it from the free list
	   mblk_flink( prev ) = next
	   mblk_blink( next ) = prev

	ELSE
* ... unnecessarily big - bite off only what we need
	   new_mblk = mblk + grid_blocks
	   mblk_flink( new_mblk ) = next
	   mblk_blink( new_mblk ) = prev
	   mblk_size ( new_mblk ) = size - grid_blocks
	   mblk_flink( prev )     = new_mblk
	   mblk_blink( next )     = new_mblk
	ENDIF

* success - set up the requested region and give it to them
        num_blocks = grid_blocks
	mblk_size ( mblk ) = num_blocks
	status = ferr_ok

	mblk_flink( mblk ) = unspecified_int4	! temp diag
	mblk_blink( mblk ) = unspecified_int4	! temp diag

 5000	RETURN
 5100	num_str = LEFINT(num_words,num_slen)
	CALL ERRMSG( ferr_dim_underspec, status,
     .    num_str(:num_slen)//' words were requested. ', *5105)
 5105	CALL WARN('Check for unspecified limits on an ABSTRACT axis')
	CALL WARN('Use the SHOW GRID command to see the axes')
	RETURN
 5200	CONTINUE
        rgrid_blocks = FLOAT(mem_blk_size)* FLOAT(grid_blocks)/ 1.e6
	num_str = LEFINT(CEILING(2.*rgrid_blocks),num_slen)

	CALL ERRMSG( ferr_insuff_memory,status,
     .	  num_str(:num_slen)//' Mwords were requested. ', *5130)
 5130	CALL WARN('You can use SET MEMORY/SIZE=xxx to increase memory.')
	CALL WARN('The "Memory use" section of the FERRET '
     .              //'Users Guide has further tips.') 
        GOTO 5000
	RETURN
	END

