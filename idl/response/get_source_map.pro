FUNCTION get_source_map, dx = dx, dy = dy, xc = xc, yc = yc

DEFAULT, dx, 1
DEFAULT, dy, 1
DEFAULT, xc, 0
DEFAULT, yc, 0

source_array = dblarr(150,150) ;,100) < energy dimension ; line_energy = 6/20*100.0

x_size = n_elements(reform(source_array[*,0]))*1.0
y_size = n_elements(reform(source_array[0,*]))*1.0

;;;;;;;;;;;;;;;;;;;;;;; Get Source Array  ;;;;;;;;;;;;;;;;;;;;;



FWHM_xs = x_size/24
FWHM_ys = y_size/24
sigma_xs = FWHM_xs/(sqrt(2.0*ALOG(2)))
sigma_ys = FWHM_ys/(sqrt(2.0*ALOG(2)))



source1 = 100.0 ; counts
source2 = 100.0 ; counts



source_centre1 = [x_size/8,3*(y_size/8) ]
source_centre2 = [7*x_size/8,5*(y_size/8) ]

	FOR i = 0.0, n_elements(source_array)-1 DO BEGIN
	
        	x = (i mod x_size)*1.0
        	y = (i - x)/x_size*1.0
		source_array[x,y] = source1*exp(-1*((x-source_centre1[0])^2/(2*sigma_xs^2)+(y-source_centre1[1])^2/(2*sigma_ys^2)))+ source2*exp(-1*((x-source_centre2[0])^2/(2*sigma_xs^2)+(y-source_centre2[1])^2/(2*sigma_ys^2)))

	ENDFOR


source_map = make_map(source_array, dx=dx, dy=dy, xc = xc, yc = yc, id = "Source Map")


RETURN, source_map

END

