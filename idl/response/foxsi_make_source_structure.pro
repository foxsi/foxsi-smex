;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; FUNCTION: "foxsi_make_source_structure"
;;;
;;; HISTORY: Initial Commit - 09/08/15 - Samuel Badman
;;;
;;; DESCRIPTION: Takes user inputted source map cube and spectral
;;; min and max and converts this to the required
;;; structure for the function
;;; foxsi_get_output_image_cube.
;;;
;;; CALL SEQUENCE: source_map_spectrum = $
;;; foxsi_make_source_structure('input_map_cube', $
;;; 'lower_energy_bound','upper energy bound')
;;;
;;; COMMENTS: lower and upper energy bounds are the lowest energy
;;; value in the lowest energy bin and the highest energy in the
;;; highest energy bin respectively
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FUNCTION foxsi_make_source_structure, source_map_spectrum, bin_min, bin_max

spec_size = N_ELEMENTS(source_map_spectrum.data[0,0,*])

source_data_cube = source_map_spectrum

source_cube_creator = ADD_TAG(ADD_TAG(source_map_spectrum[0], 0.0, $
                               'energy_bin_lower_bound_keV') ,0.0, $
                               'energy_bin_upper_bound_kev')

source_map_spectrum = REPLICATE(source_cube_creator, spec_size)

energy_spacings = FINDGEN(spec_size+1)*(bin_max - bin_min)/spec_size

lower_bound_array = energy_spacings[0:spec_size-1] + bin_min

upper_bound_array = energy_spacings[1:*] + bin_min

FOR i = 0, spec_size - 1 DO BEGIN

   ;;; Adding tags to the structure to keep track of min/max energy of
   ;;; each spectral bin
   source_map = ADD_TAG(source_data_cube[i], lower_bound_array[i],'energy_bin_lower_bound_keV')
   source_map = ADD_TAG(source_map, upper_bound_array[i],'energy_bin_upper_bound_keV')
   source_map_spectrum[i] = source_map

ENDFOR

RETURN, source_map_spectrum
END
