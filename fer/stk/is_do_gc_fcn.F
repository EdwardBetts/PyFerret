	SUBROUTINE IS_DO_GC_FCN
     .			( memory, uvar, alg_text, lo_isp, status )

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
* do bookkeeping and call up calculation to perform grid changing fcn
* (which may be an externally-defined function)

* V450:  1/97 - based on IS_DO_OP
*        7/97 - added status and memory args to DO_INTERNAL_GC_FCN call
*       7/25/97 - increase number of args allowed from 5 to 10
* V500:  1/99 *sh* Trap as errors attempts to use string variables as
*		arguments ti internal functions.
*		Strings may be passed only to external functions
* V530:  8/00 *sh* - check on string data type -- not category
* V533:  6/01 *sh* - support for args that may be string or float
* V540: *sh* 10/01 - use improved data typing general parameter parg_type_* defs
* 1/03 *kob* g77 port requires risc buff for arbitrary string concats
*  V6.0 *acm*  5/06 string results for external functions, set return type.
* V6.2 *acm* 11/08 New function efcn_get_alt_type_fcn gets the name of a 
*                  function to call if the arguments are of a different type 
*                  than defined in the current function. e.g. this lets the 
*                  user reference XCAT with string arguments and Ferret will 
*                  run XCAT_STR
* V68  *acm* 1/12  ifdef double_p for double-precision ferret.
*      *acm* 3/12 6D Ferret (common uses nferdims in tmap_dims.parm)
* V68   3/12 *KMS/ACM* see 6D branch: working on string bugs. Remove overloading
*                   of argument/return-type variable and predimensional (data size)
*                   array parameter (pointer size to one in double-precision Ferret).
* V694  *acm* 1214 Fixing ticket 2220: varname.attname in a function argument
* V710 *acm* 10/16 Ticket 2422: variables uvar_grid, uvar_data_type, uvar_aux_cat, 
*                  uvar_aux_var to be replaced with calls to LIST routines in NCF_Util.c

        IMPLICIT NONE
	include 'tmap_dims.parm'
	include	'ferret.parm'
	include	'errmsg.parm'
        include 'grid_chg_fcns.parm'
	include	'rpn.parm'
	include	'xvariables.cmn'
	include	'xcontext.cmn'
	include	'xalgebra.cmn'
	include	'xtext_info.cmn'
	include	'xfr_grid.cmn'	! w/ mgrid_abstract
	include 'xgrid_chg_fcns.cmn'
	include 'xrisc_buff.cmn' 

* calling arguments
	INTEGER		uvar, lo_isp, status
	REAL		memory( mem_blk_size, max_mem_blks )
	CHARACTER*(*)	alg_text

* local variables
	LOGICAL	ITS_UN_CACHED, not_reusable, check_alt_fcn
	INTEGER	GCF_FIND_FCN, GCF_NUM_ARGS, GCF_ARG_TYPE,
     .		MGRID_SIZE_DELTA, GCF_ARG_EVAL_ORDER, EFCN_GET_RTN_TYPE,
     .		ifcn, icom, iarg, num_com, mr, res_cx,
     .		mr1, mr2, mr3, mr4, mr5, mr6, mr7, mr8, mr9, impl_grid,
     .          typ1, typ2, typ3, typ4, typ5, typ6, typ7, typ8, typ9,
     .          typr, pdim1, pdim2, pdim3, pdim4, pdim5, pdim6, pdim7,
     .          pdim8, pdim9, pdimr, frame_bottom, com_cx, res_mr,
     .          itype, arg_first_mismatch, slen, iset, igrid,
     .          aux_cat(nferdims), aux_var(nferdims)
        CHARACTER*40 TM_FMT, alt_name

* convenience equivalences
	INTEGER	com(10), typ(9), pdim(9)
	EQUIVALENCE (com(1),mr1), (com(2),mr2), (com(3),mr3), (com(4),mr4),
     .              (com(5),mr5),
     .		    (com(6),mr6), (com(7),mr7), (com(8),mr8), (com(9),mr9),
     .              (com(10),res_mr)
	EQUIVALENCE (typ(1),typ1), (typ(2),typ2), (typ(3),typ3),
     .		    (typ(4),typ4), (typ(5),typ5), (typ(6),typ6),
     .		    (typ(7),typ7), (typ(8),typ8), (typ(9),typ9)
        EQUIVALENCE (pdim(1),pdim1), (pdim(2),pdim2), (pdim(3),pdim3),
     .              (pdim(4),pdim4), (pdim(5),pdim5), (pdim(6),pdim6),
     .              (pdim(7),pdim7), (pdim(8),pdim8), (pdim(9),pdim9)

