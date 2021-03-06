	SUBROUTINE FREE_MEMORY ( mblk, num_blocks )

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
* return a contiguous region of bulk memory to the free list merging it with
* the surrounding free regions if they are contiguous
* ( return the merged size via COMMON in mr_del_last_size )
* see documentation in XVARIABLES.CMN

* programmer - steve hankin
* NOAA/PMEL, Seattle, WA - Tropical Modeling and Analysis Program
* written for VAX computer under VMS operating system
*
* revision 0.0 - 4/1/86
* revision 1.0 - 7/21/88 - complete re-write using linked list
* V200:  6/12/89 - use doubly linked list; return mr_del_last_*
*	 8/1/89  - corrected bug: mr_del_last* not set for not contig at all
* V312: 5/94 - array "memory" as a calling argument
*        2/12 *kms* Add E and F dimensions (use nferdims in tmap_dims.parm)

        IMPLICIT NONE
        include 'tmap_dims.parm'
	include 'ferret.parm'
	include 'xvariables.cmn'
	include 'xprog_state.cmn'

* calling argument declarations:
	INTEGER	mblk, num_blocks, mem_blk, i

* internal variable declarations:
	INTEGER	prev, next, nex2
	LOGICAL	contig_above, contig_below

! temp diag
	IF ( num_blocks .NE. mblk_size( mblk ) ) STOP ' FREE_MEMORY'

!* as a diagnostic test - fill unused memory with a flag
! removed 5/18/94 as "memory" is no longer in COMMON 
!	IF ( mode_diagnostic ) THEN
!	   DO 50 mem_blk = mblk, mblk+num_blocks-1
!	   DO 50 i = 1, mem_blk_size
! 50	   memory( i,mem_blk ) = bad_val4
!	ENDIF

* find the position of "mblk" in the ordered free memory list
	prev = 0
	next = mblk_flink( prev )
 100	IF ( next .EQ. 0 ) THEN
* ... end of list - this mblk value must be greater than anything in the list
	   GOTO 200
	ELSEIF ( next .LT. mblk ) THEN
* ... keep looking further in the list
	   prev = next
	   next = mblk_flink( next )
	   GOTO 100
	ENDIF
* ... found it - prev<mblk and next>mblk
	nex2 = mblk_flink( next )

* will the new region merge contiguously above or below ?
 200	contig_above = mblk + num_blocks .EQ. next
	contig_below = prev + mblk_size(prev) .EQ. mblk
     .		 .AND. prev .NE. 0

* insert the freed bulk memory region into the free list
	IF ( contig_above .AND. contig_below ) THEN
	   mr_del_last_mblk   = prev
	   mr_del_last_size   = mblk_size( prev )
     .			      + num_blocks
     .			      + mblk_size( next )
	   mblk_size ( prev ) = mr_del_last_size
	   mblk_flink( prev ) = nex2
	   mblk_blink( nex2 ) = prev
	   mblk_flink( mblk ) = unspecified_int4	! temp diag
	   mblk_blink( mblk ) = unspecified_int4	! temp diag
	   mblk_size ( mblk ) = unspecified_int4	! temp diag
	   mblk_flink( next ) = unspecified_int4	! temp diag
	   mblk_blink( next ) = unspecified_int4	! temp diag
	   mblk_size ( next ) = unspecified_int4	! temp diag

	ELSEIF ( contig_above ) THEN
	   mr_del_last_mblk   = mblk
	   mr_del_last_size   = num_blocks + mblk_size( next )
	   mblk_size ( mblk ) = mr_del_last_size
	   mblk_flink( mblk ) = nex2
	   mblk_blink( mblk ) = prev
	   mblk_blink( nex2 ) = mblk
	   mblk_flink( prev ) = mblk
	   mblk_flink( next ) = unspecified_int4	! temp diag
	   mblk_blink( next ) = unspecified_int4	! temp diag
	   mblk_size ( next ) = unspecified_int4	! temp diag

	ELSEIF ( contig_below ) THEN
	   mr_del_last_mblk   = prev
	   mr_del_last_size   = mblk_size( prev ) + num_blocks
	   mblk_size ( prev ) = mr_del_last_size
	   mblk_flink( mblk ) = unspecified_int4	! temp diag
	   mblk_blink( mblk ) = unspecified_int4	! temp diag
	   mblk_size ( mblk ) = unspecified_int4	! temp diag

	ELSE
	   mr_del_last_mblk   = mblk
	   mr_del_last_size   = num_blocks
	   mblk_flink( mblk ) = next
	   mblk_blink( mblk ) = prev
	   mblk_flink( prev ) = mblk
	   mblk_blink( next ) = mblk

	ENDIF
	RETURN
	END
