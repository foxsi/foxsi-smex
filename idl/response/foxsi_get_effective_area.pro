;+
; NAME : foxsi_get_effective_area
;
; PURPOSE : Returns the total FOXSI effective area.
;
; SYNTAX : det_eff = foxsi_get_effective_area()
;
; INPUTS : None
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

FUNCTION foxsi_get_effective_area, ENERGY_ARR = energy_arr, PLOT = plot, $
    SHUTTER_STATE = shutter_state

    COMMON foxsi_smex_vars, foxsi_root_path, foxsi_data_path, foxsi_name, $
        foxsi_optic_effarea, foxsi_number_of_modules, foxsi_shell_ids, $
        foxsi_thick_shutter_thickness_mm, foxsi_thin_shutter_thickness_mm, $
        foxsi_detector_thickness_um

    default, shutter_state, 0


    optics_eff_area = foxsi_get_optics_effective_area()
    energy_arr = optics_eff_area.energy_keV
    detector = foxsi_get_detector_efficiency(energy_arr = energy_arr)
    blanket = foxsi_get_blanket_transmission(energy_arr = energy_arr)

    eff_area = optics_eff_area.eff_area_cm2 * detector.efficiency * blanket.transmission
    IF shutter_state NE 0 THEN BEGIN
        shutter = get_foxsi_get_shutter_transmission(energy_arr = energy_arr)
        eff_area = optics_eff_area.eff_area * shutter.transmission
    ENDIF

    IF keyword_set(PLOT) THEN BEGIN
        plot, energy_arr, eff_area, xtitle = 'Energy [keV]', ytitle = 'Detector Efficiency', $
              /nodata, yrange = [0.0, 1.0], charsize = 1.5
        oplot, eff_area, eff_area, psym = -4
    ENDIF

    result = create_struct("energy_keV", energy_arr, "eff_area_cm2", eff_area)

    RETURN, result
END
