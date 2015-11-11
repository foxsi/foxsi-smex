FUNCTION gauss2d,x,y, amp, cen_x, cen_y, sigma_x, sigma_y, theta
  ; a 2d-gaussian that includes a rotation angle theta
  ; PARAMETERS:
  ;            x : a set of x-indices, eg findgen(1000)-500
  ;            y : a set of y-indices, e.g. findgen(1000) - 500
  ;            amp : the gaussian amplitude
  ;            cen_x : the centre of the gaussian in x
  ;            cen_y : the centre of the gaussian in y
  ;            sigma_x : the width if the gaussian in x
  ;            sigma_y : the width of the gaussian in y
  ;            theta : the rotation angle (in radians)
  ;
  ; RETURNS:
  ; A 2-d gaussian array with dimensions (x,y)
  
  a = (cos(theta)^2)/(2*sigma_x^2) + (sin(theta)^2)/(2*sigma_y^2)
  b = -(sin(2*theta))/(4*sigma_x^2) + (sin(2*theta))/(4*sigma_y^2)
  c = (sin(theta)^2)/(2*sigma_x^2) + (cos(theta)^2)/(2*sigma_y^2)

  gauss = fltarr(n_elements(x),n_elements(y))
  for i = 0, n_elements(x) - 1 do begin
     for j = 0, n_elements(y)-1 do begin    
        gauss[i,j] = amp*exp( - (a*((x[i]-cen_x)^2) + 2*b*(x[i]-cen_x)*(y[j]-cen_y) + c*((y[j]-cen_y)^2)))
     endfor
  endfor

  return, gauss
END


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;FUNCTION:        "foxsi_get_psf_map"
;;;
;;;HISTORY:         Initial Commit - 08/19/15 - Samuel Badman
;;;                 Tweaked to accomodate new convolution method -
;;;                 08/31/15 - Samuel Badman
;;;                 Changed name to foxsi_get_psf_map, and added
;;;                 PSF as a function of position - 11/02/15 - A. Inglis
;;;
;;;DESCRIPTION:     Function which generates a prescribed 2D point
;;;                 spread function with specified parameters. Takes arguments of the
;;;                 solar coordinates of the centre of the image (xc, yc), the size of the
;;;                 pixels (dx,dy) and the position in the source
;;;                 image being convolved.
;;;
;;;CALL SEQUENCE:   psf_array = foxsi_get_psf_array(xc,yc,dx,dy,x,y)
;;;
;;;INPUTS:         xc - the x-centre of the PSF map in arcsec. Default
;;;                     is 0.
;;;                yc - the y-centre of the PSF map in arcsec. Default
;;;                     is 0.
;;;                dx, dy - the pixel size for the PSF map in
;;;                         arcsec. Default is 0.5
;;;                pitch - the pitch angle of the source location
;;;                        relative to the imaging axis (arcsec).
;;;                yaw - the yaw angle of the source location relative
;;;                      to the imaging axis (arcsec).
;;;
;;;OPTIONAL INPUT: x_size - the number of pixels in the PSF map in the
;;;                         x-dimension
;;;                y_size - the number of pixels in the PSF map in the
;;;                         y-dimension
;;;                oversample - the number of subpixels to average over in
;;;                             each pixel. Default is 1 (no oversampling)
;;;
;;;OUTPUTS:        psf_map - an SSW map of the PSF at the desired
;;;                          pitch, yaw location.
;;;
;;;COMMENTS:       The PSF is now available as a function of
;;;                position. To obtain this, the psf was roughly
;;;                fitted as a sum of 3 gaussians over a range of
;;;                positions, and each parameter was fit by a
;;;                polynomial function. These fits are used by this routine.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FUNCTION foxsi_get_psf_map, xc, yc, dx, dy, pitch, yaw,$
  x_size=x_size, y_size=y_size, oversample=oversample

  default,xc,0
  default,yc,0
  default,dx,0.5
  default,dy,0.5
  default,x_size,101
  default,y_size,101
  default,oversample,1
  oversample_int = long(oversample) > 1
  
  ; calculate offaxis angle and theta from pitch and yaw
  offaxis_angle = sqrt(pitch^2 + yaw^2) / 60. ; convert to arcminutes
  polar_angle = atan(yaw, pitch) ; angle in radians
  
 ;read FOXSI PSF parameter fit values from file
  COMMON foxsi_smex_vars, foxsi_root_path, foxsi_data_path
  variable_fit_params = READ_ASCII(foxsi_data_path + 'psf_parameters.txt')
  
  poly_amp1 = reverse(variable_fit_params.field1[*,0])
  poly_amp2 = reverse(variable_fit_params.field1[*,1])
  poly_amp3 = reverse(variable_fit_params.field1[*,2])
  poly_width_x1 = reverse(variable_fit_params.field1[*,3])
  poly_width_x2 = reverse(variable_fit_params.field1[*,4])
  poly_width_x3 = reverse(variable_fit_params.field1[*,5])
  poly_width_y1 = reverse(variable_fit_params.field1[*,6])
  poly_width_y2 = reverse(variable_fit_params.field1[*,7])
  poly_width_y3 = reverse(variable_fit_params.field1[*,8])

  ;reconstruct the fit functions for each parameter of the FOXSI PSF
  amp1 = poly(offaxis_angle,poly_amp1)
  amp2 = poly(offaxis_angle,poly_amp2)
  amp3 = poly(offaxis_angle,poly_amp3)
  width_x1 = poly(offaxis_angle,poly_width_x1)
  width_y1 = poly(offaxis_angle,poly_width_y1)
  width_x2 = poly(offaxis_angle,poly_width_x2)
  width_y2 = poly(offaxis_angle,poly_width_y2)
  width_x3 = poly(offaxis_angle,poly_width_x3)
  width_y3 = poly(offaxis_angle,poly_width_y3)


