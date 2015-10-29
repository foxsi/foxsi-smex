"""
PSF is a module to handle the Point Spread Function of the FOXSI telescopes
"""

from __future__ import absolute_import
import os
import pyfoxsi
import numpy as np
import sunpy.map
import astropy.units as u

__all__ = ['Psf', 'psf_map']

def gauss2d((x,y), amplitude, xo, yo, sigma_x, sigma_y, theta) :
    r"""A two-dimensional eliptical Gaussian function of the form

    amplitude * np.exp( - (((x-xo)**2) / sigma**2))

    but where sigma can vary along dimensions and theta controls the rotation.

    Parameters
    ----------
    (x,y) : array_like
        Array_like means all those objects -- lists, nested lists, etc. --
        that can be converted to an array.  We can also refer to
        variables like `var1`.
    amplitude : float
        The amplitude of the peak.
    xo : float
        The center location in the x-axis.
    yo : float
        The center location in the y-axis.
    sigma_x : float
        The width in the unrotated x-direction.
    sigma_y : float
        The width in the unrotated y-direction.
    theta : float (radian)
        The rotation angle.

    Returns
    -------
    array
        The amplitude of the function at each (x,y)

    Examples
    --------
    These are written in doctest format, and should illustrate how to
    use the function.
    >>> x, y = np.meshgrid(np.arange(-10,10,1), np.arange(-10,10,1))
    >>> data = gauss2d((x, y), 1, 0, 0, 1, 5, np.pi/4.)
    """

    a = (np.cos(theta)**2)/(2*sigma_x**2) + (np.sin(theta)**2)/(2*sigma_y**2)
    b = -(np.sin(2*theta))/(4*sigma_x**2) + (np.sin(2*theta))/(4*sigma_y**2)
    c = (np.sin(theta)**2)/(2*sigma_x**2) + (np.cos(theta)**2)/(2*sigma_y**2)
    return amplitude*np.exp( - (a*((x-xo)**2) + 2*b*(x-xo)*(y-yo) + c*((y-yo)**2)))

def multi_gauss2d((x,y), amplitude, center, sigma_x, sigma_y, theta):
    r"""A sum of multiple two-dimensional eliptical Gaussian function of the form

    amplitude * np.exp( - (((x-xo)**2) / sigma**2))

    but where sigma can vary along dimensions and theta controls the rotation.

    The number of gaussians is set by the dimension of the variable amplitude,
    sigma_x, and sigma_y. The center and theta must be the same for each.

    Parameters
    ----------
    (x,y) : array_like
        Array_like means all those objects -- lists, nested lists, etc. --
        that can be converted to an array.  We can also refer to
        variables like `var1`.
    amplitude : array_like
        The amplitudes of the peaks.
    xo : float
        The center location in the x-axis.
    yo : float
        The center location in the y-axis.
    sigma_x : array_like
        The width in the unrotated x-direction.
    sigma_y : array_like
        The width in the unrotated y-direction.
    theta : float (radian)
        The rotation angle for each gaussian.

    See Also
    --------
    gauss2d : relationship (optional)

    Returns
    -------
    array
        The amplitude of the function at each (x,y)

    Examples
    --------
    These are written in doctest format, and should illustrate how to
    use the function.
    >>> x, y = np.meshgrid(np.arange(-10,10,1), np.arange(-10,10,1))
    >>> data = multi_gauss2d((x, y), (100,10,1), 0, 0, (1,2,3), (5,6,7), np.pi/4.)
    """
    i = 0
    for amp, sig_x, sig_y in zip(amplitude, sigma_x, sigma_y):
        g = gauss2d((x, y), amp, center[0], center[1], sig_x, sig_y, theta)
        if i == 0:
            result = g
        else:
            result += g
        i += 1
    return result

def psf_map(pitch, yaw):
    p = Psf(pitch, yaw)
    scale = 0.1
    x, y = np.meshgrid(np.arange(-20, 20, scale), np.arange(-20, 20, scale))
    im = p.func((x,y)).reshape(x.shape)
    iy, ix = np.unravel_index(np.argmax(im), im.shape)
    header =  {'cdelt1': scale,
               'cdelt2': scale,
               'telescop': 'FOXSI-2 Simulate',
               'crpix1': iy, 'crpix2': ix,
               'crval1': 0, 'crval2': 0}
    this_map = sunpy.map.Map(im, header).shift(pitch, yaw)
    return this_map


class Psf(object):

    def __init__(self, pitch, yaw):
        # load the PSF parameters
        path = os.path.dirname(pyfoxsi.__file__)
        for i in np.arange(3):
            path = os.path.dirname(path)
        path = os.path.join(path, 'data/')
        params = np.loadtxt(os.path.join(path, 'psf_parameters.txt'))

        self.offaxis_angle, self.polar_angle = self._calculate_angles(pitch, yaw)

        poly_params = []
        for g in params:
            f = np.poly1d(g)
            poly_params.append(f(self.offaxis_angle))

        amplitude = (poly_params[0], poly_params[1], poly_params[2])
        width_x = [poly_params[3], poly_params[5], poly_params[7]]
        width_y = [poly_params[4], poly_params[6], poly_params[8]]
        self.func = lambda (x, y): multi_gauss2d((x, y), amplitude, (0, 0), width_x, width_y, self.polar_angle)

    def _calculate_angles(self, pitch, yaw):
        """Calculate the polar angle and offaxis angle"""
        offaxis_angle = np.sqrt(pitch **2 + yaw ** 2)
        polar_angle = np.arctan2(yaw, pitch)
        return (polar_angle, offaxis_angle)

    def _calculate_parameter(self, offaxis_angle, params):
        f = np.poly1d(params)
        return f(offaxis_angle)
