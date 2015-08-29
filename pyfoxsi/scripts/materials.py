from pyfoxsi.response import Material
import matplotlib.pyplot as plt
import astropy.units as u
import numpy as np

detector = Material('cdte', 500 * u.um)

energies = np.arange(1,60,1)
print(detector.absorption(energies))
print(detector.transmission(energies))

detector.plot()
plt.show()

thermal_blankets = Material('mylar', 0.5 * u.mm)
thermal_blankets.plot()
plt.show()
