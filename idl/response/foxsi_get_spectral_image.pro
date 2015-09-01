;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;FUNCTION:      "foxsi_get_spectral_image"
;;;
;;;HISTORY:       Initial Commit - 08/25/15 - Samuel Badman
;;;               Improved Convolution Method - 08/31/15 - Samuel Badman               
;;;
;;;DESCRIPTION:   Function which accepts an array of structures as an
;;;               input. The structures must consist of an flux map (from MAKE_MAP.pro)
;;;               with the following tags appended (use ADD_TAG.pro):
;;;
;;;     >> 'spec_min' : energy value of first (lowest energy) slice in spectrum (KeV)
;;;     >> 'spec_max' : energy value of last (highest energy) slice in spectrum (KeV)
;;;     >> 'spec_res' : energy resolution of spectrum (KeV/slice)
;;;     >> 'energy'   : spec_min + slice_coordinate X spec_res
;;;
;;;               Each flux map is converted to counts through
;;;               multiplication by an effective area obtained from
;;;               foxsi_get_eff_area.pro. These count maps are then
;;;               from this array convolved with a point
;;;               spread function obtained through calling the
;;;               function get_psf_array with arguments specifying the
;;;               solar coordinates of the image sensor. After
;;;               convolution, the new image is rebinned according to
;;;               the keyword px = pix_size (default = 3) to reflect
;;;               the loss of resolution due to the finite strip size
;;;               in the detectors.The output is a structure with
;;;               identical parameters to the input source with the
;;;               above appended tags. This contains a processed
;;;               (convolved and pixelised) image at each energy value
;;;               of the source along with the relevant spectral information.
;;; 
;;;
;;;CALL SEQUENCE: rebinned_convolved_map = foxsi_get_spectral_image()
;;;
;;;
;;;KEYWORDS:      source_map = "source_map". User inputted source, if
;;;               blank, default generated from get_source_map_spectrum.pro
;;;               function
;;;
;;;               px = "pixel size of detector" in arcseconds, default is 3''
;;;
;;;
;;;COMMENTS:      -Runtime scales badly with FOV size
;;;               -The default spatial dimensions are set to 
;;;                [100,100] ~2.5' X 2.5' FOV at 1 arcsec per
;;;               pixel, this takes ~1s per energy slice.
;;;               -For your source, note the effective area is not
;;;               defined below 1KeV or above ~60KeV. 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FUNCTION foxsi_get_spectral_image,source_map_spectrum = source_map_spectrum, px = pix_size

IF N_ELEMENTS(source_map_spectrum) EQ 0 THEN PRINT, 'No user input detected' $
                                                    +', using default source image'

;;;;; Check for updates to peripheral functions for the purposes of testing
RESOLVE_ROUTINE, 'foxsi_get_psf_array', /IS_FUNCTION
RESOLVE_ROUTINE, 'foxsi_get_source_map_spectrum', /IS_FUNCTION
RESOLVE_ROUTINE, 'foxsi_get_effective_area', /IS_FUNCTION

;;;; Define default source_map input in case of no user input
DEFAULT, source_map_spectrum, foxsi_get_source_map_spectrum()

;;;;; Define default detector resolution to 3 arcsecs per pixel
DEFAULT, pix_size, 3

;;;; Pull spectral information from input source structure array.
spec_min = source_map_spectrum[0].spec_min
spec_max = source_map_spectrum[0].spec_max
spec_size = N_ELEMENTS(source_map_spectrum.data[0,0,*])
spec_res = source_map_spectrum[0].spec_res


print, "Spectral Min (KeV) ="+string(spec_min)
print, "Spectral Max (KeV) ="+string(spec_max)
print, "Spectral Resolution (KeV/Spectral Interval) ="+string(spec_res)

;; Redundant FOV coordinates required as arguments for get_psf_array
x=0 
y=0

 ;;; Get dimensions of FOV in pixels
x_size = N_ELEMENTS(REFORM(source_map_spectrum[0].data[*,0]))*1.0 
y_size = N_ELEMENTS(REFORM(source_map_spectrum[0].data[0,*]))*1.0 

