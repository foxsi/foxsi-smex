;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;FUNCTION:      "get_foxsi_spectral_image"
;;;
;;;HISTORY:       Initial Commit - 08/19/15 - Samuel Badman
;;;
;;;DESCRIPTION:   Function which accepts a map of a source as an input, obtained through
;;;               calling source_map = get_source_map(). This map is the
;;;               convolved with a point spread function obtained through calling the
;;;               function get_psf_array with arguments specifying the
;;;               solar coordinates of the image sensor. After
;;;               convolution, the new image is rebinned according to
;;;               the keyword px = pix_size (default = 3) to reflect the
;;;               loss of resolution due to the finite strip size in the detectors.
;;; 
;;;
;;;CALL SEQUENCE: rebinned_convolved_map = get_foxsi_image()
;;;
;;;
;;;KEYWORDS:      source_map = "source_map". User inputted source, if
;;;               blank, default generated from get_source_map
;;;               function
;;;
;;;               px = "pixel size of detector" in arcseconds, default is 3''
;;;
;;;
;;;COMMENTS:      -Runtime scales badly with FOV size
;;;               -The default source array is 
;;;               set to [150,150] ~2.5' X 2.5' FOV at 1 arcsec per
;;;               pixel, this takes a few seconds to run.
;;;               -For your source, note the effective area is not
;;;               defined below 1KeV or above ~60KeV. Also resonance troughs will cause
;;;               problems for energies below 3KeV. If possible use a
;;;               source cube with energies above 3KeV and below 60KeV
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FUNCTION get_foxsi_spectral_image,source_map_spectrum = source_map_spectrum, px = pix_size

IF N_ELEMENTS(source_map_spectrum) EQ 0 THEN PRINT, 'No user input detected, using default source image'

;;;;; Check for updates to peripheral functions for the purposes of testing
RESOLVE_ROUTINE, 'get_psf_array', /IS_FUNCTION
RESOLVE_ROUTINE, 'get_source_map_spectrum', /IS_FUNCTION
RESOLVE_ROUTINE, 'foxsi_get_optics_effective_area', /IS_FUNCTION

;;;; Define default source_map input in case of no user input
DEFAULT, source_map_spectrum, get_source_map_spectrum()

print, "Spectral Min (KeV) ="+string(source_map_spectrum[0].spec_min)
print, "Spectral Max (KeV) ="+string(source_map_spectrum[0].spec_max)
print, "Spectral Resolution (KeV/Spectral Interval) ="+string(source_map_spectrum[0].spec_res)

;;;;; Define default detector resolution to 3 arcsecs per pixel
DEFAULT, pix_size, 3


x=0 ;; Redundant FOV coordinates required as arguments for get_psf_array
y=0


x_size = N_ELEMENTS(REFORM(source_map_spectrum[0].data[*,0]))*1.0  ;;; Get dimensions of FOV in pixels
y_size = N_ELEMENTS(REFORM(source_map_spectrum[0].data[0,*]))*1.0 

print, strcompress('Source_FOV_is_'+string(N_ELEMENTS(REFORM(source_map_spectrum[0].data[*,0]))) $
+'x'+string(N_ELEMENTS(REFORM(source_map_spectrum[0].data[0,*])))+'_Pixels', /REMOVE_AL)

;; If psf is large and has non zero intensity far from the psf centre
;; then the psf array must be larger than the source array or some
;; point spread emission will be lost due to array cutoffs. For
;; perfect reconstruction in all cases, scale factor should be 2


;;Below, we call the point spread function assuming it is constant
;;across the field of view for a given pointing and only depends on
;;the pointing itself. 
;;To change this and introduce dependence of the psf on position in
;;the FOV being convolved, comment out the line marked below and
;;uncomment the copy of it inside the FOR loop (Note this will slow down runtime a lot)

;;;Comment out the line below::::
psf_array = get_psf_array(source_map_spectrum[0].xc,source_map_spectrum[0].yc,source_map_spectrum[0].dx                  $
,source_map_spectrum[0].dy,x,y,x_size,y_size) 

psf_x_size = n_elements(reform(psf_array[*,0]))*1.0
psf_y_size = n_elements(reform(psf_array[0,*]))*1.0
convolved_array = DBLARR(x_size,y_size)
convolved_cube = DBLARR(x_size,y_size, N_ELEMENTS(source_map_spectrum.data[0,0,*]))

eff_area = foxsi_get_optics_effective_area()

spec_min = source_map_spectrum[0].spec_min
spec_max = source_map_spectrum[0].spec_max
spec_size = N_ELEMENTS(source_map_spectrum.data[0,0,*])
spec_res = source_map_spectrum[0].spec_res

