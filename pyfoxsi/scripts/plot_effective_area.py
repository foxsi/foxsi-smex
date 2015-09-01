"""Plot the effective area as a function of energy"""
from pyfoxsi.response import Response
import matplotlib.pyplot as plt

resp = Response()

resp.plot()
plt.show()

resp = Response(shutter_state=1)

resp.plot()
plt.show()
