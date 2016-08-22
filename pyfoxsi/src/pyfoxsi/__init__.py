from __future__ import absolute_import
import astropy.units as u
from datetime import datetime

#shell_ids = np.arange(1, 40)
number_of_telescopes = 3
mission_title = 'FOXSI SMEX'
detector_material = 'cdte'

launch_date = datetime(2020, 06, 01)

shutters_thickness = [0, 1.0, 1.5] * u.mm
detector_thickness = 1.0 * u.mm
blanket_thickness = 0.5 * u.mm

focal_length = 15 * u.m
