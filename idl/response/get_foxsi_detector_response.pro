;;;;;;;;;;;
;;; note: runtime scales badly with FOV size, if source is far from edge of FOV then 
;;;a modification can be made to speed up the code, see note further down
;;;
;;;FUNCTION: "get_foxsi_detector_response"
;;;ARGUMENT: source_array (currently must be a 2D array)
;;;KEYWORDS: px = "pixel size" in arcseconds, default is 3
;;;
;;;

FUNCTION get_foxsi_detector_response,source_array, px = pix_size

DEFAULT, pix_size, 3

RESOLVE_ROUTINE, 'get_psf_array', /IS_FUNCTION

x_size = N_ELEMENTS(REFORM(source_array[*,0]))*1.0
y_size = N_ELEMENTS(REFORM(source_array[0,*]))*1.0 

convolved_array = DBLARR(x_size,y_size)

FOR i = 0.0, N_ELEMENTS(source_array)-1 DO BEGIN

        x = (i MOD x_size)*1.0
        y = (i - x)/x_size*1.0

	IF i/(N_ELEMENTS(source_array)) EQ 0.1 THEN PRINT, '10% Complete'
	IF i/(N_ELEMENTS(source_array)) EQ 0.2 THEN PRINT, '20% Complete'
	IF i/(N_ELEMENTS(source_array)) EQ 0.3 THEN PRINT, '30% Complete'
	IF i/(N_ELEMENTS(source_array)) EQ 0.4 THEN PRINT, '40% Complete'
	IF i/(N_ELEMENTS(source_array)) EQ 0.5 THEN PRINT, '50% Complete'	
	IF i/(N_ELEMENTS(source_array)) EQ 0.6 THEN PRINT, '60% Complete'
	IF i/(N_ELEMENTS(source_array)) EQ 0.7 THEN PRINT, '70% Complete'
	IF i/(N_ELEMENTS(source_array)) EQ 0.8 THEN PRINT, '80% Complete'
        IF i/(N_ELEMENTS(source_array)) EQ 0.9 THEN PRINT, '90% Complete'

        psf_array = get_psf_array(x,y)

        ;; If source is far from edges and won't be spread over the edge of the FOV then comment out the following 4 lines

	convolved_pixel = DBLARR(3*x_size, 3*y_size)
	convolved_pixel[x_size:2*x_size-1, y_size:2*y_size-1] = psf_array * source_array[x,y]	
	shifted_convolved_pixel = SHIFT(convolved_pixel,-1*(x_size/2 - x),-1*(y_size/2 - y))
	shifted_convolved_pixel = shifted_convolved_pixel[x_size:2*x_size-1, y_size:2*y_size-1]
 
        ;; and uncomment the next to slightly speed up code:

	;convolved_pixel = psf_array * source_array[x,y]
	;shifted_convolved_pixel = SHIFT(convolved_pixel,-1*(x_size/2 - x),-1*(y_size/2 - y))
              
       convolved_array = convolved_array + shifted_convolved_pixel

ENDFOR

PRINT, '100% Complete, rebinned_convolved_array returned'
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

rebinned_convolved_array = REBIN(convolved_array,x_size/pix_size,y_size/pix_size)

RETURN, rebinned_convolved_array

END
