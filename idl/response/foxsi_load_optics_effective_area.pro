;+
; NAME : foxsi_load_optics_effective_area
;
; PURPOSE : Load the optics effective area file.
;
; SYNTAX : data = foxsi_load_optics_effarea()
;
; INPUTS : None
;
; Optional Inputs : None
;
; KEYWORDS :  None
;
; RETURNS : struct
;
; EXAMPLES : None
;

FUNCTION foxsi_load_optics_effective_area

    ; load the foxsi-smex common block
    COMMON foxsi_smex_vars, foxsi_root_path, foxsi_data_path, foxsi_name, $
        foxsi_optic_effarea, foxsi_number_of_modules, foxsi_shell_ids

    data_filename = 'effective_area_per_shell.csv'
    path = foxsi_data_path + data_filename
    ;path = '../../data/' + data_filename

    number_of_columns = 51
    number_of_rows = 506

    OPENR, lun, path, /GET_LUN
    header = strarr(1)
    readf, lun, header
    data_str = strarr(number_of_rows)
    readf, lun, data_str
    free_lun, lun

    data = fltarr(number_of_columns, number_of_rows)

    FOR i = 0, n_elements(data_str)-1 DO BEGIN
        data[*, i] = strsplit(data_str[i], ',', /extract)
    ENDFOR

    result = create_struct('energy_keV', data[0, *], 'eff_area_cm2', data[1:number_of_columns-1, *])

    RETURN, result
END
