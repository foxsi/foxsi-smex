;;;;;;;;;;;
;;; note: runtime scales badly with FOV size, if source is far from edge of FOV then 
;;;a modification can be made to speed up the code, see note further down
;;;
;;;FUNCTION: "get_foxsi_image"
;;;ARGUMENT: source_array (a map, product of the make_map function)
;;;KEYWORDS: px = "pixel size" in arcseconds, default is 3
;;;
;;;;;;;

FUNCTION get_foxsi_image,source_map, px = pix_size

DEFAULT, pix_size, 3

RESOLVE_ROUTINE, 'get_psf_array', /IS_FUNCTION
x=0
y=0

;;Comment out this line and uncomment the same line inside the FOR
;;loop below to make the returned psf vary according to the position
;;in the source image being convolved (will slow down code a lot)

psf_array = get_psf_array(source_map.xc,source_map.yc,source_map.dx,source_map.dy,x,y)
;; Above line: feed into the psf generator, the observation parameters
;; of the source.

x_size = N_ELEMENTS(REFORM(source_map.data[*,0]))*1.0
y_size = N_ELEMENTS(REFORM(source_map.data[0,*]))*1.0 

convolved_array = DBLARR(x_size,y_size)

FOR i = 0.0, N_ELEMENTS(source_map.data)-1 DO BEGIN

        x = (i MOD x_size)*1.0
        y = (i - x)/x_size*1.0

	IF i/(N_ELEMENTS(source_map.data)) EQ 0.1 THEN PRINT, '10% Complete'
	IF i/(N_ELEMENTS(source_map.data)) EQ 0.2 THEN PRINT, '20% Complete'
	IF i/(N_ELEMENTS(source_map.data)) EQ 0.3 THEN PRINT, '30% Complete'
	IF i/(N_ELEMENTS(source_map.data)) EQ 0.4 THEN PRINT, '40% Complete'
	IF i/(N_ELEMENTS(source_map.data)) EQ 0.5 THEN PRINT, '50% Complete'	
	IF i/(N_ELEMENTS(source_map.data)) EQ 0.6 THEN PRINT, '60% Complete'
	IF i/(N_ELEMENTS(source_map.data)) EQ 0.7 THEN PRINT, '70% Complete'
	IF i/(N_ELEMENTS(source_map.data)) EQ 0.8 THEN PRINT, '80% Complete'
        IF i/(N_ELEMENTS(source_map.data)) EQ 0.9 THEN PRINT, '90% Complete'


    
        
; psf_array=get_psf_array(source_map.xc,source_map.yc,source_map.dx,source_map,dy,x,y)
;psf generation within the loop - also depends on FOV coordinates x and y, will slow down code a lot.





        ;; If source is far from edges and won't be spread over the edge of the FOV then comment out the following 4 lines

	convolved_pixel = DBLARR(3*x_size, 3*y_size)
	convolved_pixel[x_size:2*x_size-1, y_size:2*y_size-1] = psf_array * source_map.data[x,y]	
	shifted_convolved_pixel = SHIFT(convolved_pixel,-1*(x_size/2 - x),-1*(y_size/2 - y))
	shifted_convolved_pixel = shifted_convolved_pixel[x_size:2*x_size-1, y_size:2*y_size-1]
 
        ;; and uncomment the next to slightly speed up code:

	;convolved_pixel = psf_array * source_map.data[x,y]
	;shifted_convolved_pixel = SHIFT(convolved_pixel,-1*(x_size/2 - x),-1*(y_size/2 - y))
              
       convolved_array = convolved_array + shifted_convolved_pixel

ENDFOR

PRINT, '100% Complete'
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

rebinned_convolved_array = FREBIN(convolved_array,x_size/pix_size,y_size/pix_size, /TOTAL)

IF ABS(TOTAL(rebinned_convolved_array) - TOTAL(convolved_array)) GT 0.0001  THEN BEGIN
   rebinned_convolved_array =TOTAL(convolved_array)* (rebinned_convolved_array)/TOTAL(rebinned_convolved_array) ;;;; Renormalise counts to assume lossless between optics and detector
   print, 'Rebinning loss detected, renormalising...'
ENDIF


rebinned_convolved_map = make_map(rebinned_convolved_array, dx = source_map.dx*pix_size, dy = source_map.dy*pix_size, xc = source_map.xc, yc = source_map.yc, id = STRCOMPRESS('Rebinned_Convolved_Map_Pixel_Size:'+string(pix_size),/REMOVE_AL),time = '')

print,  'rebinned_convolved_map returned'

RETURN, rebinned_convolved_map

END
