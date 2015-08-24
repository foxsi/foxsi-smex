;+
; NAME : get_foxsi_get_blanket_transmission
;
; PURPOSE : Returns the shutter transmission efficiency.
;
; SYNTAX : trans = get_foxsi_get_blanket_transmission()
;
; INPUTS : None
;
; Optional Inputs :
;			energy_arr - array of energies in keV to interpolate effective area
;                            onto.
;           thick - the thickness of the shutter in microns.
;
; KEYWORDS :
;			plot - if true then plot to the screen
;
; RETURNS : struct
;               energy_keV - the energy in keV
;               transmission - the transmission percentage
;
; EXAMPLES : None
;
FUNCTION get_foxsi_get_blanket_transmission, ENERGY_ARR = energy_arr, PLOT = plot

    ; load the foxsi-smex common block
    COMMON foxsi_smex_vars, foxsi_root_path, foxsi_data_path, foxsi_name, $
        foxsi_optic_effarea, foxsi_number_of_modules, foxsi_shell_ids, $
        foxsi_thick_shutter_thickness_mm, foxsi_thin_shutter_thickness_mm, $
        foxsi_detector_thickness_um

    IF NOT keyword_set(energy_arr) THEN energy_arr = findgen(60)

    result = foxsi_get_xray_transmission(energy_arr = energy_arr, 0, 'mylar')
    energy_arr = result.energy_keV

    IF keyword_set(PLOT) THEN BEGIN
        plot, energy_arr, result.transmission, xtitle = 'Energy [keV]', ytitle = 'Transmission', $
              /nodata, yrange = [0.0, 1.0], charsize = 1.5
        oplot, energy_arr, result.transmission, psym = -4
    ENDIF

    result = create_struct("energy_keV", energy_arr, "transmission", result.transmission)

    RETURN, result
END
