from __future__ import absolute_import
import astropy.units as u
from datetime import datetime

number_of_telescopes = 2
mission_title = 'FOXSI SMEX'

launch_date = datetime(2022, 07, 01)

shutter_material = 'aluminum'
shutters_thickness = [0, 0.02, 0.08, 0.3, 1.3, 6] * u.mm
detector_material = 'cdte'
detector_thickness = 1.0 * u.mm
blanket_material = 'mylar'
blanket_thickness = 0.5 * u.mm

focal_length = 14 * u.m
