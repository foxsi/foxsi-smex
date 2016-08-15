;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;FUNCTION:      "foxsi_get_default_source_cube"         
;;;
;;;HISTORY:       Initial Commit - 08/31/15 - Samuel Badman
;;;               Changed overall flux to a more manageable value. -- 8/6/2015 -- Lindsay
;;;                                                                                            
;;;DESCRIPTION:   Function which returns an array of structures
;;;               consisting of 2D maps with spectral information
;;;               appended as tags. Default spectrum for the routine 
;;;               get_foxsi_image_cube.pro          
;;;                                                                                            
;;;CALL SEQUENCE: source_map_cube = foxsi_get_default_source_cube()                      
;;;                                                                                            
;;;KEYWORDS:      dx, dy - binsize of pixels in arcseconds 
;;;               xc, yc - centre of image in solar coordinates (arcseconds)
;;;               nbins - number of energy bins.  Default is 29
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

FUNCTION foxsi_get_default_source_cube, dx = dx, dy = dy, xc = xc, yc = yc,   $
                                        nbins = nbins

;;Define keyword defaults to 1 arcsecond per pixel and centre the image at the solar origin
DEFAULT, dx, 1
DEFAULT, dy, 1
DEFAULT, xc, 0
DEFAULT, yc, 0
DEFAULT, nbins, 14

lower_energy_bound = 2.0
upper_energy_bound = 60.0

energy_spacings   = FINDGEN(nbins+1)*(upper_energy_bound - lower_energy_bound)/nbins
lower_bound_array = energy_spacings[0:nbins-1] + lower_energy_bound
upper_bound_array = energy_spacings[1:nbins] + lower_energy_bound

source_array = DBLARR(100,100)
dims         = SIZE(source_array, /DIM)

;;;; Warning: changing the above dimensions of source_array will
;;;; significantly affect the code runtime.

x_size = dims[0]*1.0
y_size = dims[1]*1.0

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

FOR i = 0, nbins - 1 DO BEGIN

   source1 = 1.0*exp(-1*i*ALOG(2)/50) ; Peak Counts as function of energy
   source2 = 1.0*exp(-1*i*ALOG(2)/10)

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
   ;;; each spectral bin

   source_map = MAKE_MAP(source_array, dx=dx, dy=dy, xc = xc, yc = yc, id = "Source Map")
   source_map = ADD_TAG(source_map, lower_bound_array[i],'energy_bin_lower_bound_keV')
   source_map = ADD_TAG(source_map, upper_bound_array[i],'energy_bin_upper_bound_keV')

   source_map_cube = append_arr(source_map_cube, source_map, /no_copy)

ENDFOR

RETURN, source_map_cube

END

