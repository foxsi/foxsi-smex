;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;FUNCTION:      "foxsi_get_output_image_cube"
;;;
;;;HISTORY:       Initial Commit - 08/25/15 - Samuel Badman
;;;               Improved Convolution Method - 08/31/15 - Samuel Badman               
;;;
;;;DESCRIPTION:   Function which takes a simulated event (an array of
;;;               flux maps at different energy values) and obtains a
;;;               simulation of the image FOXSI would observe from
;;;               this event.
;;;               Each flux map is converted to counts through
;;;               multiplication by an effective area obtained from
;;;               foxsi_get_eff_area.pro as a function of the energy
;;;               of the midpoint of each flux map's energy range. 
;;;               These count maps are then convolved with a point
;;;               spread function obtained through calling the
;;;               function get_psf_array with arguments specifying the
;;;               solar coordinates of the image sensor. After
;;;               convolution, the new image is rebinned according to
;;;               the keyword px = pix_size (default = 3) to reflect
;;;               the loss of resolution due to the finite strip size
;;;               in the detectors. Finally, counting statistics are
;;;               accounted for by randomising each pixel's
;;;               value through random selection from  a poisson
;;;               distribution about a mean given by the pixel's original value.
;;;               The output is a structure containing imaged maps at
;;;               the inputted energy with appended tags specifying
;;;               the energy bin range for each map. 
;;;
;;;CALL SEQUENCE: output_map_cube  = foxsi_get_output_image_cube()
;;;
;;;
;;;KEYWORDS:      source_map_spectrum  = "source_map_spectrum". User
;;;               inputted source image array, if blank, default 
;;;               generated from get_source_map_spectrum.pro
;;;               function
;;;               
;;;               e_min = 'The value of the lower bound of
;;;                         the lowest energy bin in the user- 
;;;                         provided spectrum in keV'
;;;
;;;               e_max = 'The value of the upper bound of
;;;                         the lowest energy bin in the user- 
;;;                         provided spectrum in keV'
;;;               
;;;               bin_edges_array = 'Array of all the energy bin edges in the cube'
;;;
;;;               px = "pixel size of detector" in arcseconds, default is 3
;;;
;;;               no_count_stats - if set, counting statistics ignored
;;;
;;;COMMENTS:      -Runtime scales badly with FOV size
;;;               -The default spatial dimensions are set to 
;;;                [100,100] ~1.66' X 1.66' FOV at 1 arcsec per
;;;               pixel, this takes ~0.5s per energy slice.
;;;               -For your source, note the effective area is not
;;;               defined below 1KeV or above ~60KeV. 
;;;               -The user must provide either a max and min energy
;;;               value fo the whole cube if it has evenly spaced
;;;               energy bins or an array specfying the bin edges in
;;;               ascending order. This array must therefore be of
;;;               dimension n + 1 where n is the number of energy
;;;               slices in the image cube.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FUNCTION foxsi_get_output_image_cube, source_map_spectrum = source_map_spectrum,    $
                                      e_min = e_min, e_max = e_max, px =  pix_size, $
                                      bin_edges_array = bin_edges_array,            $
                                      no_count_stats = no_count_stats

upper_lower_bound_mode = 0
array_mode = 0

;;; Logic to check the user input is in the correct format

IF N_ELEMENTS(source_map_spectrum) EQ 0 THEN PRINT, 'Using default source' ELSE BEGIN
  
   IF N_ELEMENTS(bin_edges_array) EQ 0 THEN BEGIN
            
            upper_lower_bound_mode = 1

            PRINT, 'No user supplied bin energy bound arrays detected,' $
                   +' presuming evenly spaced energy bins...'            

            IF N_ELEMENTS(e_min) EQ 0 && N_ELEMENTS(e_max) EQ 0 THEN BEGIN
               
               PRINT, 'No energy axis upper and lower bounds detected,' $
                      +' using defaults (e_min = 1keV, e_max = 60keV)'

            ENDIF ELSE IF N_ELEMENTS(e_min) EQ 0 OR N_ELEMENTS(e_max) EQ 0 THEN BEGIN

                          PRINT, 'One of the energy bounds is missing,' $
                                 +'please try again with both supplied'

                          STOP

                       ENDIF
                    
    ENDIF ELSE array_mode = 1
 
ENDELSE


;;;;; Check for updates to peripheral functions for the purposes of testing
RESOLVE_ROUTINE, 'foxsi_get_psf_array', /IS_FUNCTION
RESOLVE_ROUTINE, 'foxsi_get_default_source_cube', /IS_FUNCTION
RESOLVE_ROUTINE, 'foxsi_get_effective_area', /IS_FUNCTION
RESOLVE_ROUTINE, 'foxsi_make_source_structure', /IS_FUNCTION


;;;If source_map_cube provided, create structure with spectral information
;;;for each slice. If no source_map_cube provided then use default.

;;;;; Define default minimum energy and maximum energy as 1 keV and 60
;;;;; keV respectively (i.e. utilise full range of effective area)
DEFAULT, e_min, 1.0
DEFAULT, e_max, 60.0