energy_array = eff_area.energy_kev
eff_area_array = eff_area.eff_area_cm2

source_energy_range = findgen(spec_size)*spec_res+spec_min
energy_subscripts = DBLARR(N_ELEMENTS(source_energy_range))

energy_interpol = INTERPOL(energy_array,2*N_ELEMENTS(energy_array))
eff_interpol = INTERPOL(eff_area_array, 2*N_ELEMENTS(energy_array))

inaccurate1 = ''
inaccurate2 = ''
inaccurate3 = ''

FOR k = 0.0, N_ELEMENTS(source_energy_range)-1 DO BEGIN

  arg = energy_interpol - source_energy_range[k]

  find = WHERE(ABS(arg) LT 0.100)

  find2 =  arg[WHERE(arg LT 0.100)]
      IF N_ELEMENTS(find) EQ 1 THEN BEGIN
       IF find eq -1 THEN BEGIN
       inaccurate1 = 'true'
       BREAK
       ENDIF
    ENDIF  
  
   IF MIN(find2) LT 0 && MAX(find2) GT 0 THEN find = MEAN(find)
   IF MIN(find2) GT 0 && MAX(find2) GT 0 THEN find = find[0]
   IF MIN(find2) LT 0 && MAX(find2) LT 0 THEN find = find[WHERE(find eq MAX(find))]

  energy_subscripts[k] = find 

ENDFOR

IF inaccurate1 NE 'true' THEN eff_area_values = eff_interpol[energy_subscripts]


IF inaccurate1 EQ 'true' THEN BEGIN
 
  energy_interpol = INTERPOL(energy_array,3*N_ELEMENTS(energy_array))
  eff_interpol = INTERPOL(eff_area_array, 3*N_ELEMENTS(energy_array))

  FOR k = 0.0, N_ELEMENTS(source_energy_range)-1 DO BEGIN
    
    arg = energy_interpol - source_energy_range[k]
    find = WHERE(ABS(arg) LT 0.100)
    find2 = arg[ WHERE(arg LT 0.100)]
    IF N_ELEMENTS(find) EQ 1 THEN BEGIN
       IF find eq -1 THEN BEGIN
       inaccurate2 = 'true'
       BREAK
       ENDIF
    ENDIF  
  
    IF MIN(find2) LT 0 && MAX(find2) GT 0 THEN find = MEAN(find)
    IF MIN(find2) GT 0 && MAX(find2) GT 0 THEN find = find[0]
    IF MIN(find2) LT 0 && MAX(find2) LT 0 THEN find = find[WHERE(find eq MAX(find))]
    
    energy_subscripts[k] = find

  ENDFOR
  
  IF inaccurate2 NE 'true' THEN eff_area_values = eff_interpol[energy_subscripts]  

ENDIF

IF inaccurate2 EQ 'true' THEN BEGIN
 
  energy_interpol = INTERPOL(energy_array,4*N_ELEMENTS(energy_array))
  eff_interpol = INTERPOL(eff_area_array, 4*N_ELEMENTS(energy_array))  

  FOR k = 0.0, N_ELEMENTS(source_energy_range)-1 DO BEGIN

    arg = energy_interpol - source_energy_range[k]
    find = WHERE(ABS(arg) LT 0.100)
    find2 = arg[WHERE(arg LT 0.100)]
    IF N_ELEMENTS(find) EQ 1 THEN BEGIN
       IF find eq -1 THEN BEGIN
       inaccurate3 = 'true'
       BREAK
       ENDIF
    ENDIF  
  
    IF MIN(find2) LT 0 && MAX(find2) GT 0 THEN find = MEAN(find)
    IF MIN(find2) GT 0 && MAX(find2) GT 0 THEN find = find[0]
    IF MIN(find2) LT 0 && MAX(find2) LT 0 THEN find = find[WHERE(find eq MAX(find))]
    
    energy_subscripts[k] = find

  ENDFOR

  IF inaccurate3 NE 'true' THEN eff_area_values = eff_interpol[energy_subscripts]
  IF inaccurate3 EQ 'true' THEN print, 'probably need to try a different method'
ENDIF

attenuated_source = source_map_spectrum.data*TRANSPOSE(REBIN(eff_area_values, N_ELEMENTS(eff_area_values), y_size, x_size))

FOR j = 0.0, N_ELEMENTS(source_map_spectrum.data[0,0,*])-1 DO BEGIN

convolved_array = DBLARR(x_size,y_size)


