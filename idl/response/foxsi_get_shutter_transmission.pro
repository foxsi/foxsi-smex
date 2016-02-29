;+
; NAME : get_foxsi_get_shutter_transmission
;
; PURPOSE : Returns the shutter transmission efficiency.
;
; SYNTAX : trans = get_foxsi_get_shutter_transmission(shutter_state)
;
; INPUTS :
;           shutter_state -
;               0 no shutter
;               1 is thin shutter in
;               2 is thick shutter in
;
; Optional Inputs :
;			energy_arr - array of energies in keV to interpolate effective area
;                            onto.
;
; KEYWORDS :
;			plot - if true then plot to the screen
;			shutter_thick_mm - if set, then this value overrides the SHUTTER_STATE variable.
;
; RETURNS : struct
;               same as foxsi_get_xray_transmission
;
; EXAMPLES : None
;

FUNCTION foxsi_get_shutter_transmission, shutter_state, SHUTTER_THICK_MM = shutter_thick_mm, $
				 ENERGY_ARR = energy_arr, PLOT = plot

    COMMON foxsi_smex_vars, foxsi_root_path, foxsi_data_path, foxsi_name, $
        foxsi_optic_effarea, foxsi_number_of_modules, foxsi_shell_ids, $
        foxsi_shutters_thickness_mm, foxsi_detector_thickness_mm, foxsi_blanket_thickness_mm

    IF shutter_state GT n_elements(foxsi_shutters_thickness_mm)-1 THEN BEGIN
        print,'Unknown shutter state'
        RETURN, -1
    ENDIF

    thick_mm = foxsi_shutters_thickness_mm[shutter_state]
    
    ; If exact value is specified for shutter thickness, that overrides shutter_state.
    if keyword_set( SHUTTER_THICK_MM ) then thick_mm = shutter_thick_mm

    IF NOT keyword_set(energy_arr) THEN energy_arr = findgen(60)
    result = foxsi_get_xray_transmission(energy_arr = energy_arr, thick_mm, 'al', plot=plot)
    energy_keV = result.energy_keV

    RETURN, result
END