;;;08/31 - Make sure dimensions of psf_array are odd to be able to
;;;        precisely line up pixels during convolution.
;;;
  psf_x_size = (2 * (long(x_size) / 2) + 1) * oversample_int
  psf_y_size = (2 * (long(y_size) / 2) + 1) * oversample_int

  x = (findgen(psf_x_size) * dx / oversample_int) - ( ((psf_x_size - 1) / 2. * dx / oversample_int)) + xc
  y = (findgen(psf_y_size) * dy / oversample_int) - ( ((psf_y_size - 1) / 2. * dy / oversample_int)) + yc


;;;;;;;;;;;;;;;;;;;;;;;;;Generate PSF with measured paramaters for
;;;;;;;;;;;;;;;;;;;;;;;;;gaussian fits

  ;construct the 3-gaussian FOXSI PSF for a given offaxis angle and polar angle
  g1 = gauss2d(x, y, amp1, xc, yc, width_x1, width_y1, polar_angle)
  g2 = gauss2d(x, y, amp2, xc, yc, width_x2, width_y2, polar_angle)
  g3 = gauss2d(x, y, amp3, xc, yc, width_x3, width_y3, polar_angle)

  ;; Normalise total PSF so that total of psf_array EQ 1
  psf = (g1 + g2 + g3) / total(g1+g2+g3)

  if oversample_int gt 1 then begin
    psf = reform(psf, oversample_int, psf_x_size / oversample_int, oversample_int, psf_y_size / oversample_int, /overwrite)
    psf = total(total(psf, 3), 1)
  endif

  ;make the PSF as an SSW map
  psf_map = make_map(psf,xc = xc, yc = yc, dx = dx, dy = dy, id = 'FOXSI PSF', polar_angle = polar_angle*!radeg,$
                     offaxis_angle=offaxis_angle, offaxis_angle_units = 'arcmin', polar_angle_units = 'deg')

 ;??? not sure what this does
psf_centre1 = [(psf_x_size+1)/2, (psf_y_size+1)/2 ]  ;;PSF centered
psf_centre2 = [(psf_x_size+1)/2, (psf_y_size+1)/2 ]
psf_centre3 = [(psf_x_size+1)/2, (psf_y_size+1)/2 ]


;; Return PSF map
print, 'Returned psf map'
RETURN, psf_map

END
