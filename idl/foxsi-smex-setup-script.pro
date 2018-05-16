COMMON foxsi_smex_vars, foxsi_root_path, foxsi_data_path, foxsi_name, $
    foxsi_optic_effarea, foxsi_number_of_modules, foxsi_shell_ids, $
    foxsi_shutters_thickness_mm, foxsi_detector_thickness_mm, foxsi_blanket_thickness_mm, $
    foxsi_stc_aperture_area_mm2, foxsi_stc_detector_material, foxsi_stc_detector_thickness_mm, $
    foxsi_stc_filter_material, foxsi_stc_filter_thickness_um

; Set Path where foxsi-smex is
CD, Current=fs_location

; to minimize the chance of collisions all variables names must be start
; with foxsi_

foxsi_root_path = fs_location
foxsi_data_path = strmid(foxsi_root_path, 0, strlen(foxsi_root_path)-3) + 'data/'
;foxsi_data_path = foxsi_root_path + '/data/'
foxsi_name = 'FOXSI-SMEX'
foxsi_number_of_modules = 2
foxsi_launch_date = '2022/07/01'

foxsi_focal_length = 14

; the attenuators are assumed to be aluminum
foxsi_shutters_thickness_mm = [0, 0.02, 0.08, 0.3, 1.3, 6]
foxsi_detector_thickness_mm = 1.0
; the blankets are assumed to be made of mylar
foxsi_blanket_thickness_mm = 0.5

; Thresholds at which a warning kicks in for detector rates
; Thresholds are per-pixel and per-detector.
foxsi_default_rate_limit_pixel = 12.e3
foxsi_default_rate_limit_detector = 60.e3

; STC Parameters
foxsi_stc_aperture_area_mm2 = {q: 1.0, f: 0.02}
foxsi_stc_detector_material = 'Si'
foxsi_stc_detector_thickness_mm = 0.5
foxsi_stc_filter_material = 'Be'
foxsi_stc_filter_thickness_um = {q: 15, f: 50}


add_path, foxsi_root_path, /expand

print, 'FOXSI SMEX Ready to Go!'
