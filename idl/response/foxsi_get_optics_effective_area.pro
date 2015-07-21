;+
; NAME : foxsi_get_optics_effective_area
;
; PURPOSE : Returns the optics effective area..
;
; SYNTAX : eff_area = foxsi_get_optics_effective_area()
;
; INPUTS : None
;
; Optional Inputs :
;			energy_arr - array of energies
;
; KEYWORDS :
;			plot - if true then plot to the screen
;
; RETURNS : struct
;
; EXAMPLES : None
;

FUNCTION foxsi_get_optics_effective_area, ENERGY_ARR = energy_arr, PLOT = plot

	; load the foxsi-smex common block
    COMMON foxsi_smex_vars, foxsi_root_path, foxsi_data_dir, foxsi_name, foxsi_optic_effarea, foxsi_number_of_modules

	eff_area = foxsi_load_optics_effective_area()

	energy = eff_area.field01
    eff_area = 1

    data = create_struct('energy', energy, 'eff_area_cm2', eff_area)
	energy = result.energy

	; dummy values
	eff_area = replicate(1, n_elements(energy))

	IF keyword_set(energy_arr) THEN BEGIN
	    eff_area_orig = interpol(eff_area, energy, energy_arr)
	    eff_area = eff_area_orig
	ENDIF ELSE BEGIN
		energy_arr = energy
		eff_area_orig = eff_area
	ENDELSE

	IF keyword_set(PLOT) THEN BEGIN

		title = foxsi_name
		plot, energy_arr, foxsi_number_of_modules * eff_area_orig, psym = -4, $
			xtitle = "Energy [keV]", ytitle = "Effective Area [cm!U2!N]", $
			charsize = 1.5, /xstyle, xrange = [min(energy_arr), max(energy_arr)], $
			title = title, /nodata

		oplot, energy_arr, foxsi_number_of_modules * eff_area_orig, psym = -4, color = 7
		oplot, energy_arr, eff_area_orig, psym = -4, color = 7
	ENDIF

	result = create_struct("energy_keV", energy_arr, "eff_area_cm2", eff_area)

	RETURN, result

END