* local parameter declarations
* ... pfloat_words indicates that each float value in an array is 1 word
* ... ptpr_words   indicates that each pointer     in an array is 2 word
* These are assigned to pdim values
	INTEGER	    pfloat_words, pptr_words
#ifdef double_p
	PARAMETER  (pfloat_words = 1,
     .		    pptr_words   = 1 )
#else
	PARAMETER  (pfloat_words = 1,
     .		    pptr_words   = 2 )
#endif

*        ... interpretation stack setup at the time this is called ...
*	stack level		stack contents
*	 isp	<--	most recently obtained component for calculation
*	isp-1		...
*	isp-2	<--	...	other components of this expression on stack
*	isp-n		...
*	lo_isp	<--	level at which expression evaluation was called

* the "frame_bottom" is the isp level that will be left when the components of
* the current calculation (1 to 3) are reduced to a single value.
* on exit isp will point to the frame bottom and the result will be left there

* initialize all data types to default of FLOAT
        DO icom = 1, 9
          typ(icom) = parg_type_float
          pdim(icom) = pfloat_words
        ENDDO

* identify the text of the particular function
*	(internal or external GC fcn handled the same)
	ifcn = GCF_FIND_FCN( alg_text )
	IF ( ifcn .EQ. unspecified_int4 ) STOP ' bad GC fcn err'
	num_com = GCF_NUM_ARGS( ifcn )

* sanity check on stack contents
	frame_bottom = isp - num_com + 1
	IF ( frame_bottom .LE. lo_isp ) CALL ERRMSG
     .		( ferr_syntax, status, 'RPN', *5000 )

* trap attempts to pass arguments of the wrong type (1/99)

        arg_first_mismatch = 0
        check_alt_fcn = .FALSE.
	DO 100 icom = 1, num_com
	   iarg = GCF_ARG_EVAL_ORDER(ifcn, icom)
	   itype = GCF_ARG_TYPE(ifcn, iarg)
	   com_cx  = is_cx(frame_bottom+icom-1)
           IF ( cx_type(com_cx) .EQ. ptype_string ) THEN
              typ(icom) = parg_type_string
              pdim(icom) = pptr_words
           ENDIF
	   IF ( (cx_type(com_cx) .EQ. ptype_string)
     .	        .NEQV. (itype .EQ. parg_type_string) ) THEN
	      IF (itype .NE. parg_type_float_or_string)  
     .           check_alt_fcn = .TRUE.
	   ENDIF
	   IF (check_alt_fcn .AND. arg_first_mismatch.EQ.0)
     .        arg_first_mismatch = iarg
 100	CONTINUE

* Does the function designate an alternate function for strings?
* If so, check the argument types for it.

        IF (check_alt_fcn) THEN
*          alt_name is blank-terminated (not null-terminated)
*          and is unchanged if alt_type_fcn does not exist
           alt_name = ' '
	   CALL efcn_get_alt_type_fcn( ifcn, alt_name )  
	   ifcn = GCF_FIND_FCN( alt_name )
	   IF (ifcn .EQ. unspecified_int4) GOTO 5200

* re-initialize all data types to default of FLOAT
           DO icom = 1, 9
             typ(icom) = parg_type_float
             pdim(icom) = pfloat_words
           ENDDO
      	   DO 101 icom = 1, num_com
	      iarg = GCF_ARG_EVAL_ORDER(ifcn, icom)
	      itype = GCF_ARG_TYPE(ifcn, iarg)
	      com_cx  = is_cx(frame_bottom+icom-1)
              IF (cx_type(com_cx) .EQ. ptype_string) THEN
                 typ(icom) = parg_type_string
                 pdim(icom) = pptr_words
              ENDIF
	      IF ( (cx_type(com_cx) .EQ. ptype_string)
     .	           .NEQV. (itype .EQ. parg_type_string) ) THEN
	         IF (itype .NE. parg_type_float_or_string) 
     .              GOTO 5200
	      ENDIF
 101	   CONTINUE
        ENDIF

