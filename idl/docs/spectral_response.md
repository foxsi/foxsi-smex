Spectral response
=================

The main function to access the effective area is `foxsi_get_effective_area`.
It returns the effective area in cm^2 which includes the thermal blankets,
detector efficiency, and shutters (if specified).  The area for a single optics 
module and the area for the entire set are both returned, along with the energy 
array at which these values are computed.

If desired, the user can specify the energy array for which the effective area
will be computed via the optional keyword ENERGY_ARR.  If no energy array is 
input, the function will use the default energies 1-50 keV sampled at 1 keV 
intervals.

At present, only the diagonal instrument spectral response is considered. 
Energy resolution, fluorescence, Compton scattering, and other nondiagonal 
elements are not included.

Don't forget to run @foxsi-smex-setup-script before trying the routines.

;
; Example: Plot the effective area for all 3 FOXSI modules.
;

@foxsi-smex-setup-script			; if not already run

area = foxsi_get_effective_area()
plot, area.energy_kev, area.eff_area_cm2, /xlog, /ylog, yrange=[1.,1.e3], $
	thick=3, xtitle='Energy [keV]', ytitle='FOXSI effective area [cm!U-3!N]'
oplot, area.energy_kev, area.eff_area_optic_cm2, line=1, thick=3
al_legend, ['Single module','Three modules'], line=[1,0], thick=3


;
; Example: Determine the FOXSI count spectrum for a specified hard X-ray distribution.
;

@foxsi-smex-setup-script			; if not already run

!p.multi=[0,1,2]

; HXR source (example isothermal flare):
t_flare  = 15			; flare temperature in MK
em_flare = 1.d48	; flare emission measure in cm^-3
energy_2D = get_edges( findgen(50)+1.5, /edges_2 )		; edges of energy bins
energy = get_edges( energy_2D, /mean )
flux = f_vth( energy_2D, [em_flare/1.d49, t_flare/11.6, 1.] )
plot, energy, flux, /xlog, /ylog, thick=3, xtitle='Energy [keV]', $
	ytitle='Photon flux [s!U-1!N cm!U-2!N keV!U-1!N]', $
	title='Flare T=15 MK, EM=1.e49 cm!U-3!N'

; Fold through the diagonal FOXSI response using full 3 modules.
area = foxsi_get_effective_area( energy_arr=energy )
counts = area.eff_area_cm2 * flux
plot, energy, counts, /xlog, /ylog, psym=10, thick=3, xtitle='Energy [keV]', $
	ytitle='FOXSI counts [s!U-1!N keV!U-1!N]', $
	title='Flare T=15 MK, EM=1.e49 cm!U-3!N'

!p.multi=0
