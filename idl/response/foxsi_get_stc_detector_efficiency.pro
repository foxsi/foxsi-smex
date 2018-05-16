;+
; NAME : foxsi_get_stc_detector_efficiency
;
; PURPOSE : Returns the STC detector efficiency as a fraction (0-1).
;
; SYNTAX : det_eff = get_foxsi_stc_detector_efficiency()
;
; INPUTS : None
;
; Optional Inputs :
;           energy_arr - array of energies in keV to interpolate effective area
;                            onto.
;           det_thick - the thickness of the detector in microns.
;
; KEYWORDS :
;           plot - if true then plot to the screen
;
; RETURNS : struct
;               energy_keV - the energy in keV
;               efficiency - the detector efficiency
;
; EXAMPLES : None
;

FUNCTION foxsi_get_stc_detector_efficiency, ENERGY_ARR = energy_arr, PLOT = plot

    COMMON foxsi_smex_vars, foxsi_root_path, foxsi_data_path, foxsi_name, $
        foxsi_optic_effarea, foxsi_number_of_modules, foxsi_shell_ids, $
        foxsi_shutters_thickness_mm, foxsi_detector_thickness_mm, foxsi_blanket_thickness_mm, $
        foxsi_stc_aperture_area_mm2, foxsi_stc_detector_material, foxsi_stc_detector_thickness_mm, $
        foxsi_stc_filter_material, foxsi_stc_filter_thickness_um


    IF NOT keyword_set(energy_arr) THEN energy_keV = findgen(60) ELSE $
        energy_keV = energy_arr

    result = foxsi_get_xray_transmission(energy_arr = energy_arr, $
                                             foxsi_stc_detector_thickness_mm, $
                                             foxsi_stc_detector_material, $
                                             plot=plot)
    RETURN, result
END