!* the merged context is already nearly complete
	res_cx = is_big_cx(lo_isp)

* determine data type of result - and set pdimr and typr
        IF ( ifcn .LE. GFCN_NUM_INTERNAL ) THEN
*          only truly-internal grid-changing functions get here
*          Ferret already knows the return type since it may depend on argument type
*          (under the get_uvar_grid - is_uvar_grid - merge_grid calling stack)

           iset = cx_data_set(res_cx)
           IF (iset .EQ. unspecified_int4) iset = pdset_irrelevant
	   
	   itype = ptype_unknown
	   CALL GET_SAVED_UVAR_DTYPE(uvar, iset, itype) 

           cx_type(res_cx) = itype
           IF ( cx_type(res_cx) .EQ. ptype_string ) THEN
              typr = pfcn_rtn_string
              pdimr = pptr_words
           ELSE IF ( cx_type(res_cx) .EQ. ptype_float ) THEN
              typr = pfcn_rtn_float
              pdimr = pfloat_words
           ELSE
              STOP 'IS_DO_GC_FCN cs_type(res_cx) is neither ptype_string nor ptype_float'
           ENDIF
        ELSE
*          get the return type from the external function information
*          this includes "external" functions internalized (statically linked in)
           typr = EFCN_GET_RTN_TYPE (ifcn)
           IF ( typr .EQ. pfcn_rtn_string ) THEN
              cx_type(res_cx) = ptype_string
              pdimr = pptr_words
           ELSE IF ( typr .EQ. pfcn_rtn_float ) THEN
              cx_type(res_cx) = ptype_float
              pdimr = pfloat_words
           ELSE
              STOP 'IS_DO_GC_FCN typr is neither pfcn_rtn_string nor pfcn_rtn_float'
           ENDIF

           iset = cx_data_set(res_cx)
           IF (iset .EQ. unspecified_int4) iset = pdset_irrelevant

* Get the stored grid, then save the newly found type with it. The call to
* SAVE_UVAR_GRID wipes out the grid information so also get and re-save the 
* Auxiliary regridding info.
	   
	   CALL GET_SAVED_UVAR_DTYPE(uvar, iset, itype)
	   IF (itype .NE. cx_type(res_cx)) THEN
	      CALL GET_SAVED_UVAR_GRID(uvar, iset, igrid)
	      CALL GET_SAVED_UVAR_AUX_INFO(uvar, iset, aux_cat, aux_var, status)

	      CALL SAVE_UVAR_GRID( uvar, igrid, cx_type(res_cx), iset )
	      CALL SAVE_UVAR_AUX_INFO(uvar, aux_cat, aux_var, iset)
	   ENDIF

        ENDIF

* need to fill in those axes that the function "imposes"
	CALL GCF_IMPOSE_RESULT_LIMS( ifcn, memory, is_mr(lo_isp+1),
     .			 is_cx(lo_isp+1), res_cx, status )
	IF ( status .NE. ferr_ok ) GOTO 5000
        

* allocate memory space for result
	CALL CREATE_MEM_VAR( res_cx, res_mr, status )
	IF ( status .NE. ferr_ok ) GOTO 5000
	mr_category( res_mr ) = cat_temp_var
	mr_variable( res_mr ) = res_mr	! cat_temp_var vars point to themselves
	IF (cx_type(res_cx) .EQ. ptype_string) THEN
	   CALL INIT_C_STRING_ARRAY( MGRID_SIZE_DELTA(res_mr),
     .                               memory(1, mr_blk1(res_mr)),
     .                               mr_c_pointer(res_mr)      )
	ENDIF

* point to the memory resident components
* (if fewer than 9 components default extras to dummy)
	DO 300 icom = 1, num_com
 300	com(icom) = is_mr(frame_bottom+icom-1)
	DO 310 icom = num_com+1, 9
 310	com(icom) = dummy_mr

* set up 6D array limits as unsubscripted variables in COMMON
	CALL NON_ARRAY_SUBSC( com, 10 )

