;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;FUNCTION:        "get_psf_array"
;;;
;;;HISTORY:         Initial Commit - 08/19/15 - Samuel Badman
;;;
;;;DESCRIPTION:     Function which generates a prescribed 2D point
;;;                 spread function with specified parameters. Takes arguments of the
;;;                 solar coordinates of the centre of the image (xc, yc), the size of the
;;;                 pixels (dx,dy) and the position in the source
;;;                 image being convolved.Eventually these will be
;;;                 used to change the parameters of the psf depending
;;;                 on the source position and FOV position. 
;;;
;;;CALL SEQUENCE:   psf_array = get_psf_array(xc,yc,dx,dy,x,y)
;;;
;;;COMMENTS:       Currently,the psf generated is that obtained by
;;;                measuring the diffraction patterns of the FOXSI optics from an xray
;;;                generator at an off-axis positon of 7' . The psf was roughly
;;;                fitted as a sum of 3 gaussians with parameters indicated in the
;;;                code below.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FUNCTION get_psf_array,xc,yc, dx, dy, x, y,x_size, y_size 

;; Set defaults to the positon corresponding to the currently
;; generated PSF parameters
DEFAULT, xc, 420
DEFAULT, yc, 0
DEFAULT, dx, 1
DEFAULT, dy, 1
DEFAULT, x, 0
DEFAULT, y, 0

;;; Note array size here must match that of the source_map.data array
;;; inputted in to the main get_foxsi_image function

psf_scale_factor = 2

IF x_size MOD 2 NE 0.0 THEN psf_array = DBLARR(psf_scale_factor*x_size+1,psf_scale_factor*y_size+1)
IF x_size MOD 2 EQ 0.0 THEN psf_array = DBLARR(psf_scale_factor*x_size,psf_scale_factor*y_size)

psf_x_size = n_elements(reform(psf_array[*,0]))*1.0
psf_y_size = n_elements(reform(psf_array[0,*]))*1.0

;;;;;;;;;;;;;;;;;;;;;;;;;Generate PSF, for now just gaussians

;;; Gaussian Paramters
sigma_x1 = 1.27836
sigma_y1 = 1.77492

sigma_x2 = 4.36214
sigma_y2 = 7.21397

sigma_x3 = 47.5
sigma_y3 = 240.314

psf_centre1 = [(psf_x_size+1)/2, (psf_y_size+1)/2 ]
psf_centre2 = [(psf_x_size+1)/2, (psf_y_size+1)/2 ]
psf_centre3 = [(psf_x_size+1)/2, (psf_y_size+1)/2 ]

;; Generate gaussian from above parameters
psf_1 =0.9875*psf_gaussian(npix = [psf_x_size,psf_y_size], /double, st_dev = [sigma_x1,sigma_y1], centroid = psf_centre1)
psf_2 = 0.218387*psf_gaussian(npix = [psf_x_size,psf_y_size], /double, st_dev = [sigma_x2,sigma_y2], centroid = psf_centre2)
psf_3 = 0.0762158*psf_gaussian(npix = [psf_x_size,psf_y_size], /double, st_dev = [sigma_x3,sigma_y3], centroid = psf_centre3)

;; Normalise total PSF so that total of psf_array EQ 1
psf_array = 1.0 * (psf_1+psf_2+psf_3)/total(psf_1+psf_2+psf_3)


;; Return PSF
print, 'Returned psf_array'
RETURN, psf_array

END
