from pyfoxsi.psf import convolve
from sunpy.map import Map
import matplotlib.pyplot as plt

f = '/Users/schriste/Google Drive/Work/FOXSI SMEX/Data/hsi_image_20050513_164526to164626_pixon_3arcsecx64_25to50kev_d1to9.fits'
hsi = Map(f)

foxsi_map = convolve(hsi)

plt.figure()
plt.subplot(1, 2, 1)
hsi.plot()
plt.subplot(1, 2, 2)
foxsi_map.plot()
plt.show()
