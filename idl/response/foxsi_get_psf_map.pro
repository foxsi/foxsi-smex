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
;;;FUNCTION:        "foxsi_get_psf_array"
;;;
;;;HISTORY:         Initial Commit - 08/19/15 - Samuel Badman
;;;                 Tweaked to accomodate new convolution method -
;;;                 08/31/15 - Samuel Badman 
;;;
;;;DESCRIPTION:     Function which generates a prescribed 2D point
;;;                 spread function with specified parameters. Takes arguments of the
;;;                 solar coordinates of the centre of the image (xc, yc), the size of the
;;;                 pixels (dx,dy) and the position in the source
;;;                 image being convolved.Eventually these will be
;;;                 used to change the parameters of the psf depending
;;;                 on the source position and FOV position. 
;;;
;;;CALL SEQUENCE:   psf_array = foxsi_get_psf_array(xc,yc,dx,dy,x,y)
;;;
;;;COMMENTS:       Currently,the psf generated is that obtained by
;;;                measuring the diffraction patterns of the FOXSI optics from an xray
;;;                generator at an off-axis positon of 7' . The psf was roughly
;;;                fitted as a sum of 3 gaussians with parameters indicated in the
;;;                code below.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FUNCTION foxsi_get_psf_map,xc,yc, dx, dy, x, y,x_size=x_size, y_size=y_size,$
                             offaxis_angle=offaxis_angle,theta=theta
 
  default,xc,0
  default,yc,0
  default,dx,0.5
  default,dy,0.5
  default,offaxis_angle,0
  default,theta,0
  default,x_size,100
  default,y_size,100
  
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

  theta_rad = theta*!const.DtoR
  ;construct the 3-gaussian FOXSI PSF for a given offaxis angle and theta
  g1 = gauss2d(x, y, amp1, xc, yc, width_x1, width_y1, theta_rad)
  g2 = gauss2d(x, y, amp2, xc, yc, width_x2, width_y2, theta_rad)
  g3 = gauss2d(x, y, amp3, xc, yc, width_x3, width_y3, theta_rad)

  ;; Normalise total PSF so that total of psf_array EQ 1
  psf = (g1 + g2 + g3) / total(g1+g2+g3)

  psf_map = make_map(psf,xc = xc, yc = yc, dx = dx, dy = dy, id = 'FOXSI PSF', theta = theta, offaxis_angle=offaxis_angle)


psf_centre1 = [(psf_x_size+1)/2, (psf_y_size+1)/2 ]  ;;PSF centered
psf_centre2 = [(psf_x_size+1)/2, (psf_y_size+1)/2 ]
psf_centre3 = [(psf_x_size+1)/2, (psf_y_size+1)/2 ]


;; Return PSF map
print, 'Returned psf_array'
RETURN, psf_map

END
