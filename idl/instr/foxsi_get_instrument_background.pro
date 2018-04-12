;+
; NAME : foxsi_get_instrument_background
;
; PURPOSE : Returns the current best estimate for the instrument background (both telescopes).
;   See https://docs.google.com/document/d/1oMd9dJ0RoMMoT86fpZeK6b5eztfPzlg_bO47GiXqx7s/edit?usp=sharing
;   for a detailed write-up.
;
; SYNTAX : bkg = foxsi_get_instrument_background()
;
; INPUTS : None
;
; Optional Inputs :
;			energy_arr - for the returned spectrum, use the energies in this array (in keV)
;			                 rather than the default energies (1-keV steps from 0 to 60 keV)
;
; Optional Outputs :
;			energy_arr - the energy array used
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

    default, energy_arr, findgen(60)

    result = 2. * energy_arr ^ (-0.8) * exp(-energy_arr / 30.)

    IF keyword_set(in_hpd) THEN result *= !pi / 4. * 25. ^ 2 / (9. * 60) ^ 2

    RETURN, result
END