print, strcompress('Source_FOV_is_'+string(N_ELEMENTS(REFORM(source_map_spectrum[0].data[*,0])$
       )) +'x'+string(N_ELEMENTS(REFORM(source_map_spectrum[0].data[0,*])))+'_Pixels',        $
       /REMOVE_AL)




;;; Interpolate source to achieve odd dimensions for the purpose
;;; of accurate convolution

o_x_size =  x_size + 1 - (x_size MOD 2)
o_y_size =  y_size + 1 - (y_size MOD 2)

odd_source_cube = CONGRID(source_map_spectrum.data,o_x_size,o_y_size,spec_size)




;;; Obtain psf assuming constant across FOV

psf_array = foxsi_get_psf_array(source_map_spectrum[0].xc,source_map_spectrum[0].yc, $
            source_map_spectrum[0].dx, source_map_spectrum[0].dy, x, y,        $
            x_size = o_x_size, y_size = o_y_size) 

psf_x_size = n_elements(reform(psf_array[*,0]))*1.0
psf_y_size = n_elements(reform(psf_array[0,*]))*1.0




;; Create Empty Array for putting in processed values

convolved_cube = odd_source_cube*0



;; Obtain effective_area energy profile using foxsi_get_effective_area function

eff_area = foxsi_get_effective_area()

;; Pull in eff_area tags as variables

energy_array = eff_area.energy_kev
eff_area_array = eff_area.eff_area_cm2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Interpolate the eff_area spectrum obtained above to obtain values
;; for the energy values of the input source spectrum.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


source_energy_range = findgen(spec_size)*spec_res+spec_min
energy_subscripts = DBLARR(N_ELEMENTS(source_energy_range))


;;; Interpolate to required accuracy (through iterations below)

energy_interpol = INTERPOL(energy_array,2*N_ELEMENTS(energy_array))
eff_interpol = INTERPOL(eff_area_array, 2*N_ELEMENTS(energy_array))

inaccurate1 = ''
inaccurate2 = ''
inaccurate3 = ''



;;;;; Loop searches for the points where the interpolated spectra
;;;;; approximately equal a source energy bin. If for some source
;;;;; energy value a nearby interpol value is not found then the loop
;;;;; is repeated with a higher degree of interpolation.

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
  
   ;;;;This accounts for the cases where we have many interpol values
   ;;;;near enough the source energy value. If they are spread either
   ;;;;side of source value then the mean is taken, if they are skewed
   ;;;;to one side of the source then the value closest to the source
   ;;;;value is taken.

   IF MIN(find2) LT 0 && MAX(find2) GT 0 THEN find = MEAN(find)
   IF MIN(find2) GT 0 && MAX(find2) GT 0 THEN find = find[0]
   IF MIN(find2) LT 0 && MAX(find2) LT 0 THEN find = find[WHERE(find eq MAX(find))]
  
  ;;;; An array of subscripts identifies the energy values in the
  ;;;; interpol which correspond to the energies of the source.

  energy_subscripts[k] = find 

ENDFOR

;;; If values were found for every source energy then an array of
;;; effective area values for each spectral slice is obtained from eff_interpol

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
    IF MIN(find2) GE 0 && MAX(find2) GT 0 THEN find = find[0]
    IF MIN(find2) LT 0 && MAX(find2) LE 0 THEN find = find[WHERE(find eq MAX(find))]
   
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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;; Each slice of the source cube is multiplied by the corresponding
;;;;; effective area value. This converts a flux to counts/s.

attenuated_source = odd_source_cube*TRANSPOSE(REBIN(eff_area_values,    $
                     N_ELEMENTS(eff_area_values), o_y_size, o_x_size))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; 08/31 -Improved convolution method takes only the pixels in the psf which
;;; overlap with the convolved image for a given FOV pixel. 
;;; Eliminates need to shift whole array and therefore the problem
;;; with wrapping.

;;; Each slice is convolved separately, this means larger FOVs very
;;; quickly become costly in computation time if there are many
;;; spectral positions in the source.

FOR j = 0.0, N_ELEMENTS(attenuated_source[0,0,*])-1 DO BEGIN

convolved_array = DBLARR(o_x_size,o_y_size)

