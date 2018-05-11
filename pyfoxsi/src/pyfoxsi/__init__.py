from __future__ import absolute_import
import astropy.units as u
from datetime import datetime

mission_title = 'FOXSI-SMEX'
launch_date = datetime(2022, 7, 1)

number_of_dsi_telescopes = 2

shutter_material = 'Al'
shutter_thickness = [0, 0.02, 0.08, 0.3, 1.3, 6] * u.mm
detector_material = 'cdte'
detector_thickness = 1.0 * u.mm
blanket_material = 'mylar'
blanket_thickness = 0.5 * u.mm

dsi_focal_length = 14 * u.m
