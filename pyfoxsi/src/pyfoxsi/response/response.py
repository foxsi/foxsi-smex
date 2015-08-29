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
    """An object which provides the FOXSI telescope response"""

    def __init__(self):
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
        self.effective_area = pd.DataFrame({'module': self._eff_area_per_shell.sum(axis=1), 'total': self._eff_area_per_shell.sum(axis=1)})
        self.number_of_telescopes = pyfoxsi.number_of_telescopes
        self.optical_path = []

    def plot(self):
        ax = self.effective_area.plot()
        ax.set_title(pyfoxsi.mission_title + ' ' + str(self.number_of_telescopes) + 'x')
        ax.set_ylabel('Effective area [$cm^2$]')
        ax.set_xlabel('Energy [keV]')

    @property
    def number_of_telescopes(self):
        return self.__number_of_telescopes

    @number_of_telescopes.setter
    def number_of_telescopes(self, x):
        self.effective_area['total'] = self.effective_area['total'] / self.__number_of_telescopes * x
        self.__number_of_telescopes = x

    @property
    def optical_path(self):
        return self.__optical_path

    @optical_path.setter
    def optical_path(self, x):
        self.effective_area['total'] = self.effective_area['total'] / self.__number_of_telescopes * x
        self.__number_of_telescopes = x


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
        self.material = material
        self.thickness = thickness

        path = os.path.dirname(pyfoxsi.__file__)
        for i in np.arange(3):
            path = os.path.dirname(path)
        path = os.path.join(path, 'data/')
        filename = 'mass_attenuation_coefficient.hdf5'
        data_file = os.path.join(path, filename)

        h = h5py.File(data_file, 'r')
        data = h[self.material]
        self._source_data = data

        self.density = u.Quantity(self._source_data.attrs['density'], self._source_data.attrs['density unit'])

        data_energy_kev = np.log10(self._source_data[0,:] * 1000)
        data_attenuation_coeff = np.log10(self._source_data[1,:])
        self._f = interpolate.interp1d(data_energy_kev, data_attenuation_coeff, bounds_error=False, fill_value=0.0)
        self._mass_attenuation_coefficient_func = lambda x: 10 ** self._f(np.log10(x))

    def __repr__(self):
        """Returns a human-readable representation."""
        return '<Material ' + str(self.material) + ' ' + str(self.thickness) + '>'

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
        plt.title(self.material + ' ' + str(self.thickness))
        plt.xlabel('Energy [keV]')
