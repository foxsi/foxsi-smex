;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;FUNCTION:      "foxsi_get_source_map_spectrum"         
;;;
;;;HISTORY:       Initial Commit - 08/31/15 - Samuel Badman
;;;                                                                                            
;;;DESCRIPTION:   Funtion which returns an array of structures
;;;               consisting of 2D maps with spectral information
;;;               appended as tags. Default spectrum for the routine 
;;;               get_foxsi_spectral_image.pro          
;;;                                                                                            
;;;CALL SEQUENCE: source_map_spectrum = foxsi_get_source_map_spectrum()                      
;;;                                                                                            
;;;KEYWORDS:      dx, dy - binsize of pixels in arcseconds 
;;;               xc, yc - centre of image in solar coordinates (arcseconds)
;;;                                                                                            
;;;                                                                                            
;;;COMMENTS:      Currently returns an array of maps with 2 Gaussian sources,
;;;               each of FWHM 1/20 * FOV size and each with a peak count rate
;;;               per bin of 1000. Source 1 is centred about [0.375,0.625], 
;;;               Source 2 is centred about [0.875,0.625] expressed as a
;;;               fraction of the FOV dimensions. In the spectral
;;;               dimension, source 1 is constant in energy and source
;;;               2 is attenuated  with a half width of ~20kev
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FUNCTION foxsi_get_source_map_spectrum, dx = dx, dy = dy, xc = xc, yc = yc

;;;;Define keyword defaults to 1 arcsecond per pixel and centre the image at the solar origin
DEFAULT, dx, 1
DEFAULT, dy, 1
DEFAULT, xc, 0
DEFAULT, yc, 0

spectral_resolution = 2.0 ; keV per bin
spectrum_lower_bound = 1.0
spectrum_upper_bound = 60.0
spectrum_dimension = (spectrum_upper_bound - spectrum_lower_bound)/spectral_resolution
IF spectrum_upper_bound EQ spectrum_lower_bound THEN spectrum_dimension = 1

source_array = DBLARR(100,100)
;;;; Warning: changing the above dimensions of source_array will
;;;; significantly affect the code runtime.

;Make structure to act as a placeholder while making the source cube

cube_creator = ADD_TAG(ADD_TAG(ADD_TAG(ADD_TAG(MAKE_MAP(source_array, dx=dx, dy=dy,    $
               xc = xc, yc = yc, id = "Source Map"), spectrum_lower_bound,'spec_min'), $
               spectrum_upper_bound, 'spec_max'),spectral_resolution,'spec_res')       $
               ,0.0, 'Energy')

source_map_spectrum = REPLICATE(cube_creator, spectrum_dimension+1)

x_size = N_ELEMENTS(REFORM(source_array[*,0]))*1.0
y_size = N_ELEMENTS(REFORM(source_array[0,*]))*1.0

;;;;;;;;;;;;;;;;;;;;;;; Get Source Cube  ;;;;;;;;;;;;;;;;;;;;;
;;; Define parameters of toy gaussian sources
FWHM_xs = x_size/20                      
FWHM_ys = y_size/20
sigma_xs = FWHM_xs/(sqrt(2.0*ALOG(2)))   ;;Standard deviations are calculated from FWHM
sigma_ys = FWHM_ys/(sqrt(2.0*ALOG(2)))

source_centre1 = [1.5*x_size/4,2.5*(y_size/4) ] ; Source centre coordinates
source_centre2 = [7*x_size/8,5*(y_size/8)]

;;; Loop over spectral slices of the cube and assign each a spatial
;;; distribution of counts.

FOR i = 0, spectrum_dimension DO BEGIN

source1 = 1000.0;*exp(-1*i*ALOG(2)/50) ; Peak Counts as function of energy
source2 = 1000.0*exp(-1*i*ALOG(2)/10)

;;; Create Sources from the above parameters

source_1  = source1*psf_gaussian(npix = [x_size, y_size], $ 
            /double, st_dev = [sigma_xs,sigma_ys],        $
            centroid = source_centre1 )


source_2  = source2*psf_gaussian(npix = [x_size, y_size], $
            /double, st_dev = [sigma_xs,sigma_ys],        $
            centroid = source_centre2)

;;; Add individual sources to get complete source array

source_array = source_1 + source_2

;;; Make map from the source array and user inputted keywords or their defaults and RETURN
;;; Adding tags to the structure to keep track of min/max energy of
;;; the cube and its resolution and also keep track of the energy of
;;; the current slice.

source_map_spectrum[i] = ADD_TAG(ADD_TAG(ADD_TAG(ADD_TAG(MAKE_MAP(source_array, dx=dx, dy=dy, xc = xc, yc = yc, id = "Source Map"), spectrum_lower_bound,'spec_min'),spectrum_upper_bound,'spec_max'),spectral_resolution,'spec_res'),spectrum_lower_bound + spectral_resolution*i, 'Energy')

ENDFOR

RETURN, source_map_spectrum

END

