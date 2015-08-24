
FUNCTION foxsi_get_xray_transmission, thick, material, ENERGY_ARR = energy_arr, $
    PLOT = plot

    COMMON foxsi_smex_vars, foxsi_root_path, foxsi_data_path, foxsi_name, $
        foxsi_optic_effarea, foxsi_number_of_modules, foxsi_shell_ids, $
        foxsi_thick_shutter_thickness_mm, foxsi_thin_shutter_thickness_mm, $
        foxsi_detector_thickness_um

    ; load the data
    file_id = H5F_OPEN(foxsi_data_path + 'mass_attenuation_coefficient.hdf5')
    dataset_cdte = H5D_OPEN(file_id, material)
    ; Read in the actual image data.
    data = H5D_READ(dataset_cdte)

    energy_keV = data[0] * 1000.0
    attenuation_coeff = data[1]

    IF keyword_set(energy_arr) THEN BEGIN
        atten_len_um = interpol(atten_len_um, energy_keV, energy_arr)
    ENDIF ELSE energy_arr = energy_keV

    ;should load this from the hdf5 file
    density_cgs = 6.2
    path_length_m = thick_um * 1e-6
    transmission = 1 - exp(-attenuation_coeff * density_cgs * path_length_m * 100.0)
    efficiency = 1 - transmission

    IF keyword_set(PLOT) THEN BEGIN
        plot, energy_arr, transmission, xtitle = 'Energy [keV]', ytitle = 'Efficiency', $
              /nodata, yrange = [0.0, 1.0], charsize = 1.5
        oplot, energy_arr, transmission, psym = -4, linestyle = 1
        oplot, energy_arr, 1 - transmission, psym = -4, linestyle = 2
        ssw_legend, linestyle=[1,2], text=['Transmission', 'Efficiency']
    ENDIF

    result = create_struct("energy_keV", energy_arr, "efficiency", efficiency, $
        "transmission", transmission)

    H5F_OPEN, file_id
    RETURN, result

END
