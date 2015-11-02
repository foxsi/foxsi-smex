FUNCTION polynomial, angle, a, b, c
  result = (a*angle^2) + (b*angle) + c
  RETURN,result
END


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

FUNCTION foxsi_get_psf_map,xc,yc, dx, dy, pitch, yaw ,x_size=x_size, y_size=y_size                          
 
  default,xc,0
  default,yc,0
  default,dx,0.5
  default,dy,0.5
  default,x_size,100
  default,y_size,100
  
  ; calculate offaxis angle and theta from pitch and yaw
  offaxis_angle = sqrt(pitch^2 + yaw^2) / 60. ; convert to arcminutes
  polar_angle = atan(yaw, pitch) ; angle in radians
  
 ;read FOXSI PSF parameter fit values from file
  variable_fit_params = READ_ASCII('psf_parameters.txt')
  
  poly_amp1 = variable_fit_params.field1[*,0]
  poly_amp2 = variable_fit_params.field1[*,1]
  poly_amp3 = variable_fit_params.field1[*,2]
  poly_width_x1 = variable_fit_params.field1[*,3]
  poly_width_x2 = variable_fit_params.field1[*,5]
  poly_width_x3 = variable_fit_params.field1[*,7]
  poly_width_y1 = variable_fit_params.field1[*,4]
  poly_width_y2 = variable_fit_params.field1[*,6]
  poly_width_y3 = variable_fit_params.field1[*,8]


  ;reconstruct the fit functions for each parameter of the FOXSI PSF
  amp1 = polynomial(offaxis_angle,poly_amp1[0],poly_amp1[1],poly_amp1[2])
  amp2 = polynomial(offaxis_angle,poly_amp2[0],poly_amp2[1],poly_amp2[2])
  amp3 = polynomial(offaxis_angle,poly_amp3[0],poly_amp3[1],poly_amp3[2])
  width_x1 = polynomial(offaxis_angle,poly_width_x1[0],poly_width_x1[1],poly_width_x1[2])
  width_y1 = polynomial(offaxis_angle,poly_width_y1[0],poly_width_y1[1],poly_width_y1[2])
  width_x2 = polynomial(offaxis_angle,poly_width_x2[0],poly_width_x2[1],poly_width_x2[2])
  width_y2 = polynomial(offaxis_angle,poly_width_y2[0],poly_width_y2[1],poly_width_y2[2])
  width_x3 = polynomial(offaxis_angle,poly_width_x3[0],poly_width_x3[1],poly_width_x3[2])
  width_y3 = polynomial(offaxis_angle,poly_width_y3[0],poly_width_y3[1],poly_width_y3[2])

  
;;08/31 - Made psf_scale_factor always 2 so full image always convolved
  psf_scale_factor = 2

;;;08/31 - Make sure dimensions of psf_array are odd to be able to
;;;        precisely line up pixels during convolution.
;;;
  psf_x_size = 1.0*(psf_scale_factor*x_size +1 - (psf_scale_factor*x_size MOD 2))
  psf_y_size = 1.0*(psf_scale_factor*y_size +1 - (psf_scale_factor*y_size MOD 2))

  x = (findgen(psf_x_size) * dx) - ( (psf_x_size*dx / 2.)) + xc
  y = (findgen(psf_y_size) * dy) - ( (psf_y_size*dy / 2.)) + yc
  

;;;;;;;;;;;;;;;;;;;;;;;;;Generate PSF with measured paramaters for
;;;;;;;;;;;;;;;;;;;;;;;;;gaussian fits

  ;construct the 3-gaussian FOXSI PSF for a given offaxis angle and polar angle
  g1 = gauss2d(x, y, amp1, xc, yc, width_x1, width_y1, polar_angle)
  g2 = gauss2d(x, y, amp2, xc, yc, width_x2, width_y2, polar_angle)
  g3 = gauss2d(x, y, amp3, xc, yc, width_x3, width_y3, polar_angle)

  ;; Normalise total PSF so that total of psf_array EQ 1
  psf = (g1 + g2 + g3) / total(g1+g2+g3)

  ;make the PSF as an SSW map
  psf_map = make_map(psf,xc = xc, yc = yc, dx = dx, dy = dy, id = 'FOXSI PSF', polar_angle = polar_angle*!radeg, offaxis_angle=offaxis_angle)

 ;??? not sure what this does
psf_centre1 = [(psf_x_size+1)/2, (psf_y_size+1)/2 ]  ;;PSF centered
psf_centre2 = [(psf_x_size+1)/2, (psf_y_size+1)/2 ]
psf_centre3 = [(psf_x_size+1)/2, (psf_y_size+1)/2 ]


;; Return PSF map
print, 'Returned psf map'
RETURN, psf_map

END
