;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;FUNCTION:      "get_foxsi_image"
;;;
;;;DESCRIPTION:   Function which accepts a map of a source as an input, obtained through
;;;               calling source_map = get_source_map(). This map is the
;;;               convolved with a point spread function obtained through calling the
;;;               function get_psf_array with arguments specifying the
;;;               solar coordinates of the image sensor. After
;;;               convolution, the new image is rebinned according to
;;;               the keyword px = pix_size (default = 3) to reflect the
;;;               loss of resolution due to the finite strip size in the detectors.
;;; 
;;;CALL SEQUENCE: rebinned_convolved_map = get_foxsi_image(source_map)
;;;
;;;KEYWORDS:      px = "pixel size" in arcseconds, default is 3
;;;
;;;COMMENTS:      -Runtime scales badly with FOV size, if source is far from edge of FOV then 
;;;               a modification can be made to speed up the code, see note further down.
;;;               -For the moment, psf_array and source_map.data must
;;;               have the same dimensions, at the moment these are
;;;               set to [150,150] ~2.5' X 2.5' FOV at 1 arcsec per
;;;               pixel
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FUNCTION get_foxsi_image,source_map, px = pix_size

;;;;; Define default detector resolution to 3 arcsecs per pixel
DEFAULT, pix_size, 3

;;;;; Check for updates to get_psf_array.pro for the purposes of testing
RESOLVE_ROUTINE, 'get_psf_array', /IS_FUNCTION


;;Below, we call the point spread function assuming it is constant
;;across the field of view for a given pointing and only depends on
;;the pointing itself. 
;;To change this and introduce dependence of the psf on position in
;;the FOV being convolved, comment out the line marked below and
;;uncomment the copy of it inside the FOR loop (Note this will slow down runtime a lot)

x=0 ;; Redundant FOV coordinates required as arguments for get_psf_array
y=0

;;;Comment out the line below::::
psf_array = get_psf_array(source_map.xc,source_map.yc,source_map.dx,source_map.dy,x,y) 


x_size = N_ELEMENTS(REFORM(source_map.data[*,0]))*1.0  ;;; Get dimensions of FOV in pixels
y_size = N_ELEMENTS(REFORM(source_map.data[0,*]))*1.0 

convolved_array = DBLARR(x_size,y_size)

FOR i = 0.0, N_ELEMENTS(source_map.data)-1 DO BEGIN

        x = (i MOD x_size)*1.0   ;;;Calculate FOV x,y coordinates from FOR loop variable
        y = (i - x)/x_size*1.0


        ;;;Below: Progress Monitor ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	IF i/(N_ELEMENTS(source_map.data)) EQ 0.1 THEN PRINT, '10% Complete'
	IF i/(N_ELEMENTS(source_map.data)) EQ 0.2 THEN PRINT, '20% Complete'
	IF i/(N_ELEMENTS(source_map.data)) EQ 0.3 THEN PRINT, '30% Complete'
	IF i/(N_ELEMENTS(source_map.data)) EQ 0.4 THEN PRINT, '40% Complete'
	IF i/(N_ELEMENTS(source_map.data)) EQ 0.5 THEN PRINT, '50% Complete'	
	IF i/(N_ELEMENTS(source_map.data)) EQ 0.6 THEN PRINT, '60% Complete'
	IF i/(N_ELEMENTS(source_map.data)) EQ 0.7 THEN PRINT, '70% Complete'
	IF i/(N_ELEMENTS(source_map.data)) EQ 0.8 THEN PRINT, '80% Complete'
        IF i/(N_ELEMENTS(source_map.data)) EQ 0.9 THEN PRINT, '90% Complete'
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

      ; Uncomment line below to introduce FOV coord dependence to get_psf_array      
      ; psf_array=get_psf_array(source_map.xc,source_map.yc,source_map.dx,source_map,dy,x,y)


       
        ;; Do convolution and correct for wrapping due to SHIFT
        ;; function for each pixel.
 
        ;; We do this by, for a given x,y point in the source image
        ;; creating an array with dimensions 3 x dimensions of the
        ;; psf_array with the original psf array situated at the
        ;; centre. This array is then shifted by the corresponding FOV
        ;; pixel position and only the central portion of the large
        ;; array corresponding to the dimensionsons of the original
        ;; psf is taken and added to the convolution array - any
        ;; overspills over the edge of the original psf are ignored.

        convolved_pixel = DBLARR(3*x_size, 3*y_size)
	convolved_pixel[x_size:2*x_size-1, y_size:2*y_size-1] =              $
        psf_array * source_map.data[x,y]
	shifted_convolved_pixel = SHIFT(convolved_pixel,-1*(x_size/2 - x),   $
        -1*(y_size/2 - y))
	shifted_convolved_pixel = shifted_convolved_pixel[x_size:2*x_size-1, $
        y_size:2*y_size-1]
 
        ;; If source is far from edges and won't be spread over the edge of the FOV then
        ;; comment out the preceding 4 lines to speed up code and
        ;; uncomment the next 2lines  to slightly speed up code:

	;convolved_pixel = psf_array * source_map.data[x,y]
	;shifted_convolved_pixel = SHIFT(convolved_pixel,-1*(x_size/2 - x),-1*(y_size/2 - y))
        ; if the above 2 lines are used, then a source with nonzero intensity near
        ; an edge of the FOV will be spread over the edge of the FOV and wrap
        ; around unphysically to the opposite edge of the array
       
       convolved_array = convolved_array + shifted_convolved_pixel

ENDFOR

PRINT, '100% Complete'
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;; Do rebinning due to detector pixelation;;;
rebinned_convolved_array = FREBIN(convolved_array,x_size/pix_size,y_size/pix_size, /TOTAL)


;; Detect if FREBIN causes unacceptable loss of counts (e.g for non
;; integer pixelation ratio. If detected, total counts are
;; renormalised to correct (ideal) value.

IF ABS(TOTAL(rebinned_convolved_array) - TOTAL(convolved_array)) GT 0.0001  THEN BEGIN
   rebinned_convolved_array =TOTAL(convolved_array)* (rebinned_convolved_array)/TOTAL(rebinned_convolved_array) ;;;; Renormalise counts to assume lossless between optics and detector
   print, 'Rebinning loss detected, renormalising...'
ENDIF


;;; Makes and outputs map of convolved and rebinned array with pixel size given
;;; by the pixel size of the source map multiplied by the pixelation
;;; ratio given as a keyword in this function. The centre of the map
;;; is preserved as the centre of the source image

rebinned_convolved_map = make_map(rebinned_convolved_array, dx = source_map.dx*pix_size, dy = source_map.dy*pix_size, xc = source_map.xc, yc = source_map.yc, id = STRCOMPRESS('Rebinned_Convolved_Map_Pixel_Size:'+string(pix_size),/REMOVE_AL),time = '')

print,  'rebinned_convolved_map returned'

RETURN, rebinned_convolved_map

END
