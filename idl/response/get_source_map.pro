;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;FUNCTION:      "get_source_map"         
;;;                                                                                            
;;;DESCRIPTION:   Funtion which returns a toy example of a source map which can be fed into
;;;               the get_foxsi_image programme to see what it looks like on the 
;;;               detector            
;;;                                                                                            
;;;CALL SEQUENCE: source_map = get_source_map()                                                
;;;                                                                                            
;;;KEYWORDS:      dx, dy - binsize of pixels in arcseconds 
;;;               xc, yc - centre of image in solar coordinates (arcseconds)
;;;                                                                                            
;;;                                                                                            
;;;COMMENTS:      Currently returns an array with 2 Gaussian sources, each of FWHM 1/20 * FOV
;;;               size and each with a peak count rate of 100. Source 1 is centred about
;;;               [0.375,0.625], Source 2 is centred about [0.875,0.625] expressed as a
;;;               fraction of the FOV dimensions.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FUNCTION get_source_map, dx = dx, dy = dy, xc = xc, yc = yc


;;;;Define keyword defaults to 1 arcsecond per pixel and centre the image at the solar origin
DEFAULT, dx, 1
DEFAULT, dy, 1
DEFAULT, xc, 0
DEFAULT, yc, 0

source_array = DBLARR(160,160) ;,100) < energy dimension ; line_energy = 6/20*100.0

;;;; Warning: changing the above dimensions of source_array will significantly affect the code
;;;; runtime. This must also match the dimensions of the psf array for the moment. This is an
;;;; issue to be discussed.


x_size = N_ELEMENTS(REFORM(source_array[*,0]))*1.0
y_size = N_ELEMENTS(REFORM(source_array[0,*]))*1.0

;;;;;;;;;;;;;;;;;;;;;;; Get Source Array  ;;;;;;;;;;;;;;;;;;;;;

;;; Define parameters of toy gaussian sources

FWHM_xs = x_size/20                      
FWHM_ys = y_size/20
sigma_xs = FWHM_xs/(sqrt(2.0*ALOG(2)))   ;;Standard deviations are calculated from FWHM
sigma_ys = FWHM_ys/(sqrt(2.0*ALOG(2)))

source1 = 100.0 ; Peak Counts
source2 = 100.0

source_centre1 = [1.5*x_size/4,2.5*(y_size/4) ] ; Source centre coordinates
source_centre2 = [7*x_size/8,5*(y_size/8)]

;;; Create Sources from the above parameters

;source_1  = source1*psf_gaussian(npix = [x_size, y_size], $ 
            ;/double, st_dev = [sigma_xs,sigma_ys],        $
            ;centroid = source_centre1 )
source_1 = 0

source_2  = source2*psf_gaussian(npix = [x_size, y_size], $
            /double, st_dev = [sigma_xs,sigma_ys],        $
            centroid = source_centre2)

;;; Add individual sources to get complete source array

source_array = source_1 + source_2

;;; Make map from the source array and user inputted keywords or their defaults and RETURN

source_map = make_map(source_array, dx=dx, dy=dy, xc = xc, yc = yc, id = "Source Map")

RETURN, source_map

END

