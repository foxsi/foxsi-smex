"""Get the physical parameters for a telescope module"""

from pyfoxsi.telescope import Optic

optic = Optic()

# the total mass of a telescope module is
print(optic.mass)

# get the properties of a particular telescope shell
print(optic.shell(3))
