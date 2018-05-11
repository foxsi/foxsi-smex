"""
Response is a module to handle the response of the FOXSI telescopes
"""

from __future__ import absolute_import
import os

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy import interpolate

import astropy.units as u
from roentgen.absorption import Material
import pyfoxsi

__all__ = ['DSIResponse']


class DSIResponse(object):
    """An object which provides the FOXSI DSI telescope response

    Parameters
    ----------
    shutter_state : int, default 0 (no shutter)
        A number representing the state of the shutter

    Examples
    --------
    >>> from pyfoxsi.response import Response
    >>> resp = DSIResponse()
    >>> resp1 = DSIResponse(shutter_state=1)
    """
    def __init__(self, shutter_state=0, number_of_telescopes=2):
        path = os.path.dirname(pyfoxsi.__file__)
        for i in np.arange(3):
            path = os.path.dirname(path)
        path = os.path.join(path, 'data/')
        filename = 'effective_area_per_module.csv'
        effarea_file = os.path.join(path, filename)
        self.data = pd.read_csv(effarea_file, index_col=0, skiprows=4)
        self._energies = u.Quantity(self.data.index, 'keV')
        self.__number_of_telescopes = number_of_telescopes
        self.optic_effective_area = u.Quantity(self.data['effective_area'], 'cm**2') * self.number_of_telescopes
        self._set_default_optical_path()

        if (shutter_state >= 0) and (shutter_state < len(pyfoxsi.shutter_thickness)):
            self.__optical_path.append(Material(pyfoxsi.shutter_material, pyfoxsi.shutter_thickness[shutter_state]))
            self.__shutter_state = shutter_state
        else:
            raise ValueError('Not a valid shutter state, must be 0 to {0}'.format(len(pyfoxsi.shutter_thickness)))
        self._factor = self._calc_factor_from_optical_path()

    def plot(self, energy=None, axes=None):
        """Plot the effective area"""
        if axes is None:
            axes = plt.gca()
        if energy is None:
            energy = self.energy
        y = self.effective_area(energy)
        axes.plot(self.energy, y)
        axes.set_title('{0} {1} shutter state={2}'.format(pyfoxsi.mission_title,
                                                          str(self.number_of_telescopes),
                                                          str(self.shutter_state)))
        axes.set_ylabel('Effective area [{0}]'.format(y.unit))
        axes.set_xlabel('Energy [{0}]'.format(energy.unit))

    def _set_default_optical_path(self):
        self.__optical_path = [Material(pyfoxsi.blanket_material,
                                        pyfoxsi.blanket_thickness),
                               Material(pyfoxsi.detector_material,
                                        pyfoxsi.detector_thickness)]

    @property
    def energy(self):
        return self._energies

    def effective_area(self, energy):
        """Given an energy return the effective area."""
        factor = self._calc_factor_from_optical_path()
        effarea = self.optic_effective_area.value * factor
        f = interpolate.interp1d(self._energies.to_value('keV'), effarea)
        return f(energy) * u.cm**2

    @property
    def number_of_telescopes(self):
        """The total number of telescope modules"""
        return self.__number_of_telescopes

    @property
    def optical_path(self):
        """The materials in the optical path including the detector"""
        return self.__optical_path

    @optical_path.setter
    def optical_path(self, x):
        self.optical_path = x
        self._add_optical_path_to_effective_area()

    @property
    def shutter_state(self):
        """The shutter state"""
        return self.__shutter_state

    @shutter_state.setter
    def shutter_state(self, x):
        raise AttributeError('Cannot change shutter state. Create new object with desired shutter state')

    def _calc_factor_from_optical_path(self):
        """Calculate the effect of material on the optical path."""
        factor = np.ones_like(self._energies.value)
        # Apply all of the materials in the optical path to factor
        for mat in self.optical_path:
            if mat.name.count('Cadmium Telluride'):  # should not hard code
                # if it is the detector than we want the absorption
                factor *= mat.absorption(self._energies).value
            else:
                factor *= mat.transmission(self._energies).value
        return factor
