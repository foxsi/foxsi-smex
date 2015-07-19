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

import pyfoxsi

__all__ = [Response']


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