IF KEYWORD_SET(source_map_spectrum) EQ 1 THEN BEGIN
   IF upper_lower_bound_mode EQ 1  THEN source_map_spectrum =                              $
                                          foxsi_make_source_structure(source_map_spectrum, $
                                          e_min = e_min, e_max = e_max)

   IF array_mode EQ 1  THEN source_map_spectrum =   $
                 foxsi_make_source_structure(source_map_spectrum, arr = bin_edges_array)

ENDIF ELSE  source_map_spectrum = foxsi_get_default_source_cube()

;;;;; Define default detector resolution to 3 arcsecs per pixel
DEFAULT, pix_size, 3

;;;; Pull spectral information from input source structure array.

spec_size   = N_ELEMENTS(source_map_spectrum.data[0,0,*])
upper_array = source_map_spectrum.energy_bin_upper_bound_keV
lower_array = source_map_spectrum.energy_bin_lower_bound_keV
spec_res    = upper_array[0] - lower_array[0]

print, "Spectral Resolution (keV/Energy_Bin) ="+string(spec_res)

;; Redundant FOV coordinates required as arguments for get_psf_array
x=0 
y=0

 ;;; Get dimensions of FOV in pixels
dims   = SIZE(source_map_spectrum[0].data, /DIM)
x_size = dims[0]*1.0
y_size = dims[1]*1.0

print, strcompress('Source_FOV_is_'+STRING(FIX(dims[0])) +'x'  $
       + STRING(FIX(dims[1]))+'_Pixels', /REMOVE_AL)


;;; Interpolate source to achieve odd dimensions for the purpose
;;; of accurate convolution

o_x_size =  x_size + 1 - (x_size MOD 2)
o_y_size =  y_size + 1 - (y_size MOD 2)

odd_source_cube = CONGRID(source_map_spectrum.data,o_x_size,o_y_size,spec_size)

;;; Obtain psf assuming constant across FOV

psf_array = foxsi_get_psf_array(source_map_spectrum[0].xc,source_map_spectrum[0].yc, $
            source_map_spectrum[0].dx, source_map_spectrum[0].dy, x, y,        $
            x_size = o_x_size, y_size = o_y_size) 

psf_dims   = SIZE(psf_array,/DIM)
psf_x_size = psf_dims[0]*1.0
psf_y_size = psf_dims[1]*1.0


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


source_energy_range = (upper_array + lower_array)/2 
energy_subscripts   = DBLARR(N_ELEMENTS(source_energy_range))


;;; Interpolate to required accuracy (through iterations below)

energy_interpol = INTERPOL(energy_array,2*N_ELEMENTS(energy_array))
eff_interpol    = INTERPOL(eff_area_array, 2*N_ELEMENTS(energy_array))

inaccurate1 = 0
inaccurate2 = 0
inaccurate3 = 0

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
       inaccurate1 = 1
       BREAK
       ENDIF
    ENDIF  
  
   ;;;;This accounts for the cases where we have many interpol values
   ;;;;near enough the source energy value. If they are spread either
   ;;;;side of source value then the mean is taken, if they are skewed
   ;;;;to one side of the source then the value closest to the source
   ;;;;value is taken.

   IF MIN(find2) LT 0 && MAX(find2) GT 0 THEN find = MEAN(find)
   IF MIN(find2) GE 0 && MAX(find2) GT 0 THEN find = find[0]
   IF MIN(find2) LT 0 && MAX(find2) LE 0 THEN find = find[WHERE(find eq MAX(find))]
  
  ;;;; An array of subscripts identifies the energy values in the
  ;;;; interpol which correspond to the energies of the source.

  energy_subscripts[k] = find 

ENDFOR

;;; If values were found for every source energy then an array of
;;; effective area values for each spectral slice is obtained from eff_interpol

IF inaccurate1 EQ 0 THEN eff_area_values = eff_interpol[energy_subscripts]


IF inaccurate1 EQ 1 THEN BEGIN
 
  energy_interpol = INTERPOL(energy_array,3*N_ELEMENTS(energy_array))
  eff_interpol = INTERPOL(eff_area_array, 3*N_ELEMENTS(energy_array))

  FOR k = 0.0, N_ELEMENTS(source_energy_range)-1 DO BEGIN
    
    arg = energy_interpol - source_energy_range[k]
    find = WHERE(ABS(arg) LT 0.100)
    find2 = arg[ WHERE(arg LT 0.100)]
    IF N_ELEMENTS(find) EQ 1 THEN BEGIN
       IF find eq -1 THEN BEGIN
       inaccurate2 = 1
       BREAK
       ENDIF
    ENDIF  
 
    IF MIN(find2) LT 0 && MAX(find2) GT 0 THEN find = MEAN(find)
    IF MIN(find2) GE 0 && MAX(find2) GT 0 THEN find = find[0]
    IF MIN(find2) LT 0 && MAX(find2) LE 0 THEN find = find[WHERE(find eq MAX(find))]
    
    energy_subscripts[k] = find

  ENDFOR
  
  IF inaccurate2 EQ 0 THEN eff_area_values = eff_interpol[energy_subscripts]  

