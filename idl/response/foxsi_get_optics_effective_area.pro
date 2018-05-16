;+
; NAME : foxsi_get_optics_effective_area
;
; PURPOSE : Returns the optics effective area in cm^2.
;
; SYNTAX : eff_area = foxsi_get_optics_effective_area()
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
;           configuration - the configuration of the optics
;               1 : 14 meters, 2 modules, 20 shells (2016/07/05)
;
; RETURNS : struct
;               energy_keV - the energy in keV
;               eff_area_cm2 - the total effective area provided by the FOXSI optics
;               eff_area_optic_cm2 - the effective area for a single telescope optic
;
; EXAMPLES : None
;

FUNCTION foxsi_get_optics_effective_area, ENERGY_ARR = energy_arr, PLOT = plot, $
    POSITION = position

    ; load the foxsi-smex common block
    COMMON foxsi_smex_vars, foxsi_root_path, foxsi_data_path, foxsi_name, $
    foxsi_optic_effarea, foxsi_number_of_modules, foxsi_shell_ids, $
    foxsi_shutters_thickness_mm, foxsi_detector_thickness_mm, foxsi_blanket_thickness_mm, $
    foxsi_stc_aperture_area_mm2, foxsi_stc_detector_material, foxsi_stc_detector_thickness_mm, $
    foxsi_stc_filter_material, foxsi_stc_filter_thickness_um

	eff_area_data = foxsi_load_optics_effective_area()
    energy_orig_kev = eff_area_data.energy_kev
    eff_area_orig_cm2 = fltarr(n_elements(energy_orig_kev))


    eff_area_orig_cm2 = eff_area_data.eff_area_cm2_1
    foxsi_number_of_modules = 2
  

    ; add up all of the areas for each of the included optics shells
    ;FOR i = 0, n_elements(foxsi_shell_ids)-1 DO BEGIN
    ;    eff_area_orig_cm2 += data[foxsi_shell_ids[i]-1, *]
    ;ENDFOR

    ; include loss of area due to optics mounting structure (spider)
    ; removed as already included in effective area
    ; eff_area_orig_cm2 = eff_area_orig_cm2 * 0.9

	IF keyword_set(energy_arr) THEN BEGIN
	    eff_area_cm2 = interpol(eff_area_orig_cm2, energy_orig_kev, energy_arr)
	ENDIF ELSE BEGIN
		energy_arr = energy_orig_kev
		eff_area_cm2 = eff_area_orig_cm2
	ENDELSE

	IF keyword_set(PLOT) THEN BEGIN
		title = foxsi_name
		plot, energy_arr, foxsi_number_of_modules * eff_area_cm2, $
			xtitle = "Energy [keV]", ytitle = "Effective Area [cm!U2!N]", $
			charsize = 1.5, /xstyle, xrange = [min(energy_arr), max(energy_arr)], $
			title = title, /nodata

		oplot, energy_arr, foxsi_number_of_modules * eff_area_cm2, linestyle = 2
		oplot, energy_arr, eff_area_cm2, linestyle = 1
        ssw_legend, ['Total', 'Optic'], linestyle = [2, 1]
	ENDIF

	result = create_struct("energy_keV", energy_arr, $
                           "eff_area_cm2", eff_area_cm2 * foxsi_number_of_modules, $
                           "eff_area_optic_cm2", eff_area_cm2)

	RETURN, result
END
