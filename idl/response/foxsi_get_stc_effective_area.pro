;+
; NAME : foxsi_get_stc_effective_area
;
; PURPOSE : Returns the total FOXSI STC effective area.
;
; SYNTAX : eff_area = foxsi_get_stc_effective_area()
;
; INPUTS :
;           kind - choose 'Q' or 'F'
;
; Optional Inputs :
;           energy_arr - array of energies in keV to interpolate effective area
;                            onto.
;
; KEYWORDS :
;           plot - if true then plot to the screen
;
; RETURNS : struct
;               energy_keV - the energy in keV
;               eff_area_cm2 - the total effective area in cm^2
;
; EXAMPLES : None
;

FUNCTION foxsi_get_stc_effective_area, kind, ENERGY_ARR = energy_arr, PLOT = plot

    ; load the foxsi-smex common block
    COMMON foxsi_smex_vars, foxsi_root_path, foxsi_data_path, foxsi_name, $
        foxsi_optic_effarea, foxsi_number_of_modules, foxsi_shell_ids, $
        foxsi_shutters_thickness_mm, foxsi_detector_thickness_mm, foxsi_blanket_thickness_mm, $
        foxsi_stc_aperture_area_mm2, foxsi_stc_detector_material, foxsi_stc_detector_thickness_mm, $
        foxsi_stc_filter_material, foxsi_stc_filter_thickness_um

    IF keyword_set(energy_arr) THEN BEGIN
        optics_eff_area = foxsi_get_stc_optics_effective_area(kind, energy_arr = energy_arr)
    ENDIF ELSE BEGIN
        optics_eff_area = foxsi_get_stc_optics_effective_area(kind)
        energy_arr = optics_eff_area.energy_keV
    ENDELSE
    detector = foxsi_get_stc_detector_efficiency(energy_arr = energy_arr)
    filter = foxsi_get_stc_filter_transmission(energy_arr = energy_arr)

    eff_area_cm2 = optics_eff_area.eff_area_cm2 * detector.absorption * blanket.transmission

    IF keyword_set(PLOT) THEN BEGIN
        plot_title = foxsi_name
        plot, energy_arr, eff_area_cm2, xtitle = 'Energy [keV]', ytitle = 'Effective Area [cm!U2!N]', $
              /nodata, charsize = 1.5, title = plot_title
        oplot, energy_arr, eff_area_cm2, psym = -4
        oplot, energy_arr, eff_area_cm2_optic, psym = -5
        ssw_legend, ['Total', 'Module'], psym=[4,5]
    ENDIF
    result = create_struct("energy_keV", reform(energy_arr), "eff_area_cm2", eff_area_cm2)
    RETURN, result
END
