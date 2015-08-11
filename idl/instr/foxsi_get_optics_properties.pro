;+
; NAME : foxsi_get_optics_properties
;
; PURPOSE : Returns various properties of the optics.
;
; SYNTAX : optics_properties = foxsi_get_optics_properties()
;
; INPUTS : None
;
; Optional Inputs : None
;
; KEYWORDS : None
;
; RETURNS : struct
;
; EXAMPLES : None
;

FUNCTION foxsi_get_optics_properties

	; load the foxsi-smex common block
    COMMON foxsi_smex_vars, foxsi_root_path, foxsi_data_path, foxsi_name, $
        foxsi_optic_effarea, foxsi_number_of_modules, foxsi_shell_ids

    data_filename = 'shell_parameters.csv'
    path = foxsi_data_dir + data_filename

    data = read_csv(path, n_table_header=2, header=header)

    print, header
    result = create_struct('shell_id', data.field01, 'radius_inner_cm', data.field02, $
                            'radius_mid_cm', data.field03, 'radius_outer_cm', data.field04, $
                            'graze_angle_deg', data.field05, 'geoarea_cm2', data.field08, $
                            'mass_kg', data.field09, 'thickness_cm', data.field11 $
                            )
	RETURN, result
END
