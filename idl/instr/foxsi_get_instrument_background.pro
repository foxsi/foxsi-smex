;+
; NAME : foxsi_get_instrument_background
;
; PURPOSE : Returns the current best estimate for the instrument_background (defaults to entire instrument)
;
; SYNTAX : bkg = foxsi_get_instrument_background()
;
; INPUTS : None
;
; Optional Inputs :
;			energy_arr - array of energies in keV 
;
; KEYWORDS :
;			in_hpd - if set, scale background to only within the nominal HPD (25")
;
; RETURNS : 
;			background in units of counts/s/keV
;
; EXAMPLES : None
;

FUNCTION foxsi_get_instrument_background, ENERGY_ARR = energy_arr, IN_HPD = in_hpd

    IF NOT keyword_set(energy_arr) THEN energy_keV = findgen(60) ELSE $
        energy_keV = energy_arr

    ; This expression includes an additional factor of 2 to account for the increased background
    ; at 28.5-deg inclination compared to 6-deg inclination
    result = 2. * 2. * energy_keV ^ (-0.8) * exp(-energy_keV / 30.)

    IF keyword_set(in_hpd) THEN result *= !pi / 4. * 25. ^ 2 / (9. * 60) ^ 2

    RETURN, result
END
