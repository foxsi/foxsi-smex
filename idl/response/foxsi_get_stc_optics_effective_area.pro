;+
; NAME : foxsi_get_stc_optics_effective_area
;
; PURPOSE : Returns the STC optics effective area in cm^2.
;
; SYNTAX : eff_area = foxsi_get_stc_optics_effective_area()
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

FUNCTION foxsi_get_stc_optics_effective_area, kind, ENERGY_ARR = energy_arr, PLOT = plot

    ; load the foxsi-smex common block
    COMMON foxsi_smex_vars, foxsi_root_path, foxsi_data_path, foxsi_name, $
        foxsi_optic_effarea, foxsi_number_of_modules, foxsi_shell_ids, $
        foxsi_shutters_thickness_mm, foxsi_detector_thickness_mm, foxsi_blanket_thickness_mm, $
        foxsi_stc_aperture_area_mm2, foxsi_stc_detector_material, foxsi_stc_detector_thickness_mm, $
        foxsi_stc_filter_material, foxsi_stc_filter_thickness_um


    energy_orig_kev = findgen(200) * 0.1
    CASE kind OF
       'Q': aperture_area_cm2 = foxsi_stc_aperture_area_mm2.q / 100.
       'F': aperture_area_cm2 = foxsi_stc_aperture_area_mm2.f / 100.
       ELSE: print, 'Invalid kind!'
    ENDCASE

    eff_area_data = replicate(aperture_area_cm2, n_elements(energy_orig_kev))

    IF keyword_set(energy_arr) THEN BEGIN
        eff_area_cm2 = interpol(eff_area_data, energy_orig_kev, energy_arr)
    ENDIF ELSE BEGIN
        energy_arr = energy_orig_kev
        eff_area_cm2 = eff_area_data
    ENDELSE

    IF keyword_set(PLOT) THEN BEGIN
        title = foxsi_name + ' STC-' + kind
        plot, energy_arr, eff_area_cm2, $
            xtitle = "Energy [keV]", ytitle = "Effective Area [cm!U2!N]", $
            charsize = 1.5, /xstyle, xrange = [min(energy_arr), max(energy_arr)], $
            title = title, /nodata

        oplot, energy_arr, eff_area_cm2, linestyle = 2
    ENDIF

    result = create_struct("energy_keV", energy_arr, $
                           "eff_area_cm2", eff_area_cm2)

	RETURN, result
END
