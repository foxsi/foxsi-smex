FUNCTION get_psf_array,x ,y 

 ;;;; x and y are the coordinate of positions in the source plane

psf_array = dblarr(150,150)

x_size = n_elements(reform(psf_array[*,0]))*1.0
y_size = n_elements(reform(psf_array[0,*]))*1.0

;;;;;;;;;;;;;;;;;;;;;;;;;Generate PSF, for now just gaussians

FWHM_xp = x_size/18
FWHM_yp = y_size/18
sigma_xp = FWHM_xp/(sqrt(2.0*ALOG(2)))
sigma_yp = FWHM_yp/(sqrt(2.0*ALOG(2)))

psf_centre1 = [x_size/2 ,9*y_size/16 ]
psf_centre2 = [7*x_size/16, y_size/2]
psf_centre3 = [9*x_size/16, y_size/2]

x_psf = dindgen(x_size,y_size) mod y_size
y_psf = transpose(x_psf)

	psf_array = exp(-1*((x_psf-psf_centre1[0])^2/(2*sigma_xp^2)+(y_psf-psf_centre1[1])^2/(2*sigma_yp^2))) + exp(-1*((x_psf-psf_centre2[0])^2/(2*sigma_xp^2)+(y_psf-psf_centre2[1])^2/(2*sigma_yp^2))) + exp(-1*((x_psf-psf_centre3[0])^2/(2*sigma_xp^2)+(y_psf-psf_centre3[1])^2/(2*sigma_yp^2)))



psf_array = 1.0 * psf_array/total(psf_array)

RETURN, psf_array

END
