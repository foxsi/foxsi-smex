;+
; NAME: FOXSI_DECONV
;
; PURPOSE:
;  	Perform maximum likelihood deconvolution on a simulated FOXSI image, using a Lucy-
;		Richardson style technique.  A transformation matrix is needed that computes the 
;		flux in detector image j due to source pixel i.  Because the transformation matrix 
;		is time-consuming to compute and can be used for deconvolution of any images that 
;		share dimensions, pixel size, and desired source resolution, that matrix is 
;		computed in a separate function and must be input to this routine using either the 
;		MATRIX_VAR or the MATRIX_FILE keyword (but not both).
;		(See FOXSI_DEFINE_MATRIX.)
;
;
; INPUT:
;		IMAGE:		The simulated FOXSI image map to deconvolve, in a plot_map structure.  
;							Must be square.
;
; KEYWORDS:
;		MATRIX_VAR:			Variable containing the transformation matrix.
;		MATRIX_FILE:		IDL save file containing the transformation matrix, named MATRIX.
;				Note that one of MATRIX_FILE or MATRIX_VAR must be set.
;		MAX_ITER:				Stop after this many iterations.  Default 40.
;
;
;	NEEDS FIXING:
;		Code is assuming 1 arcsec source resolution.  How do we specify this??
;
;
; HISTORY:
;		2015-nov-12		LG	Created.
;		2015-dec-02		LG	Putting on lipstick.
;-


FUNCTION	FOXSI_DECONV, image, matrix_var=matrix_var, $
												matrix_file=matrix_file, max_iter=max_iter, stop=stop

	default, max_iter, 40
	
	size = size( image.data )
	if size[1] ne size[2] then begin
		print, 'Simulated image must be square.'
		return, -1
	endif
	measured_dim = size[1]
	h = reform( image.data, measured_dim^2 )
	
	; Must supply a transformation matrix or a matrix file, but not both.
	if not keyword_set(matrix_var) and not keyword_set(matrix_file) then begin
		print, 'User must supply either a matrix or a matrix file.'
		return, -1
	endif
	
	if keyword_set(matrix_var) and keyword_set(matrix_file) then begin
		print, 'User must supply either a matrix or a matrix file, but not both!'
		return, -1
	endif

	if keyword_set( matrix_file ) then restore, matrix_file else matrix=matrix_var

	; Check that matrix is appropriate for the given data.
	size = size( matrix )
	if size[2] ne measured_dim^2 then begin
		print, 'Matrix does not match image dimensions.'
		return, -1
	endif
	
	source_dim = sqrt(size[1])

	;
	; Do the deconvolution
	;

	inv_matrix = transpose( matrix )			; this is S_ji (inverse matrix)

	; Grey-scale initial guess for W
	W0 = fltarr( source_dim^2 )+1./source_dim^2

	w = w0
	for i=1, max_iter do begin
		if i mod 10 eq 0 then print, 'Iter ', i, ' of', max_iter
		C = reform( w#matrix )			; reconv
		temp = reform( (h/c)#inv_matrix )
		w = w*temp
		if i eq 1 then map = make_map( reform( w, source_dim, source_dim ), dx=0.4, dy=0.4 ) $
			else map = [map, make_map( reform( w, source_dim, source_dim ), dx=0.4, dy=0.4 )]
		map[i-1].id = strtrim(i,2)+' Iterations'
	endfor
	
	if keyword_set( stop ) then stop

	return, map
	
END
