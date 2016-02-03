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
;           position - the position in the field of view (default is [0,0] On-axis)
;
; RETURNS : struct
;               energy_keV - the energy in keV
;               eff_area_cm2 - the total effective area in cm^2
;               eff_area_optic_cm2 - the effective area for a single telescope in cm^2
;
; EXAMPLES : None
;

FUNCTION foxsi_get_effective_area, ENERGY_ARR = energy_arr, PLOT = plot, $
    SHUTTER_STATE = shutter_state, SHUTTER_THICK_MM = shutter_thick_mm, POSITION=position

    default, shutter_state, 0
    default, position, [0, 0]

    COMMON foxsi_smex_vars, foxsi_root_path, foxsi_data_path, foxsi_name, $
        foxsi_optic_effarea, foxsi_number_of_modules, foxsi_shell_ids, $
        foxsi_shutters_thickness_mm, foxsi_detector_thickness_mm, foxsi_blanket_thickness_mm

    IF keyword_set(energy_arr) THEN BEGIN
        optics_eff_area = foxsi_get_optics_effective_area(energy_arr = energy_arr, position=position)
    ENDIF ELSE BEGIN
        optics_eff_area = foxsi_get_optics_effective_area()
        energy_arr = optics_eff_area.energy_keV
    ENDELSE
    detector = foxsi_get_detector_efficiency(energy_arr = energy_arr)
    blanket = foxsi_get_blanket_transmission(energy_arr = energy_arr)
    shutter = foxsi_get_shutter_transmission(shutter_state, energy_arr = energy_arr, $
    																				 shutter_thick_mm = shutter_thick_mm, _extra=_extra)

    eff_area_cm2 = optics_eff_area.eff_area_cm2 * detector.absorption * blanket.transmission * shutter.transmission
    eff_area_cm2_optic = optics_eff_area.eff_area_optic_cm2 * detector.absorption * blanket.transmission * shutter.transmission

    IF keyword_set(PLOT) THEN BEGIN
        plot_title = foxsi_name
        plot, energy_arr, eff_area_cm2, xtitle = 'Energy [keV]', ytitle = 'Effective Area [cm!U2!N]', $
              /nodata, charsize = 1.5, title = plot_title
        oplot, energy_arr, eff_area_cm2, psym = -4
        oplot, energy_arr, eff_area_cm2_optic, psym = -5
        ssw_legend, ['Total', 'Module'], psym=[4,5]
    ENDIF
    result = create_struct("energy_keV", reform(energy_arr), "eff_area_cm2", eff_area_cm2, "eff_area_optic_cm2", eff_area_cm2_optic)
    RETURN, result
END
