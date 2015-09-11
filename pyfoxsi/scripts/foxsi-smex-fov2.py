import matplotlib.pyplot as plt
from sunpy.map import Map
import sunpy.data.sample as s
import numpy as np
from astropy.units import Quantity
import scipy.signal

aia = Map(s.AIA_171_IMAGE)

fig, axs = plt.subplots(1,1)
aia.plot(axes=axs[0])
aia.draw_grid()

pixel_size = 3.4
number_of_pixels = 160

center = np.array([461, 303])
smap = aia.submap(Quantity([center[0] - pixel_size * number_of_pixels/2., center[0] + pixel_size * number_of_pixels/2.], 'arcsec'),
                  Quantity([center[1] - pixel_size * number_of_pixels/2., center[1] + pixel_size * number_of_pixels/2.], 'arcsec'))
smap.plot()

#plate scale for this image is 1.3 arcsec
#plate scale for AIA image is 1.4 arcsec which is very close
psf = np.fromfile('onaxis_psf.dat', dtype=np.float32).reshape(53,53)
psf /= psf.sum()

r = scipy.signal.convolve2d(smap.data, psf, mode='same')

smap.data = r
smap.plot()

new_dim = int(smap.dimensions.x.value * smap.scale.x.value / pixel_size)

rmap = smap.resample(Quantity([new_dim, new_dim], 'pix'), method='spline')
rmap.plot()

plt.show()
