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

```

;
; Example: Plot the effective area for all 3 FOXSI modules.
;

@foxsi-smex-setup-script			; if not already run

area = foxsi_get_effective_area()
plot, area.energy_kev, area.eff_area_cm2, /xlog, /ylog, yrange=[1.,1.e3], $
	thick=3, xtitle='Energy [keV]', ytitle='FOXSI effective area [cm!U-3!N]'
oplot, area.energy_kev, area.eff_area_optic_cm2, line=1, thick=3
al_legend, ['Single module','Three modules'], line=[1,0], thick=3

The effect of various attenuator states can be included by using the keyword SHUTTER_STATE 
in the foxsi_get_effective_area routine.  SHUTTER_STATE can take on the values 0,1,2 
as defined by:
;           shutter_state -
;               0 no shutter
;               1 is thin shutter in  (1.0 mm)
;               2 is thick shutter in	(1.5 mm)

```

```

;
; Example: Determine the FOXSI count spectrum for a specified hard X-ray distribution.
;

@foxsi-smex-setup-script			; if not already run

!p.multi=[0,1,2]

IDL> ; HXR source (example isothermal flare):
IDL> t_flare  = 15   ; flare temperature in MK
IDL> em_flare = 1.d48 ; flare emission measure in cm^-3
IDL> energy_2D = get_edges( findgen(50)+1.5, /edges_2 )  ; edges of energy bins
IDL> energy = get_edges( energy_2D, /mean )
IDL> flux = f_vth( energy_2D, [em_flare/1.d49, t_flare/11.6, 1.] )
IDL> plot, energy, flux, /xlog, /ylog, thick=3, xtitle='Energy [keV]', $
IDL>  ytitle='Photon flux [s!U-1!N cm!U-2!N keV!U-1!N]', $
IDL>  title='Flare T=15 MK, EM=1.e49 cm!U-3!N'

IDL> ; Fold through the diagonal FOXSI response using full 3 modules.
IDL> area = foxsi_get_effective_area( energy_arr=energy )
IDL> counts = area.eff_area_cm2 * flux
IDL> plot, energy, counts, /xlog, /ylog, psym=10, thick=3, xtitle='Energy [keV]', $
IDL>  ytitle='FOXSI counts [s!U-1!N keV!U-1!N]', $
IDL>  title='Flare T=15 MK, EM=1.e49 cm!U-3!N'

!p.multi=0

```

```

;
; Using attenuators (shutters)
; You can use predefined attenuator states (0,1,2; SHUTTER_STATE keyword) or you can 
; specify the exact attenuator thickness you'd like to use (SHUTTER_THICKNESS_MM keyword).
; Shutters are aluminum, but other materials can be added on request.
;

; Example with no shutter.  Specify nothing.
area  = foxsi_get_effective_area( )
plot,  area.energy_kev, area.eff_area_cm2  

; Example: specify shutters by predefined state:
; States are 0: no shutter, 1: 1 mm, 2: 1.5 mm
area0 = foxsi_get_effective_area( shutter_state=0. )
area1 = foxsi_get_effective_area( shutter_state=1. )
area2 = foxsi_get_effective_area( shutter_state=2. )
plot,  area0.energy_kev, area0.eff_area_cm2  
oplot, area1.energy_kev, area1.eff_area_cm2  
oplot, area2.energy_kev, area2.eff_area_cm2  

; Example: specify shutters by exact thickness in mm:
areaA = foxsi_get_effective_area( shutter_thick_mm=0. )
areaB = foxsi_get_effective_area( shutter_thick_mm=1. )
areaC = foxsi_get_effective_area( shutter_thick_mm=2. )
areaD = foxsi_get_effective_area( shutter_thick_mm=3. )
plot,  areaA.energy_kev, areaA.eff_area_cm2  
oplot, areaB.energy_kev, areaB.eff_area_cm2  
oplot, areaC.energy_kev, areaC.eff_area_cm2  
oplot, areaD.energy_kev, areaD.eff_area_cm2  

```