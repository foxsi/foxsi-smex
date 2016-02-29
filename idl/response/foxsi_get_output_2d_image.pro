;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;FUNCTION:      "foxsi_get_output_2d_image"
;;;
;;;HISTORY:       Initial Commit - 08/19/15 - Samuel Badman
;;;               Improved Convolution Method - 08/31/15 - Samuel Badman               
;;;
;;;DESCRIPTION:   Function which accepts a 2D map of a source as an input, obtained through
;;;               calling source_map = get_source_map(). This map is the
;;;               convolved with a point spread function obtained through calling the
;;;               function get_psf_array with arguments specifying the
;;;               solar coordinates of the image sensor. After
;;;               convolution, the new image is rebinned according to
;;;               the keyword px = pix_size (default = 3) to reflect the
;;;               loss of resolution due to the finite strip size in
;;;               the detectors. Finally, counting statistics is
;;;               accounted for via replacing each pixel's value with
;;;               one randomly drawn from a poisson distribution
;;;               with a mean given by that pixel's original value.
;;;               
;;; 
;;;
;;;CALL SEQUENCE: rebinned_convolved_map = foxsi_get_output_2d_image()
;;;
;;;
;;;KEYWORDS:      source_map = "source_map". User inputted source, if
;;;               blank, default generated from get_source_map
;;;               function
;;;
;;;               px = "pixel size of detector" in arcseconds, default is 3''
;;;               
;;;               no_count_stats - if keyword set no counting stats
;;;                                accounted for
;;;               oversample_psf - degree of oversampling to produce a more
;;;                                accurate PSF. Default is 1 (no oversampling)
;;;								quiet - Don't print out progress.
;;;
;;;COMMENTS:      -Runtime scales badly with FOV size
;;;               -The default source array is 
;;;               set to [150,150] ~2.5' X 2.5' FOV at 1 arcsec per
;;;               pixel, this takes a few seconds to run.
;;;               -Convolution method improved - slight speed
;;;                upgrade,shorter and more accurate. Removes hard
;;;                edges and asymmetry which were previously
;;;                detectable at low resolutions.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FUNCTION foxsi_get_output_2d_image,source_map = source_map, px = pix_size, no_count_stats = no_count_stats,$
  oversample_psf=oversample_psf, quiet=quiet

IF N_ELEMENTS(SOURCE_MAP) EQ 0 THEN PRINT, 'No user input detected, using default source image'

;;;;; Check for updates to peripheral functions for the purposes of testing
RESOLVE_ROUTINE, 'foxsi_get_psf_map', /IS_FUNCTION
RESOLVE_ROUTINE, 'foxsi_get_default_source_map', /IS_FUNCTION

;;;; Define default source_map input in case of no user input
DEFAULT, source_map, foxsi_get_default_source_map()

;;;;; Define default detector resolution to 3 arcsecs per pixel
DEFAULT, pix_size, 3.0

x=0.0 ;; Redundant FOV coordinates required as arguments for get_psf_array
y=0.0 ;; Will come into play when FOV coordinate dependence is introduced into psf

dims   = SIZE(source_map.data, /DIM)
x_size = dims[0]  ;;; Get dimensions of FOV in pixels
y_size = dims[1]

if not keyword_set( quiet ) then print, strcompress('Source_Array_is_'+string(x_size) $
       +'x'+string(y_size)+'_Pixels', /REMOVE_AL)

;;; Obtain psf assuming constant across FOV
;;; The requested size of the PSF is double the source map for later convenience

psf_map = foxsi_get_psf_map(source_map.xc,source_map.yc,source_map.dx      $
,source_map.dy,x,y,x_size=2*x_size-1,y_size=2*y_size-1, oversample=oversample_psf)

; psf_array has dimensions (2*x_size-1) by (2*y_size-1)
psf_array = psf_map.data


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; 08/31 -Improved convolution method takes only the pixels in the psf which
;;; overlap with the convolved image for a given FOV pixel. 
;;; Eliminates need to shift whole array and therefore the problem
;;; with wrapping.


convolved_array = DBLARR(x_size,y_size)

FOR y = 0, y_size-1 DO BEGIN
   FOR x = 0, x_size-1 DO BEGIN
     
      
      convolved_pixel         = psf_array * source_map.data[x,y]
     

      shifted_convolved_pixel = convolved_pixel[x_size-1-x:2*x_size-2-x,$
                                y_size-1-y:2*y_size-2-y]

      convolved_array        = convolved_array + shifted_convolved_pixel

       
      ;;; Progress monitor - run time is still long for large (>150'x150') FOV sizes 
      IF x eq 0 and not keyword_set( QUIET ) THEN $
      											 print, STRCOMPRESS("Image_Row_"+string(FIX(y+1))+"_of_"    $
                             +string(FIX(y_size))+"_completed", /REMOVE_AL)

   ENDFOR
ENDFOR


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;; Do rebinning due to detector pixelation;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

rebinned_convolved_array = FREBIN(convolved_array,x_size*source_map.dx                      $
                           /pix_size,y_size*source_map.dy/pix_size, /TOTAL)


;; Detect if FREBIN causes unacceptable loss of counts (e.g for non
;; integer pixelation ratio. If detected, total counts are
;; renormalised to correct (ideal) value.

IF ABS(TOTAL(rebinned_convolved_array) - TOTAL(convolved_array)) GT 0.0001  THEN BEGIN
   
   rebinned_convolved_array =TOTAL(convolved_array)* (rebinned_convolved_array)             $
   /TOTAL(rebinned_convolved_array) 
   
   print, 'Rebinning loss detected, renormalising...'

ENDIF


;;; Makes and outputs map of convolved and rebinned array with pixel size 
;;; equal to the value of the px keyword (default = 3'' per pixel)
;;; The centre of the map is preserved as the centre of the source image

; Simple map ID:
rebinned_convolved_map = make_map(rebinned_convolved_array, dx = pix_size, dy = pix_size,   $
                         xc = source_map.xc, yc = source_map.yc, id = 'FOXSI counts')

output_dims = SIZE(rebinned_convolved_map.data,/DIM)

;;;; Add noise due to counting statistics for each pixel ;;;;;
IF KEYWORD_SET(no_count_stats) NE 1 THEN BEGIN
  FOR x = 0, output_dims[0] - 1 DO BEGIN
     FOR y = 0, output_dims[1] - 1 DO BEGIN
          mean = rebinned_convolved_map.data[x,y]
          IF mean NE 0.0 THEN BEGIN 
                  noisy_value = RANDOMU(seed, 1, POISSON = mean)
                  rebinned_convolved_map.data[x,y] = noisy_value
               ENDIF         
      
     ENDFOR
  ENDFOR
ENDIF

print,  'rebinned_convolved_map returned'

RETURN, rebinned_convolved_map

END
