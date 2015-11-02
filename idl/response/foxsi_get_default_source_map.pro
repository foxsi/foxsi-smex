;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;FUNCTION:      "foxsi_get_default_source_map"         
;;;
;;;HISTORY:       Initial Commit - 08/19/15 - Samuel Badman
;;;                                                                                            
;;;DESCRIPTION:   Funtion which returns a toy example of a
;;;               monochromatic source map which can be fed
;;;               into the foxsi_get_2d_image.pro to see 
;;;               what it looks like on the detector.            
;;;                                                                                            
;;;CALL SEQUENCE: source_map = foxsi_get_default_source_map()      
;;;                                                                                            
;;;KEYWORDS:      dx, dy - binsize of pixels in arcseconds 
;;;               xc, yc - centre of image in solar coordinates (arcseconds)
;;;                                                                                            
;;;                                                                                            
;;;COMMENTS:      Currently returns an array with 2 Gaussian sources, each of FWHM 1/20 * FOV
;;;               size and each with a peak count rate of 100. Source 1 is centred about
;;;               [0.375,0.625], Source 2 is centred about [0.5,0.5] expressed as a
;;;               fraction of the FOV dimensions.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FUNCTION foxsi_get_default_source_map, dx = dx, dy = dy, xc = xc, yc = yc


;;;;Define keyword defaults to 1 arcsecond per pixel and centre the image at the solar origin
DEFAULT, dx, 1
DEFAULT, dy, 1
DEFAULT, xc, 0
DEFAULT, yc, 0

source_array = DBLARR(500,500)

;;;; Warning: changing the above dimensions of source_array will significantly affect the code
;;;; runtime. 

x_size = N_ELEMENTS(REFORM(source_array[*,0]))*1.0
y_size = N_ELEMENTS(REFORM(source_array[0,*]))*1.0

;;;;;;;;;;;;;;;;;;;;;;; Get Source Array  ;;;;;;;;;;;;;;;;;;;;;

;;; Define parameters of toy gaussian sources

FWHM_xs = x_size/20                      
FWHM_ys = y_size/20
sigma_xs = FWHM_xs/(sqrt(2.0*ALOG(2)))   ;;Standard deviations are calculated from FWHM
sigma_ys = FWHM_ys/(sqrt(2.0*ALOG(2)))

source1 = 1000.0 ; Peak Counts
source2 = 1000.0

source_centre1 = [1.5*x_size/4,2.5*(y_size/4) ] ; Source centre coordinates
source_centre2 = [(x_size+1.0)/2.0,(y_size+1.0)/2.0]

;;; Create Sources from the above parameters

source_1  = source1*PSF_GAUSSIAN(npix = [x_size, y_size], $ 
            /double, st_dev = [sigma_xs,sigma_ys],        $
            centroid = source_centre1 )


source_2  = source2*PSF_GAUSSIAN(npix = [x_size, y_size], $
            /double, st_dev = [sigma_xs,sigma_ys],        $
            centroid = source_centre2)

;;; Add individual sources to get complete source array

source_array = source_1 + source_2

;;; Make map from the source array and user inputted keywords or their defaults and RETURN

source_map = make_map(source_array, dx=dx, dy=dy, xc = xc, yc = yc, id = "Source Map")

RETURN, source_map

END

