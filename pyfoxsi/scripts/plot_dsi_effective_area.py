"""Plot the effective area as a function of energy"""
import pyfoxsi
from pyfoxsi.response import DSIResponse
import matplotlib.pyplot as plt

resp = DSIResponse()

resp.plot()
plt.plot(resp._energies, resp._optic_effective_area, label='Optics only')
plt.title('DSI')

for i, thickness in enumerate(pyfoxsi.shutter_thickness):
    this_resp = DSIResponse(shutter_state=i)
    plt.plot(this_resp._energies, this_resp.effective_area(this_resp._energies), label='Shutter state {0}'.format(i))

plt.legend()
plt.show()