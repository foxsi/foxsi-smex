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
;     position - the position in the field of view (default is [0,0] On-axis)
;     configuration - the configuration of the optics
;               1 : 14 meters, 2 modules, 20 shells (2016/07/05, default)
;               2 : 14 meters, 1 module, 20 shells (2017/10/20)
;               3 : 14 meters, 2 modules, 15 shells (2017/10/20)
;               4 : 14 meters, 1 module, 15 shells (2017/10/20)
;    shells - the shells to include, overrides the default configuration.
;
; RETURNS : struct
;               energy_keV - the energy in keV
;               eff_area_cm2 - the total effective area provided by the FOXSI optics
;               eff_area_optic_cm2 - the effective area for a single telescope optic
;
; EXAMPLES : None
;

FUNCTION foxsi_get_optics_effective_area, ENERGY_ARR = energy_arr, PLOT = plot, $
    POSITION = position, SHELLS = shells, CONFIGURATION = configuration

    ; load the foxsi-smex common block
    COMMON foxsi_smex_vars, foxsi_root_path, foxsi_data_path, foxsi_name, $
    foxsi_optic_effarea, foxsi_number_of_modules, foxsi_shell_ids, $
    foxsi_shutters_thickness_mm, foxsi_detector_thickness_mm, foxsi_blanket_thickness_mm, $
    foxsi_stc_aperture_area_mm2, foxsi_stc_detector_material, foxsi_stc_detector_thickness_mm, $
    foxsi_stc_filter_material, foxsi_stc_filter_thickness_um

  DEFAULT, CONFIGURATION, 1
  DEFAULT, SHELLS, indgen(20)

  IF CONFIGURATION EQ 1 THEN foxsi_number_of_modules = 2
  IF CONFIGURATION EQ 2 THEN foxsi_number_of_modules = 1
  IF CONFIGURATION EQ 3 THEN BEGIN
    foxsi_number_of_modules = 2
    ; first 3 largest and 3 smallest shells are fabricated first for EM
    ; remove the 5 smallest shells after the required first 3
    ; schriste 23-Oct-2017
    shells = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 17, 18, 19]
  ENDIF
  IF CONFIGURATION EQ 4 THEN BEGIN
    ; first 3 largest and 3 smallest shells are fabricated first for EM
    ; remove the 5 smallest shells after the required first 3
    ; schriste 23-Oct-2017
    foxsi_number_of_modules = 1
    shells = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 17, 18, 19]
  ENDIF

<<<<<<< HEAD
    ; include loss of area due to optics mounting structure (spider)
    ; removed as already included in effective area
    ; eff_area_orig_cm2 = eff_area_orig_cm2 * 0.9
=======
  eff_area_data = foxsi_load_shell_effective_area()
  energy_orig_kev = eff_area_data.energy_kev
  eff_area_orig_cm2 = fltarr(n_elements(energy_orig_kev))
  FOR i = 0, n_elements(shells)-1 DO BEGIN
      eff_area_orig_cm2 += eff_area_data.eff_area_cm2[*, shells[i]]
  ENDFOR
  ; include loss of area due to optics mounting structure (spider)
  eff_area_orig_cm2 = eff_area_orig_cm2 * 0.9
>>>>>>> origin/master

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