* perform the operation

	IF (IFCN .LE. GFCN_NUM_INTERNAL) THEN

	  CALL DO_INTERNAL_GC_FCN( memory,
     .		ifcn, num_com, is_cx(frame_bottom),
     .		memory(1, mr_blk1(mr1) ), mr1, pdim1, typ1,
     .		memory(1, mr_blk1(mr2) ), mr2, pdim2, typ2,
     .		memory(1, mr_blk1(mr3) ), mr3, pdim3, typ3,
     .		memory(1, mr_blk1(mr4) ), mr4, pdim4, typ4,
     .		memory(1, mr_blk1(mr5) ), mr5, pdim5, typ5,
     .		memory(1, mr_blk1(mr6) ), mr6, pdim6, typ6,
     .		memory(1, mr_blk1(mr7) ), mr7, pdim7, typ7,
     .		memory(1, mr_blk1(mr8) ), mr8, pdim8, typ8,
     .		memory(1, mr_blk1(mr9) ), mr9, pdim9, typ9,
     .		memory(1, mr_blk1(res_mr)), res_mr, pdimr, typr,
     .		res_cx, status )
	  IF ( status .NE. ferr_ok ) GOTO 5100

	ELSE 

	  CALL DO_EXTERNAL_GC_FCN( memory,
     .			ifcn, num_com, com, is_cx(frame_bottom),
     .			memory(1, mr_blk1(mr1) ), mr1,
     .			memory(1, mr_blk1(mr2) ), mr2,
     .			memory(1, mr_blk1(mr3) ), mr3,
     .			memory(1, mr_blk1(mr4) ), mr4,
     .			memory(1, mr_blk1(mr5) ), mr5,
     .			memory(1, mr_blk1(mr6) ), mr6,
     .			memory(1, mr_blk1(mr7) ), mr7,
     .			memory(1, mr_blk1(mr8) ), mr8,
     .			memory(1, mr_blk1(mr9) ), mr9,
     .			memory(1, mr_blk1(res_mr)), res_mr,
     .			status )


	ENDIF

* clean up 
 
* ... if any components were un_cached we must uncache the result
	not_reusable = .FALSE.
	DO 2050 icom = isp, frame_bottom, -1
 2050	IF ( ITS_UN_CACHED(is_mr(icom)) ) not_reusable = .TRUE.
	IF ( not_reusable ) CALL UN_CACHE( res_mr )

* ...release component cx stack space
	DO 2100 isp = isp, frame_bottom, -1
	   IF ( is_cx(isp) .NE. cx_stack_ptr ) WRITE (6,*) 'OP_STK??'	! temp
	   cx_stack_ptr = cx_stack_ptr - 1
	   mr  = is_mr( isp )
	   IF ( mr_protected(mr) .EQ. mr_temporary
     .	   .OR. mr_category (mr) .EQ. cat_temp_var ) THEN
	      CALL DELETE_VARIABLE( mr )
	   ELSE
	      CALL MR_NOT_IN_USE( mr )
	   ENDIF
* (9/95) deallocate dynamic grids from components
	   com_cx = is_cx(isp)
	   IF ( cx_has_impl_grid(com_cx) ) THEN
	      impl_grid = cx_grid(com_cx)
	      CALL DEALLO_DYN_GRID(impl_grid)
	      cx_has_impl_grid(com_cx) = .FALSE.
	   ENDIF
 2100	CONTINUE

* collapse the interp stack frame
	isp = frame_bottom
	is_mr( isp ) = res_mr

* save the result context at the cx level previously used by the 1st component
	cx_stack_ptr = cx_stack_ptr + 1
	CALL TRANSFER_CONTEXT( res_cx, cx_stack_ptr )
	is_cx( isp ) = cx_stack_ptr

	RETURN

* error exit
 5000	RETURN
 5100	CALL DELETE_VARIABLE(res_mr)
	GOTO 5000
* 1/03 *kob* g77 port requires risc buff for arbitrary string concats
 5200	CONTINUE
* Could not match argument types
        risc_buff = alg_text
	alt_name = TM_FMT(FLOAT(arg_first_mismatch), 2, 40, slen)
	CALL ERRMSG( ferr_invalid_command, status,
     .		'string/numeric data type mix-up. Argument '//
     .		alt_name(:slen)//' : '//risc_buff, *5000 )
	END

