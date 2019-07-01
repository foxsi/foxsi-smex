"""Plot the effective area as a function of energy"""
import pyfoxsi
from pyfoxsi.response import STCResponse
import matplotlib.pyplot as plt

resp_q = STCResponse(kind='Q')
resp_f = STCResponse(kind='F')

plt.figure(1)

plt.subplot(121)

resp_q.plot()
plt.plot(resp_q._energies, resp_q._optic_effective_area,
         label='Q Optics only', linestyle='--', color='blue')
plt.title('STC-Q')
plt.legend()

plt.subplot(122)

resp_f.plot(color='red')
plt.plot(resp_f._energies, resp_f._optic_effective_area,
         label='F Optics only', linestyle='--', color='red')
plt.title('STC-F')


plt.legend()
plt.show()