"""
PSF is a module to handle the Point Spread Function of the FOXSI telescopes
"""

from __future__ import absolute_import
import os
import pyfoxsi
import numpy as np
import sunpy.map
import astropy.units as u
from astropy.convolution import Gaussian2DKernel
from astropy.convolution import convolve as astropy_convolve
from sunpy.map import Map

__all__ = ['psf', 'convolve']

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

def psf(x, y, scale=1 * u.arcsec / u.pix):
    r"""The point spread function.

    .. warning: implement the x and y keywords are not yet implemented.

    Parameters
    ----------
    x : `~astropy.units.quantities` <deg>
        The angle at which the psf is returned in the horizontal direction.
    y : `~astropy.units.quantities` <deg>
        The angle at which the psf is returned in the vertical direction.
    scale : float
        The pixel scale (e.g. arcsec / pixel). Should be set to match the map
        with which it will be convolved.

    Returns
    -------
    kernel : `~astropy.convolution.Gaussian2DKernel`
        A psf kernel, normalized. Assumes 1 arcsec pixels if scale is not set.

    Examples
    --------
    >>> p = psf(0 * u.arcmin, 0 * u.arcmin)
    >>> p = psf(0 * u.arcmin, 0 * u.arcmin, 2 * u.arcsec)
    """
    # load the PSF parameters
    path = os.path.dirname(pyfoxsi.__file__)
    for i in np.arange(3):
        path = os.path.dirname(path)
    path = os.path.join(path, 'data/')
    params = np.loadtxt(os.path.join(path, 'psf_parameters.txt'))

    offaxis_angle = np.sqrt(y ** 2 + x ** 2)
    polar_angle = np.arctan2(y, x)

    poly_params = []
    for g in params:
        f = np.poly1d(g)
        poly_params.append(f(offaxis_angle))

    amplitude = (poly_params[0], poly_params[1], poly_params[2])
    width = u.Quantity([poly_params[3], poly_params[4], poly_params[5]], 'arcsec')
    width = width / scale
    print(width)
    # add 90 deg to the polar angle to make the rotation angle perpendicular
    # to the polar angle
    kernel = amplitude[0] * Gaussian2DKernel(width[0].value) + amplitude[1] * Gaussian2DKernel(width[1].value) + amplitude[2] * Gaussian2DKernel(width[2].value)
    kernel.normalize()
    return kernel

def convolve(sunpy_map):
    """Convolve the FOXSI psf with an input map

    Parameters
    ----------
    sunpy_map : `~sunpy.map.GenericMap`
        An input map.

    Returns
    -------
    sunpy_map : `~sunpy.map.GenericMap`
        The map convolved with the FOXSI psf.
    """

    this_psf = psf(0 * u.arcmin, 0 * u.arcmin, scale=sunpy_map.scale.x)

    smoothed_data = astropy_convolve(sunpy_map.data, this_psf)
    meta = sunpy_map.meta.copy()
    meta['telescop'] = 'FOXSI-SMEX'
    result = Map((smoothed_data, meta))

    return result
