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

__all__ = ['test', 'Response']

def test():
    print('foobar')

class Response(object):
    """An object which provides the FOXSI telescope response"""
    def __init__(self):
        pyfoxsi.shell_ids = np.arange(1, 40)
        path = os.path.dirname(response.__file__)
        for i in np.arange(3):
            path = os.path.dirname(path)
        filename = 'effective_area_per_shell.csv'
        effarea_file = os.path.join(path, filename)
        self._eff_area_per_shell = pd.read_csv(effarea_file, index_col=0)
        # find what shells are missing
        shell_numbers = np.array(eff_area.columns, np.uint)
        missing_shells = np.setdiff1d(shell_numbers, pyfoxsi.shell_ids)
        # remove the missing shells
        for missing_shell in missing_shells:
            self._eff_area_per_shell.drop(str(missing_shell), 1, inplace=True)
        # now add the effective area of all of the shells together
        self.effective_area = self._eff_area_per_shell.sum(axis=1)
