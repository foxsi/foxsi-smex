"""
Telescope is a module to handle the FOXSI telescopes
"""
from __future__ import absolute_import

import pyfoxsi
import pandas as pd
from astropy.units import Unit
import os.path
import numpy as np

class Optic(object):
    """A FOXSI Optic"""
    def __init__(self):
        path = os.path.dirname(pyfoxsi.__file__)
        for i in np.arange(3):
            path = os.path.dirname(path)
        path = os.path.join(path, 'data/')
        filename = 'shell_parameters.csv'
        params_file = os.path.join(path, filename)
        self.shell_params = pd.read_csv(params_file, index_col=0)
        the_units = [Unit(this_unit) for this_unit in self.shell_params.loc[np.nan].values]
        self.units = {}
        for i, col in enumerate(self.shell_params):
            self.units.update({col: the_units[i]})
        self.shell_params.drop(self.shell_params.index[0], inplace=True)
        missing_shells = np.setdiff1d(self.shell_params.index, pyfoxsi.shell_ids)
        self.shell_params.drop(missing_shells)
        for col in self.shell_params.columns:
            self.shell_params[col] = self.shell_params[col].astype(float)

    def shell(self, shell_number):
        """Return the parameters of one shell"""
        try:
            self.shell_params.loc[shell_number]
        except:
            ValueError('Shell %i is missing.' % shell_number)

    @property
    def mass(self):
        return self.shell_params['Mass'].sum() * self.units.get("Mass")
