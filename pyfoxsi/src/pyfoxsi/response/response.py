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

__all__ = ['dsi_background', 'DSIResponse', 'STCResponse']


def dsi_background(energy, in_hpd=True):
    """Returns results in counts/s/keV"""
    result = 2. * energy.to('keV').value ** (-0.8) * np.exp(-energy.to('keV').value / 30.)
    if in_hpd:
        result *=  np.pi / 4. * 25. ** 2 / (9 * 60) ** 2
    return result * u.count / u.s / u.keV


class Response(object):
    """A generic object to provide the response of a FOXSI instrument.
    """

    def __init__(self, energy, effective_area, optical_path):

        self.data = pd.DataFrame({'effective_area': effective_area.to('cm ** 2').value,
                                  'energy': energy.to('keV').value})
        self.data.set_index('energy', inplace=True)

        self._energies = u.Quantity(self.data.index, 'keV')
        self._optic_effective_area = u.Quantity(self.data['effective_area'],
                                                'cm**2')
        self.optical_path = optical_path

    def plot(self, energy=None, axes=None, color=None):
        """Plot the effective area"""
        if axes is None:
            axes = plt.gca()
        if energy is None:
            energy = self.energy
        y = self.effective_area(energy)
        if color is None:
            axes.plot(self.energy, y)
        else:
            axes.plot(self.energy, y, color=color)
        axes.set_ylabel('Effective area [{0}]'.format(str(y.unit)))
        axes.set_xlabel('Energy [{0}]'.format(str(energy.unit)))

    @property
    def energy(self):
        return self._energies

    def effective_area(self, energy):
        """Given an energy return the effective area."""
        factor = self._calc_factor_from_optical_path()
        effarea = self._optic_effective_area.value * factor
        f = interpolate.interp1d(self._energies.to_value('keV'),
                                 effarea)
        return f(energy) * u.cm ** 2

    def _calc_factor_from_optical_path(self):
        """Calculate the effect of material on the optical path."""
        factor = np.ones_like(self._energies.value)
        # Apply all of the materials in the optical path to factor
        for mat in self.optical_path:
            if mat.name.count('Cadmium Telluride') or mat.name.count('Silicon'):  # should not hard code
                # if it is the detector than we want the absorption
                factor *= mat.absorption(self._energies).value
            else:
                factor *= mat.transmission(self._energies).value
        return factor


class STCResponse(Response):
    """An object which provides the FOXSI STC telescope response

    Parameters
    ----------
    kind : str (Q or F)
       Specify the STC detector. Q is for quiet which provides more
        sensitivity. F is for flare which is optimized for flares observations.

    Examples
    --------
    >>> from pyfoxsi.response import STCResponse
    >>> resp = STCResponse()
    >>> resp_q = STCResponse(kind='Q')
    >>> resp_f = STCResponse(kind='F')
    """
    def __init__(self, kind='Q'):

        energies = np.arange(0.2, 20, 0.1)

        if (kind != 'Q') and (kind != 'F'):
            raise ValueError('Not a valid STC kind. Must be Q or F')

        # add the detector to the path
        optical_path = []
        optical_path.append(Material(pyfoxsi.stc_detector_material, pyfoxsi.stc_detector_thickness))
        # add the kind specific filter to the path
        optical_path.append(Material(pyfoxsi.stc_filter_material,
                                     pyfoxsi.stc_filter_thickness.get(kind)))
        effective_area = np.ones_like(energies) * pyfoxsi.stc_aperture_area.get(kind)

        super().__init__(energies * u.keV, effective_area, optical_path)
        self.__kind = kind

    @property
    def kind(self):
        return self.__kind

    @kind.setter
    def kind(self, x):
        raise AttributeError('Cannot change kind. Create new object with desired value.')


class DSIResponse(Response):
    """An object which provides the FOXSI DSI telescope response

    Parameters
    ----------
    shutter_state : int, default 0 (no shutter)
        A number representing the state of the shutter

    Examples
    --------
    >>> from pyfoxsi.response import DSIResponse
    >>> resp = DSIResponse()
    >>> resp_atten1 = DSIResponse(shutter_state=1)
    """
    def __init__(self, shutter_state=0, number_of_telescopes=2):
        path = os.path.dirname(pyfoxsi.__file__)
        for i in np.arange(3):
            path = os.path.dirname(path)
        path = os.path.join(path, 'data/')
        filename = 'effective_area_per_module.csv'
        effarea_file = os.path.join(path, filename)
        data = pd.read_csv(effarea_file, index_col=0, skiprows=4)
        energy = u.Quantity(data.index, u.keV)
        effective_area = data['effective_area'].values * u.cm ** 2
        # the default optical path
        optical_path = [Material(pyfoxsi.blanket_material, pyfoxsi.blanket_thickness),
                        Material(pyfoxsi.detector_material, pyfoxsi.detector_thickness)]
        if (shutter_state >= 0) and (shutter_state < len(pyfoxsi.shutter_thickness)):
            optical_path.append(Material(pyfoxsi.shutter_material, pyfoxsi.shutter_thickness[shutter_state]))
            self.__shutter_state = shutter_state
        else:
            raise ValueError('Not a valid shutter state, must be 0 to {0}'.format(len(pyfoxsi.shutter_thickness)))
        super().__init__(energy, effective_area, optical_path)
        self.__number_of_telescopes = number_of_telescopes
        self._optic_effective_area = u.Quantity(self.data['effective_area'], 'cm**2') * self.number_of_telescopes
        self._factor = self._calc_factor_from_optical_path()

    @property
    def number_of_telescopes(self):
        """The total number of telescope modules"""
        return self.__number_of_telescopes

    @property
    def shutter_state(self):
        """The shutter state"""
        return self.__shutter_state

    @shutter_state.setter
    def shutter_state(self, x):
        raise AttributeError('Cannot change shutter state. Create new object with desired shutter state')