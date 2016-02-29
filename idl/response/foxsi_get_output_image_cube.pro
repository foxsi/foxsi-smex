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
;;;               oversample_psf - degree of oversampling to produce a more
;;;                                accurate PSF. Default is 1 (no oversampling)
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
                                      no_count_stats = no_count_stats,              $
                                      oversample_psf = oversample_psf

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
RESOLVE_ROUTINE, 'foxsi_get_output_2d_image', /IS_FUNCTION
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

spec_size   = N_ELEMENTS(source_map_spectrum)
upper_array = source_map_spectrum.energy_bin_upper_bound_keV
lower_array = source_map_spectrum.energy_bin_lower_bound_keV
spec_res    = upper_array[0] - lower_array[0]

; Only print spectral resolution if constant energy binning is used.
if array_mode eq 0 then print, "Spectral Resolution (keV/Energy_Bin) ="+string(spec_res)


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

		; If we've gone above the energy range of the FOXSI response, then stop.
		if source_energy_range[k] gt max( energy_interpol ) then break

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


for layer = 0, n_elements(source_map_spectrum) - 1 do begin

	print, 'Processing map ', lower_array[layer], upper_array[layer], ' keV'

  ; Convert the source map from photons to counts
  this_map = source_map_spectrum[layer]
  this_map.data *= eff_area_values[layer]

  ; Generate the convolved image, with noise if desired
  this_map = foxsi_get_output_2d_image(source_map=this_map, /quiet, $
                                       px=pix_size, no_count_stats=no_count_stats, oversample_psf=oversample_psf)

	; Add energy info to map ID
	this_map.id += ' '+strtrim( average( [lower_array[layer],upper_array[layer]] ), 2)+' keV

  ; Append the new map to the output map cube
  this_map = add_tag(this_map, lower_array[layer], 'energy_bin_lower_bound_keV')
  this_map = add_tag(this_map, upper_array[layer], 'energy_bin_upper_bound_keV')
  output_map_cube = append_arr(output_map_cube, this_map, /no_copy)
endfor

RETURN, output_map_cube

END
