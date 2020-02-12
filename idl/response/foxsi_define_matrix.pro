;+
; NAME: FOXSI_DEFINE_MATRIX
;
; PURPOSE:
;  	Define a transformation matrix that computes the counts in each expected image pixel i 
;		due to each source pixel j.  Source and expected image pixels can be sized differently.
;
;		Notes:
;				-- The PSF must be >=2x the source image dimensions, and square.
;				-- So far, this has only been tested for cases where the dimensions of the source 
;					 array are an integer multiple of the dimensions of the expected image array.
;				-- No actual source is needed at this point.  This computes the transformation
;					 matrix that can be used for any source.  This matrix can be applied to any
;					 detector image with the specified pixel pitch and dimension.
;				-- It's not fast.  Computing the matrix with defaults takes about 5 minutes
;					 on Lindsay's laptop.
;
; OPTIONAL INPUT:
;		PSF:		plot_map structure containing the point spread function.  The deconvolved image
;						will have a pixel size equal to the PSF pixel size.  If no PSF is supplied then 
;						a default PSF with 0.8" pixels is used with dimensions based on source dims.
;
; KEYWORDS:
;		SOURCE_DIM:			Dimensions of square 2D source array.  Default is 168.  Make this an 
;										integer multiple of the dimensions of your measured image.  It doesn't
;										matter what integer multiple it is, but size requires time -- a
;										computation of the transformation matrix corresponding to a 168x168
;										source array takes about 5 minutes on a 2014 Macbook Pro.
;		MEASURED_DIM:		Dimensions of square 2D expected image array.  This must match the  
;										size of the image you want to deconvolve!
;		PITCH:					Detector pixel size.  This must match the pixel size of the image you
;										want to deconvolve!
;		MATRIX_FILE:		Save the matrix variable in an IDL save file of this name.
;
; HISTORY:
;		2015-nov-12		LG	Created.
;-


FUNCTION	FOXSI_DEFINE_MATRIX, psf, source_dim=source_dim, measured_dim=measured_dim, $
												 			 pitch=pitch, matrix_file=matrix_file, stop=stop

	default, measured_dim, long(21)			; expected image dimensions in detector pixels
	default, source_dim, long(168)			; source dimensions in source pixels
	default, pitch, 3.0									; detector pixel pitch (for expected image)

	; to match variable names in other parts of the code.
	w_dim = source_dim
	h_dim = measured_dim

	; If no PSF was input then get a default one with 0.8 arcsec pixels, on-axis.
	if n_elements(psf) lt 1 then $
		psf = foxsi_get_psf_map( 0.,0.,0.8,0.8,0.,0., x_size=2*source_dim, y_size=2*source_dim )

	; get the size of the source image pixels.
	if psf.dx ne psf.dy then begin
		print, 'PSF must have same pixel size in both dimensions.'
		return, -1
	endif	
	pix = psf.dx					; source pixel size
	
	if (size(psf.data))[1] lt 2*w_dim then begin
		print, 'PSF must be >= 2x source array size.'
		return, -1
	endif
	
	; Define the elements of the transformation matrix.

	matrix = fltarr( w_dim^2, h_dim^2 )

	print, 'Computing transformation matrix.'
	for col=0, w_dim-1 do begin
		for row=0, w_dim-1 do begin

			if row eq 0 then print, 100*float(col)/w_dim, ' percent.'

			shift_psf = shift_map( psf, col*pix, row*pix )
			sub_map, shift_psf, sub, xra=[0.,w_dim*pix], yra=[0.,w_dim*pix]
			rebin = rebin( sub.data[0:w_dim-1,0:w_dim-1], h_dim, h_dim )
			reform = reform( rebin, h_dim^2 )
			matrix[row*w_dim+col,*] = reform

		endfor
	endfor
	
	if keyword_set( matrix_file) then begin
		save, matrix, file= matrix_file
		print, 'Transformation matrix saved in ', matrix_file, '.'
	endif

	return, matrix
	
END

