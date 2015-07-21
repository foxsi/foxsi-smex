;+
; NAME : foxsi_load_optics_effarea
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

FUNCTION foxsi_load_optics_effarea

    ; load the foxsi-smex common block
    COMMON foxsi_smex_vars, foxsi_root_path, foxsi_data_dir, foxsi_name, foxsi_optic_effarea, foxsi_number_of_modules

    data_filename = 'effective_area_per_shell.csv'
    path = foxsi_data_dir + data_filename
    data = read_csv(path, header=header)

    RETURN, data

END
