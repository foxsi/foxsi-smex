;+
; NAME : foxsi_get_detector_efficiency
;
; PURPOSE : Returns the detector efficiency as a percent.
;
; SYNTAX : det_eff = get_foxsi_detector_efficiency()
;
; INPUTS : None
;
; Optional Inputs :
;			energy_arr - array of energies in keV to interpolate effective area
;                            onto.
;           det_thick - the thickness of the detector in microns.
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

FUNCTION foxsi_get_detector_efficiency, ENERGY_ARR = energy_arr, PLOT = plot

    ; load the foxsi-smex common block
    COMMON foxsi_smex_vars, foxsi_root_path, foxsi_data_path, foxsi_name, $
        foxsi_optic_effarea, foxsi_number_of_modules, foxsi_shell_ids, $
        foxsi_thick_shutter_thickness_mm, foxsi_thin_shutter_thickness_mm, $
        foxsi_detector_thickness_um

    IF NOT keyword_set(energy_arr) THEN energy_arr = findgen(60)

    result = foxsi_get_xray_transmission(energy_arr = energy_arr, $
                                         foxsi_detector_thickness_um, 'cdte')

    IF keyword_set(PLOT) THEN BEGIN
        plot, energy_arr, result.efficiency, xtitle = 'Energy [keV]', ytitle = 'Detector Efficiency', $
              /nodata, yrange = [0.0, 1.0], charsize = 1.5
        oplot, energy_arr, result.efficiency, psym = -4
    ENDIF

    result = create_struct("energy_keV", energy_arr, "efficiency", result.efficiency)

    RETURN, result
END
