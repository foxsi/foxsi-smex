;+
; NAME : foxsi_get_stc_filter_transmission
;
; PURPOSE : Returns the shutter transmission efficiency.
;
; SYNTAX : trans = get_foxsi_stc_blanket_transmission('Q')
;
; INPUTS : None
;
; Optional Inputs :
;           energy_arr - array of energies in keV to interpolate effective area
;                            onto.
;           thick - the thickness of the shutter in microns.
;
; KEYWORDS :
;           plot - if true then plot to the screen
;
; RETURNS : struct
;               energy_keV - the energy in keV
;               transmission - the transmission percentage
;
; EXAMPLES : None
;
FUNCTION foxsi_get_stc_filter_transmission, kind, ENERGY_ARR = energy_arr, PLOT = plot

    ; load the foxsi-smex common block
        COMMON foxsi_smex_vars, foxsi_root_path, foxsi_data_path, foxsi_name, $
        foxsi_optic_effarea, foxsi_number_of_modules, foxsi_shell_ids, $
        foxsi_shutters_thickness_mm, foxsi_detector_thickness_mm, foxsi_blanket_thickness_mm, $
        foxsi_stc_aperture_area_mm2, foxsi_stc_detector_material, foxsi_stc_detector_thickness_mm, $
        foxsi_stc_filter_material, foxsi_stc_filter_thickness_um

    IF NOT keyword_set(energy_arr) THEN energy_keV = findgen(60) ELSE $
        energy_keV = energy_arr

    CASE kind OF:
        Q: filter_thickness = foxsi_stc_filter_thickness_um.q
        F: filter_thickness = foxsi_stc_filter_thickness_um.f
        ELSE: print, 'Invalid kind! Kind must be Q or F.'
    ENDCASE

    result = foxsi_get_xray_transmission(energy_arr = energy_arr, $
                                         filter_thickness, $
                                         foxsi_stc_filter_material, plot=plot)
    RETURN, result
END
