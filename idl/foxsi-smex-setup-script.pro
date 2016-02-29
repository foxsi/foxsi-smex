COMMON foxsi_smex_vars, foxsi_root_path, foxsi_data_path, foxsi_name, $
    foxsi_optic_effarea, foxsi_number_of_modules, foxsi_shell_ids, $
    foxsi_shutters_thickness_mm, foxsi_detector_thickness_mm, foxsi_blanket_thickness_mm

; Set Path where foxsi-smex is
CD, Current=fs_location

; to minimize the chance of collisions all variables names must be start
; with foxsi_

foxsi_root_path = fs_location
foxsi_data_path = strmid(foxsi_root_path, 0, strlen(foxsi_root_path)-3) + 'data/'
;foxsi_data_path = foxsi_root_path + '/data/'
foxsi_name = 'FOXSI-SMEX'
foxsi_number_of_modules = 3
foxsi_launch_date = '2020/06/01'

foxsi_focal_length = 15

foxsi_shutters_thickness_mm = [0, 1.0, 1.5]
foxsi_detector_thickness_mm = 0.500
; the blankets are assumed to be made of mylar
foxsi_blanket_thickness_mm = 0.5

; the shells that are included in a FOXSI optics module
; foxsi_shell_ids = indgen(40)+1

add_path, foxsi_root_path, /expand

print, 'FOXSI SMEX Ready to Go!'
