"""Plot the effective area as a function of energy"""
from pyfoxsi.response import DSIResponse
import matplotlib.pyplot as plt

resp = DSIResponse()

resp = DSIResponse(shutter_state=0)

resp.plot()
plt.plot(resp._energies, resp.optic_effective_area, label='Optics only')
plt.show()