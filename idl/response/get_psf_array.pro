FUNCTION get_psf_array,xc,yc, dx, dy, x, y 

DEFAULT, xc, 0
DEFAULT, yc, 0
DEFAULT, dx, 1
DEFAULT, dy, 1
DEFAULT, x, 0
DEFAULT, y, 0
;;
;; xc and yc are the coordinates of the centre of the field of view in solar coordinates (arcsecs)
;; dx and dy are the bin sizes of the field of view map
;; x and y are the coordinate of positions in the source plane

psf_array = dblarr(150,150)

x_size = n_elements(reform(psf_array[*,0]))*1.0
y_size = n_elements(reform(psf_array[0,*]))*1.0

;;;;;;;;;;;;;;;;;;;;;;;;;Generate PSF, for now just gaussians

;;; Gaussian Paramters
sigma_x1 = 1.27836
sigma_y1 = 1.77492

sigma_x2 = 4.36214
sigma_y2 = 7.21397

sigma_x3 = 47.5
sigma_y3 = 240.314

psf_centre1 = [(x_size+1)/2, (y_size+1)/2 ]
psf_centre2 = [(x_size+1)/2, (y_size+1)/2 ]
psf_centre3 = [(x_size+1)/2, (y_size+1)/2 ]

psf_1 =0.9875*psf_gaussian(npix = [x_size,y_size], /double, st_dev = [sigma_x1,sigma_y1], centroid = psf_centre1)
psf_2 = 0.218387*psf_gaussian(npix = [x_size,y_size], /double, st_dev = [sigma_x2,sigma_y2], centroid = psf_centre2)
psf_3 = 0.0762158*psf_gaussian(npix = [x_size,y_size], /double, st_dev = [sigma_x3,sigma_y3], centroid = psf_centre3)

psf_array = 1.0 * (psf_1+psf_2+psf_3)/total(psf_1+psf_2+psf_3)

print, 'Returned psf_array'
RETURN, psf_array

END