PRINT, STRCOMPRESS('Convolving_spectral_slice_'+STRING(FIX(j+1))+'_of_'+STRING(N_ELEMENTS(source_map_spectrum.data[0,0,*])),/REMOVE_AL)

  IF x_size MOD 2 EQ 0 THEN BEGIN

    FOR i = 0.0, N_ELEMENTS(source_map_spectrum[j].data)-1 DO BEGIN

        x = (i MOD x_size)*1.0  
        y = (i - x)/x_size*1.0
       
	convolved_pixel = psf_array * attenuated_source[x,y,j]
	shifted_convolved_pixel = convolved_pixel[(psf_x_size/2-x):(psf_x_size/2-x+x_size-1), (psf_y_size/2 -y):(psf_y_size/2-y+y_size-1)]
       convolved_array = convolved_array + shifted_convolved_pixel

    ENDFOR
ENDIF ELSE BEGIN

    FOR i = 0.0, N_ELEMENTS(source_map_spectrum[j].data)-1 DO BEGIN

        x = (i MOD x_size)*1.0  
        y = (i - x)/x_size*1.0
       
	convolved_pixel = psf_array *attenuated_source[x,y,j]
	shifted_convolved_pixel = convolved_pixel[((psf_x_size-1)/2-x):((psf_x_size-1)/2-x+x_size-1), ((psf_y_size-1)/2 -y):((psf_y_size-1)/2-y+y_size-1)]
       convolved_array = convolved_array + shifted_convolved_pixel

    ENDFOR

ENDELSE
   
   convolved_cube[*,*,j] = convolved_array
 
ENDFOR


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;; Do rebinning due to detector pixelation;;;

rebin =  FREBIN(convolved_cube[*,*,0],x_size*source_map_spectrum[0].dx/pix_size,y_size*source_map_spectrum[0].dy/pix_size, /TOTAL)

rebinned_convolved_cube = DBLARR(N_ELEMENTS(rebin[*,0]), N_ELEMENTS(rebin[0,*]), N_ELEMENTS(convolved_cube[0,0,*]))

renorm = 0

FOR layer = 0, N_ELEMENTS(convolved_cube[0,0,*])-1 DO BEGIN

   rebin = FREBIN(convolved_cube[*,*,layer],x_size*source_map_spectrum[0].dx/pix_size,y_size*source_map_spectrum[0].dy/pix_size, /TOTAL)
   


   IF ABS(TOTAL(rebin) - TOTAL(convolved_cube[*,*,layer])) GT 0.0001  THEN BEGIN
   rebin =TOTAL(convolved_cube[*,*,layer])* (rebin)/TOTAL(rebin) ;;;; Renormalise counts to assume lossless between optics and detector
   renorm = 1

   ENDIF

  

   rebinned_convolved_cube[*,*,layer] = rebin  

ENDFOR

 IF renorm EQ 1 THEN print, 'Rebinning loss detected, renormalising...'
;; Detect if FREBIN causes unacceptable loss of counts (e.g for non
;; integer pixelation ratio. If detected, total counts are
;; renormalised to correct (ideal) value.




;;; Makes and outputs map of convolved and rebinned array with pixel size 
;;; equal to the value of the px keyword (default = 3'' per pixel)
;;; The centre of the map is preserved as the centre of the source
;;; image

rebinned_cube_creator = ADD_TAG(ADD_TAG(ADD_TAG(ADD_TAG(make_map(rebinned_convolved_cube[*,*,0], dx = pix_size, dy = pix_size, xc = source_map_spectrum.xc, yc = source_map_spectrum.yc, id = STRCOMPRESS('Rebinned_Convolved_Map_Pixel_Size:'+string(pix_size),/REMOVE_AL)), spec_min,'spec_min'),spec_max,'spec_max'),spec_res,'spec_res'),0.0, 'Energy')

rebinned_convolved_maps = REPLICATE(rebinned_cube_creator, N_ELEMENTS(rebinned_convolved_cube[0,0,*]))

FOR rebin_layer = 0.0, N_ELEMENTS(rebinned_convolved_cube[0,0,*])-1 DO BEGIN
rebinned_convolved_maps[rebin_layer] =  ADD_TAG(ADD_TAG(ADD_TAG(ADD_TAG(make_map(rebinned_convolved_cube[*,*,rebin_layer], dx = pix_size, dy = pix_size, xc = source_map_spectrum.xc, yc = source_map_spectrum.yc, id = STRCOMPRESS('Rebinned_Convolved_Map_Pixel_Size:'+string(pix_size),/REMOVE_AL)), spec_min,'spec_min'),spec_max,'spec_max'),spec_res,'spec_res'),spec_min + spec_res*rebin_layer, 'Energy')
ENDFOR



print,  'rebinned_convolved_maps returned'
STOP
RETURN, rebinned_convolved_maps

END