ENDIF

IF inaccurate2 EQ 1 THEN BEGIN
 
  energy_interpol = INTERPOL(energy_array,4*N_ELEMENTS(energy_array))
  eff_interpol = INTERPOL(eff_area_array, 4*N_ELEMENTS(energy_array))  

  FOR k = 0.0, N_ELEMENTS(source_energy_range)-1 DO BEGIN

    arg = energy_interpol - source_energy_range[k]
    find = WHERE(ABS(arg) LT 0.100)
    find2 = arg[WHERE(arg LT 0.100)]
    IF N_ELEMENTS(find) EQ 1 THEN BEGIN
       IF find eq -1 THEN BEGIN
       inaccurate3 = 1
       BREAK
       ENDIF
    ENDIF  
  
    IF MIN(find2) LT 0 && MAX(find2) GT 0 THEN find = MEAN(find)
    IF MIN(find2) GE 0 && MAX(find2) GT 0 THEN find = find[0]
    IF MIN(find2) LT 0 && MAX(find2) LE 0 THEN find = find[WHERE(find eq MAX(find))]
    
    energy_subscripts[k] = find

  ENDFOR

  IF inaccurate3 EQ 0  THEN eff_area_values = eff_interpol[energy_subscripts]
  IF inaccurate3 EQ 1  THEN print, 'probably need to try a different method'
ENDIF


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;; Each slice of the source cube is multiplied by the corresponding
;;;;; effective area value. This converts a flux to counts/s.

attenuated_source = odd_source_cube*TRANSPOSE(REBIN(eff_area_values,    $
                     N_ELEMENTS(eff_area_values), o_y_size, o_x_size))

array_dims        = SIZE(attenuated_source, /DIM)
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

     FOR y = 0.0, array_dims[1] - 1 DO BEGIN

        FOR x = 0.0, array_dims[0] - 1 DO BEGIN

	    convolved_pixel = psf_array * attenuated_source[x,y,j]

	    shifted_convolved_pixel = convolved_pixel[(psf_x_size/2-x):     $
            (psf_x_size/2-x+o_x_size-1), (psf_y_size/2 -y)                  $
            :(psf_y_size/2-y+o_y_size-1)]

            convolved_array = convolved_array + shifted_convolved_pixel
        
         ENDFOR

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

rebinned_cube_creator = ADD_TAG(ADD_TAG(make_map(rebinned_convolved_cube[*,*,0], dx =         $
                        pix_size, dy = pix_size, xc = source_map_spectrum.xc, yc =            $
                        source_map_spectrum.yc, id = STRCOMPRESS(                             $
                        'Rebinned_Convolved_Map_Pixel_Size:'+string(pix_size),/REMOVE_AL)),   $
                        0.0, 'energy_bin_lower_bound_keV'), 0.0,'energy_bin_upper_bound_kev')

output_map_cube = REPLICATE(rebinned_cube_creator,             $            
                  N_ELEMENTS(rebinned_convolved_cube[0,0,*]))

FOR rebin_layer = 0.0, N_ELEMENTS(rebinned_convolved_cube[0,0,*])-1 DO BEGIN

    rebinned_convolved_slice = MAKE_MAP(rebinned_convolved_cube[*,*,rebin_layer], dx =    $
                               pix_size, dy = pix_size, xc =source_map_spectrum.xc, yc =  $
                               source_map_spectrum.yc, id = STRCOMPRESS(                  $
                              'Image_at_Energy_' +string(lower_array[rebin_layer])+ '-' + $
                              string(upper_array[rebin_layer])+'keV',/REMOVE_AL))

    rebinned_convolved_slice = ADD_TAG(rebinned_convolved_slice, lower_array[rebin_layer]$
                               , 'energy_bin_lower_bound_keV')

    rebinned_convolved_slice = ADD_TAG(rebinned_convolved_slice, upper_array[rebin_layer]$
                               , 'energy_bin_upper_bound_keV')

    output_map_cube[rebin_layer] = rebinned_convolved_slice


 ENDFOR

output_dims = SIZE(output_map_cube.data, /DIM)

;;;; Add noise due to counting statistics for each pixel ;;;;;

IF KEYWORD_SET(no_count_stats) NE 1 THEN BEGIN
   FOR x = 0, output_dims[0] - 1 DO BEGIN
      FOR y = 0, output_dims[1] - 1 DO BEGIN
         FOR z = 0, output_dims[2] - 1 DO BEGIN
          mean = output_map_cube[z].data[x,y]
             IF mean NE 0.0 THEN BEGIN 
                  noisy_value = RANDOMU(seed, 1, POISSON = mean)
                  output_map_cube[z].data[x,y] = noisy_value
               ENDIF         
          ENDFOR
      ENDFOR
   ENDFOR
ENDIF
print,  'output_map_cube returned'

RETURN, output_map_cube

END
