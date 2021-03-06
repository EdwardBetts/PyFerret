	SUBROUTINE DELETE_VARIABLE ( mr )

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
* delete a memory resident variable releaseing its space in the memory
* variable table and bulk memory

* programmer - steve hankin
* NOAA/PMEL, Seattle, WA - Tropical Modeling and Analysis Program
*
* revision 0.0 - 4/1/86
* revision 0.1 - 1/29/87 - change to leave illegal limits in mr if deleted
*			   in diagnostic mode and to accomodate mr_protected
*			   as declared INTEGER instead of LOGICAL
*		     and   to eliminate references to tvar_grid
* revision 0.2 - 9/30/87 - added mr_perm_prot
* revision 0.3 - 3/10/88 - added cat_named_var
* revision 1.0 - 7/21/88 - deletion involves removing the variable from its
*			   hash pile in the memory variable table and returning
*			   it to the free list
* revision 1.1 -10/12/88 - for named variables possibly call DELETE_NVAR
* V200:  5/25/89 - reordered lo/hi_ss arguments
* 		 - deleted variables flagged in mr_protected and mr_del_ links
*		 - nvar variables eliminated
*		 - temporary variables represented via mr_protected
* V320: 12/29/94 - use SPLIT_LIST to redirect tty output for GUI
* V510: 2/00 *sh* - free up the mr_grid pointer when variable is deleted
* V530: 8/00 *sh* - if the variable was a string array then free the C memory
* V533: 6/01 *sh* - allow for string variables with strides
* V601 11/06 *acm*- fix bug 1466: memory for string vars is NOT allocated via malloc,
*                   so do not FREE it here. 
*        2/12 *kms* Add E and F dimensions (use nferdims in tmap_dims.parm)
* V702 1/16 *sh*: added sanity checking of memory when debugging

        IMPLICIT NONE
        include 'tmap_dims.parm'
	include 'ferret.parm'
	include 'xvariables.cmn'
	include 'xprog_state.cmn'

* calling argument declarations:
	INTEGER mr

* internal variable declarations:
	INTEGER MGRID_SIZE_DELTA, size, idim, prev, next

	IF (mode_diagnostic) THEN
	   IF ( mr_protected(mr) .NE. mr_table_entry_only )
     .			CALL DIAGNOSTIC_OUT( '-DELETE', mr, point_to_mr )

	   IF     ( mr_protected( mr ) .EQ. mr_not_protected	) THEN
	      CONTINUE
	   ELSEIF ( mr_protected( mr ) .EQ. mr_temporary	) THEN
	      CONTINUE
	   ELSEIF ( mr_protected( mr ) .EQ. mr_table_entry_only	) THEN
	      CONTINUE
	   ELSEIF ( mr_protected( mr ) .EQ. mr_perm_protected	) THEN
	      CALL SPLIT_LIST(pttmode_ops, ttout_lun,'PERMANENT', 9)
	   ELSEIF ( mr_protected( mr ) .EQ. mr_in_progress	) THEN
	      CONTINUE
	   ELSE
	      CALL WARN( 'CORRUPTION! mr_protected ????' )
	   ENDIF
	ENDIF

* if this is a string array variable then free the "C" memory allocated
* if mr_table_entry_only, no memory was given to the variable
	IF ( mr_type(mr)      .EQ. ptype_string  .AND.
     .       mr_protected(mr) .NE. mr_table_entry_only ) THEN
	   size = MGRID_SIZE_DELTA(mr)
	   CALL FREE_C_STRING_ARRAY(mr_c_pointer(mr), size)
	ENDIF

* diagnostic "delete" message
* remove variable slot from hash pile doubly linked list
	prev = mv_blink( mr )
	next = mv_flink( mr )
	mv_flink( prev ) = next
	mv_blink( next ) = prev

* return the slot to the memory variable free list
	mv_flink( mr ) = mv_flink( 0 )	
	mv_blink( mr ) = unspecified_int4		! temp diag
	mv_flink( 0 ) = mr

* remove the variable from the deletion chain if it is there
	IF ( mr_protected(mr) .EQ. mr_not_protected ) THEN
	   prev = mr_del_blink(mr)
	   next = mr_del_flink(mr)
	   mr_del_flink(prev) = next
	   mr_del_blink(next) = prev
	   mr_del_flink(mr)   = unspecified_int4	! important 12/16
	   mr_del_blink(mr)   = unspecified_int4	! important 12/16
	ENDIF

* release bulk memory that the variable used
	IF ( mr_protected( mr ) .NE. mr_table_entry_only ) 
     . 		CALL FREE_MEMORY( mr_blk1(mr), mr_nblks(mr) )


* eliminate any stray indications that this variable points to a grid
	mr_grid( mr ) = unspecified_int4

* set protection to indicate deleted
	mr_protected( mr ) = mr_deleted

* sanity check memory integrity after deletion
! note that this call can give false indications of corruption.
! When DELETE_VARIABLE is called due to the mr table being full during
! CREATE_MEM_VAR.  In that case GET_MEMORY reserves the memory, and then
! ASSIGN_VARIABLE (which calls FIND_MR_SLOT) deletes a variable to free up
! a slot while the newly reserved memory has not yyet been assigned to an mr.
!#ifndef NDEBUG
!        IF ( mode_diagnostic ) CALL SANITY_CHECK_MEMORY("DELETE_VARIABLE")
!#endif


	RETURN
	END
