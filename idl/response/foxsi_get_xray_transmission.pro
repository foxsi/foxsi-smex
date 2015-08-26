; NAME : foxsi_get_xray_transmission
;
; PURPOSE : Returns the x-ray transmission efficiency through a material
;
; SYNTAX : trans = foxsi_get_xray_transmission()
;
; INPUTS :
;           thickness_mm - the thickness in mm
;           material - material name as a string
;
; Optional Inputs :
;			energy_arr - array of energies in keV to interpolate effective area
;                            onto.
;
; KEYWORDS :
;			plot - if true then plot to the screen
;
; RETURNS : struct
;               energy_keV - the energy in keV
;               absorption - the  absorption efficiency
;               transmission - the transmission efficiency
;
; EXAMPLES : None
;

FUNCTION foxsi_get_xray_transmission, thickness_mm, material, ENERGY_ARR = energy_arr, $
    PLOT = plot

    COMMON foxsi_smex_vars, foxsi_root_path, foxsi_data_path, foxsi_name, $
        foxsi_optic_effarea, foxsi_number_of_modules, foxsi_shell_ids, $
        foxsi_shutters_thickness_mm, foxsi_detector_thickness_mm, foxsi_blanket_thickness_mm

    ; load the data
    path = foxsi_data_path + 'mass_atten_idl/' + material + '.csv'
    f = file_search(path)
    IF f EQ '' THEN BEGIN
        print, 'File ' + path + ' not found.'
        print, 'Data for ' + material + ' may not exist?'
        RETURN, -1
    ENDIF
    data = read_csv(path, table_header=header, n_table_header = 4)
    density_cgs = float(strmid(header[3], 11, 4))

    data_energy_keV = data.field1 * 1000.0
    data_attenuation_coeff = data.field2

    IF NOT keyword_set(energy_arr) THEN energy_keV = findgen(60) ELSE $
        energy_keV = energy_arr

    ; interpolate in log space as function is better behaved in that space
    atten_len_um = 10^interpol(alog10(data_attenuation_coeff), alog10(data_energy_keV), alog10(energy_keV))
    ;should load this from the hdf5 file
    path_length_cm = thickness_mm / 10.0
    transmission = exp(-atten_len_um * density_cgs * path_length_cm)
    absorption = 1 - transmission

    IF keyword_set(PLOT) THEN BEGIN
        plot_title = material + ' ' + num2str(thickness_mm) + ' mm'
        plot, energy_keV, absorption, xtitle = 'Energy [keV]', ytitle = 'Efficiency', $
              /nodata, yrange = [0.0, 1.2], charsize = 1.5, title=plot_title
        oplot, energy_keV, absorption, psym = -4
        oplot, energy_keV, transmission, psym = -5
        ssw_legend, ['Transmission', 'Absorption'], linestyle=[1,2], psym=[5,4]
    ENDIF

    result = create_struct("energy_keV", energy_keV, "absorption", absorption, $
        "transmission", transmission)

    RETURN, result
END
