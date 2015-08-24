;+
; NAME : get_foxsi_get_shutter_transmission
;
; PURPOSE : Returns the shutter transmission efficiency.
;
; SYNTAX : trans = get_foxsi_get_shutter_transmission()
;
; INPUTS :
;           shutter_state -
;               1 is thin shutter in
;               2 is thick shutter in
;
; Optional Inputs :
;			energy_arr - array of energies in keV to interpolate effective area
;                            onto.
;
; KEYWORDS :
;			plot - if true then plot to the screen
;
; RETURNS : struct
;               energy_keV - the energy in keV
;               efficiency - the detector efficiency
;
; EXAMPLES : None
;

FUNCTION get_foxsi_get_shutter_transmission, shutter_state, ENERGY_ARR = energy_arr, PLOT = plot

    COMMON foxsi_smex_vars, foxsi_root_path, foxsi_data_path, foxsi_name, $
        foxsi_optic_effarea, foxsi_number_of_modules, foxsi_shell_ids, $
        foxsi_thick_shutter_thickness_mm, foxsi_thin_shutter_thickness_mm, $
        foxsi_detector_thickness_um

    IF NOT keyword_set(energy_arr) THEN energy_arr = findgen(60)

    switch shutter_state OF
        0: thick_um = 0
        1: thick_um = foxsi_thin_shutter_thickness_mm
        2: thick_um = foxsi_thick_shutter_thickness_mm
        ELSE print('Unknown shutter state')
    endswitch

    IF shutter_state EQ 1 THEN $
        result = foxsi_get_xray_transmission(energy_arr = energy_arr, thick_um, 'be')

    energy_arr = result.energy_keV

    IF keyword_set(PLOT) THEN BEGIN
        plot, energy_arr, result.transmission, xtitle = 'Energy [keV]', ytitle = 'Transmission', $
              /nodata, yrange = [0.0, 1.0], charsize = 1.5
        oplot, energy_arr, result.transmission, psym = -4
    ENDIF

    result = create_struct("energy_keV", energy_arr, "transmission", result.transmission)

    RETURN, result
END
