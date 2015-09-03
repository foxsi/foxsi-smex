import matplotlib.pyplot as plt
from sunpy.map import Map
import sunpy.data.sample as s
import numpy as np
aia = Map(s.AIA_171_IMAGE)

fig, axs = plt.subplots(1,2)
aia.plot(axes=axs[0])
aia.draw_grid()

r = [11.52, 10.42, 6.14, 3.64, 2.75]
e = [10, 20, 30, 40, 50]

pixel_size = 3.4
number_of_pixels = 160

center = np.array([461, 303])

line_color = 'w'

rect = plt.Rectangle(center - pixel_size * number_of_pixels/2., pixel_size * number_of_pixels, pixel_size * number_of_pixels, fill=False, color=line_color)
ax[0].add_artist(rect)

rect = plt.Rectangle(center - pixel_size/2., pixel_size, pixel_size, fill=False, color=line_color)
ax[0].add_artist(rect)

for radius, energy in zip(r,e):
    circle = plt.Circle(center, radius=radius*60, fill=False, label=str(energy), color=line_color)
    ax[0].add_artist(circle)
plt.colorbar()
plt.legend()

aia.plot(axes=ax[1])

plt.show()
