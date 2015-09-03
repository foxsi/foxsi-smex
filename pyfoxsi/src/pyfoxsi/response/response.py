"""
Response is a module to handle the response of the FOXSI telescopes
"""

from __future__ import absolute_import

import pandas as pd
import numpy as np

import warnings
import os

import matplotlib.pyplot as plt
import astropy.units as u
from scipy import interpolate
import pyfoxsi

import h5py

__all__ = ['Response', 'Material']


class Response(object):
    """An object which provides the FOXSI telescope response

    Parameters
    ----------
    shutter_state : int
        A number representing the state of the shutter (0 - no shutter, 1
        - thin shutter, 2 - thick shutter)

    Examples
    --------
    >>> from pyfoxsi.response import Response
    >>> resp = Response()
    >>> resp1 = Response(shutter_state=1)
    """
    def __init__(self, shutter_state=0):
        path = os.path.dirname(pyfoxsi.__file__)
        for i in np.arange(3):
            path = os.path.dirname(path)
        path = os.path.join(path, 'data/')
        filename = 'effective_area_per_shell.csv'
        effarea_file = os.path.join(path, filename)
        self._eff_area_per_shell = pd.read_csv(effarea_file, index_col=0)
        # find what shells are missing
        shell_numbers = np.array(self._eff_area_per_shell.columns, np.uint)
        missing_shells = np.setdiff1d(shell_numbers, pyfoxsi.shell_ids)
        # remove the missing shells
        self.__number_of_telescopes = 1
        for missing_shell in missing_shells:
            self._eff_area_per_shell.drop(str(missing_shell), 1, inplace=True)
        # now add the effective area of all of the shells together
        self.optics_effective_area = pd.DataFrame({'module': self._eff_area_per_shell.sum(axis=1), 'total': self._eff_area_per_shell.sum(axis=1)})
        self.effective_area = self.optics_effective_area.copy()
        self.number_of_telescopes = pyfoxsi.number_of_telescopes
        self._set_default_optical_path()
        if shutter_state > 0:
            self.__optical_path.append(Material('be', pyfoxsi.shutters_thickness[shutter_state]))
        self.__shutter_state = shutter_state

    def plot(self):
        ax = self.effective_area.plot()
        ax.set_title(pyfoxsi.mission_title + ' ' + str(self.number_of_telescopes) + 'x ' + 'Shutter State ' + str(self.shutter_state))
        ax.set_ylabel('Effective area [cm$^2$]')
        ax.set_xlabel('Energy [keV]')

    def _set_default_optical_path(self):
        self.__optical_path = [Material('mylar', pyfoxsi.blanket_thickness),
                            Material(pyfoxsi.detector_material, pyfoxsi.detector_thickness)]
        self._add_optical_path_to_effective_area()

    @property
    def number_of_telescopes(self):
        return self.__number_of_telescopes

    @number_of_telescopes.setter
    def number_of_telescopes(self, x):
        self.optics_effective_area['total'] = self.optics_effective_area['total'] / self.__number_of_telescopes * x
        self.__number_of_telescopes = x

    @property
    def optical_path(self):
        return self.__optical_path

    @optical_path.setter
    def optical_path(self, x):
        self.optical_path = x
        self._add_optical_path_to_effective_area()

    @property
    def shutter_state(self):
        return self.__shutter_state

    @shutter_state.setter
    def shutter_state(self, x):
        raise AttributeError('Cannot change shutter state. Create new object with desired shutter state')

    def _add_optical_path_to_effective_area(self):
        """Add the effect of the optical path to the effective area"""
        energies = np.array(self.optics_effective_area.index)
        factor = np.ones(energies.shape)
        for material in self.optical_path:
            #effective_area = self.optics_effective_area.values
            if material.name == pyfoxsi.detector_material:
                factor *= factor * material.absorption(energies)
            else:
                factor *= factor * material.transmission(energies)
        self.effective_area['factor'] = factor
        self.effective_area['total'] = factor * self.optics_effective_area['total']
        self.effective_area['module'] = factor * self.optics_effective_area['module']

class Material(object):
    """An object which provides the optical properties of a material in x-rays

    Parameters
    ----------
    material : str
        A string representing a material (e.g. cdte, be, mylar, si)
    thickness : `astropy.units.Quantity`
        The thickness of the material in the optical path.

    Examples
    --------
    >>> from pyfoxsi.response import Material
    >>> import astropy.units as u
    >>> detector = Material('cdte', 500 * u.um)
    >>> thermal_blankets = Material('mylar', 0.5 * u.mm)
    """

    def __init__(self, material, thickness):
        self.name = material
        self.thickness = thickness

        path = os.path.dirname(pyfoxsi.__file__)
        for i in np.arange(3):
            path = os.path.dirname(path)
        path = os.path.join(path, 'data/')
        filename = 'mass_attenuation_coefficient.hdf5'
        data_file = os.path.join(path, filename)

        h = h5py.File(data_file, 'r')
        data = h[self.name]
        self._source_data = data

        self.density = u.Quantity(self._source_data.attrs['density'], self._source_data.attrs['density unit'])

        data_energy_kev = np.log10(self._source_data[0,:] * 1000)
        data_attenuation_coeff = np.log10(self._source_data[1,:])
        self._f = interpolate.interp1d(data_energy_kev, data_attenuation_coeff, bounds_error=False, fill_value=0.0)
        self._mass_attenuation_coefficient_func = lambda x: 10 ** self._f(np.log10(x))

    def __repr__(self):
        """Returns a human-readable representation."""
        return '<Material ' + str(self.name) + ' ' + str(self.thickness) + '>'

    def transmission(self, energy):
    	"""Provide the transmission fraction (0 to 1).

        Parameters
        ----------
        energy : `astropy.units.Quantity`
            An array of energies in keV
        """
    	coefficients = self._mass_attenuation_coefficient_func(energy) * u.cm ** 2 / u.gram
    	transmission = np.exp(- coefficients * self.density * self.thickness)
    	return transmission

    def absorption(self, energy):
	    """Provides the absorption fraction (0 to 1).

        Parameters
        ----------
        energy : `astropy.units.Quantity`
            An array of energies in keV.
        """
	    return 1 - self.transmission(energy)

    def plot(self):
        f = plt.figure()
        energies = np.arange(1, 60)
        plt.plot(energies, self.transmission(energies), label='Transmission')
        plt.plot(energies, self.absorption(energies), label='Absorption')
        plt.ylim(0, 1.2)
        plt.legend()
        plt.title(self.name + ' ' + str(self.thickness))
        plt.xlabel('Energy [keV]')
