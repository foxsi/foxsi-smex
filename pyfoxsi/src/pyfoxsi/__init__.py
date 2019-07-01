from __future__ import absolute_import
import astropy.units as u
from datetime import datetime

mission_title = 'FOXSI-SMEX'
launch_date = datetime(2022, 7, 1)

# DSI Parameters
number_of_dsi_telescopes = 2

shutter_material = 'Al'
shutter_thickness = [0, 0.02, 0.08, 0.3, 1.3, 6] * u.mm
detector_material = 'cdte'
detector_thickness = 1.0 * u.mm
blanket_material = 'mylar'
blanket_thickness = 0.5 * u.mm

dsi_focal_length = 14 * u.m

# STC Parameters
stc_aperture_area = {'Q': 1.0 * u.mm ** 2, 'F': 0.02 * u.mm ** 2}
stc_detector_material = 'Si'
stc_detector_thickness = 0.5 * u.mm
stc_filter_material = 'Be'
stc_filter_thickness = {'Q': 15 * u.micron, 'F': 50 * u.micron}
