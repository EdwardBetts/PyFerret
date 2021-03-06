	SUBROUTINE GET_WORK_SPC ( size, start_block, status )

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
* provide a region of temporary working space to the calling routine.
* For greatest speed simply reuse the last provided if it is large enough

* programmer - steve hankin
* NOAA/PMEL, Seattle, WA - Tropical Modeling and Analysis Program
* written for VAX computer under VMS operating system
*
* revision 0.0 - 2/19/87
* V510: *sh 1/2000 - bug fix when unable to allocate requested work space
*        2/12 *kms* Add E and F dimensions (use nferdims in tmap_dims.parm)
* V69+ *acm*  9/14 Ticket 1758. Memory request uses number of blocks not words

        IMPLICIT NONE
        include 'tmap_dims.parm'
	include 'ferret.parm'
	include 'errmsg.parm'
	include 'xvariables.cmn'
	include 'xwork_space.cmn'

* calling argument declarations:
	INTEGER	size, start_block, status

* internal variable declarations:
	INTEGER grid_blocks

* --- end of introductory code ---

	IF ( size .LE. sp_last_size ) THEN
	   status = ferr_ok

	ELSE
	   CALL RELEASE_WORK_SPC
* COMPUTE # BLOCKS NEEDED
	   grid_blocks = ( size + mem_blk_size - 1 ) / mem_blk_size
	   CALL GET_MEMORY( size, grid_blocks, sp_start_block, sp_num_blocks, status )
	   IF ( status .EQ. ferr_ok ) THEN
	      sp_last_size = sp_num_blocks * mem_blk_size
	   ELSE
	      sp_last_size = 0
	   ENDIF
	ENDIF

	start_block = sp_start_block
	RETURN
	END

