```
;
; Sample script for FOXSI-SMEX image deconvolution
;

; First, produce the transformation matrix that computes the flux in a detector pixel j 
; due to a source in a source pixel i.  In general, source and detector pixels can be 
; entirely different bases.
;
; The transformation matrix is produced by FOXSI_DEFINE_MATRIX, with three typical keywords:
;		MEASURED_DIM: Linear size of the detector image.  This must match the 
;					size of the image you want to deconv.  If you have a measured 
;					image in nxn pixels, then set MEASURED_DIM=N.
;
;		SOURCE_DIM: 	Set this equal to any integer multiple of MEASURED_DIM.
;
;		MATRIX_FILE:	This will save the transformation matrix in a file for use later.
;
; This routine is time-consuming (about 1 minute on Lindsay's MBP for the example below), 
; as it computes the transformation matrix in a "brute force" way.  It is recommended that 
; you save the resulting matrix to be reused.  Any measured image with the same 
; dimensions can use the same transformation matrix. 

@foxsi-smex-setup-script

; Step 1: set up the transformation matrix.
; Assume the image to deconvolve is in a plot_map called IMAGE.

restore, 'docs/sample-image.sav'
dim = (size(image[0].data))[1]
matrix_file = 'matrix.sav'
matrix = foxsi_define_matrix( source_dim=4*dim, measured_dim = dim, matrix_file=matrix_file )

; Now the transformation matrix is computed and saved.  We should not need to repeat that step.

iter = 50		; Choose how many deconvolution iterations to do.
				; The routine will return all the intermediate iterations.
deconv = foxsi_deconv( image, matrix_file=matrix_file, max=iter )

movie_map, deconv, /noscale

; No stopping rule is implemented; the routine will iterate to the user's heart's content. 
; In the example here, the coronal source structure is probably not to be trusted 
; beyond ~10 iterations, while the bright, compact footpoints, with their better 
; statistics, can be taken a bit further than that.
```