PRINT, STRCOMPRESS('Convolving_spectral_slice_'+STRING(FIX(j+1))+       $
       '_of_'+STRING(spec_size),/REMOVE_AL)


    FOR i = 0.0, N_ELEMENTS(attenuated_source[*,*,0])-1 DO BEGIN

        x = (i MOD o_x_size)*1.0  
        y = (i - x)/o_x_size*1.0
       
	convolved_pixel = psf_array * attenuated_source[x,y,j]

	shifted_convolved_pixel = convolved_pixel[(psf_x_size/2-x):     $
        (psf_x_size/2-x+o_x_size-1), (psf_y_size/2 -y)                  $
        :(psf_y_size/2-y+o_y_size-1)]

        convolved_array = convolved_array + shifted_convolved_pixel

    ENDFOR

   
   convolved_cube[*,*,j] = convolved_array
 
ENDFOR

source_map_spectrum.data = CONGRID(odd_source_cube,x_size,y_size,spec_size)          $
                           *TOTAL(source_map_spectrum.data)/TOTAL(odd_source_cube)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;; Do rebinning due to detector pixelation;;;

rebin =  FREBIN(convolved_cube[*,*,0],x_size*source_map_spectrum[0].dx/pix_size,     $
         y_size*source_map_spectrum[0].dy/pix_size, /TOTAL)

rebinned_convolved_cube = DBLARR(N_ELEMENTS(rebin[*,0]), N_ELEMENTS(rebin[0,*]),     $
                          N_ELEMENTS(convolved_cube[0,0,*]))

renorm = 0

FOR layer = 0, N_ELEMENTS(convolved_cube[0,0,*])-1 DO BEGIN

   rebin = FREBIN(convolved_cube[*,*,layer],x_size*source_map_spectrum[0].dx/pix_size, $
           y_size*source_map_spectrum[0].dy/pix_size, /TOTAL)
   


   IF ABS(TOTAL(rebin) - TOTAL(convolved_cube[*,*,layer])) GT 0.0001  THEN BEGIN
   rebin =TOTAL(convolved_cube[*,*,layer])* (rebin)/TOTAL(rebin) 
   ;;;; Renormalise counts to assume lossless between optics and detector
   renorm = 1

   ENDIF

  

   rebinned_convolved_cube[*,*,layer] = rebin  

ENDFOR

 IF renorm EQ 1 THEN print, 'Rebinning loss detected, renormalising...'
;; Detect if FREBIN causes unacceptable loss of counts (e.g for non
;; integer pixelation ratio. If detected, total counts are
;; renormalised to correct (ideal) value.




;;; Makes and outputs maps of convolved,rebinned cube  with pixel size 
;;; equal to the value of the px keyword (default = 3'' per pixel)
;;; with the appended tags detailed in the preamble,

rebinned_cube_creator = $
 ADD_TAG(ADD_TAG(ADD_TAG(ADD_TAG(make_map(rebinned_convolved_cube[*,*,0], dx = pix_size,   $
 dy = pix_size, xc = source_map_spectrum.xc,yc = source_map_spectrum.yc, id = STRCOMPRESS( $
 'Rebinned_Convolved_Map_Pixel_Size:'+string(pix_size),/REMOVE_AL)),spec_min,'spec_min'),   $
spec_max,'spec_max'), spec_res,'spec_res'),0.0, 'Energy')

rebinned_convolved_maps = REPLICATE(rebinned_cube_creator,               $            
                          N_ELEMENTS(rebinned_convolved_cube[0,0,*]))

FOR rebin_layer = 0.0, N_ELEMENTS(rebinned_convolved_cube[0,0,*])-1 DO BEGIN

rebinned_convolved_maps[rebin_layer] = $
 ADD_TAG(ADD_TAG(ADD_TAG(ADD_TAG(make_map(rebinned_convolved_cube[*,*,rebin_layer],     $
 dx = pix_size, dy = pix_size, xc =source_map_spectrum.xc, yc = source_map_spectrum.yc, $
 id = STRCOMPRESS('Rebinned_Convolved_Map_Pixel_Size:' +string(pix_size),/REMOVE_AL)),  $
 spec_min,'spec_min'),spec_max,'spec_max'),spec_res,'spec_res'),spec_min +              $
 spec_res*rebin_layer, 'Energy')

ENDFOR



print,  'rebinned_convolved_maps returned'

RETURN, rebinned_convolved_maps

END
