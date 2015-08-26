Imaging
=======

get_foxsi_image.pro                       (located in /response folder)
-------------------

>> Requires make_map and plot_map functions.

This function is intended to simulate the image measured by the FOXSI detectors for a
given input source image. Currently this must be a 2D monochromatic source, future iterations
of this programme will introduce the possibility of different energy photons in the source.

This involves modelling the convolution of the image due to the point spread function of
the optics modules and the pixelisation of the detectors. The function may be run with an
automatically generated source (a narrow gaussian to the right hand side of a 150x150 FOV)
and a default pixelisation ratio of 3 with the call:

    IDL> rebinned_convolved_map = get_foxsi_image()

And the output viewed with the command:

    IDL> plot_map, rebinned_convolved_map

Alternatively, a user supplied source_map may be supplied and the function run with a
custom pixelisation ratio as follows:

    IDL> rebinned_convolved_map = get_foxsi_image(source_map, px = "Your Pixelisation Ratio")

Note the source_map file contains information on the pixel size in arcseconds and the solar
coordinates of the centre of the field of view. This is automatically read in and propagated
in the programme.

The convolution currently only has one point spread function which was obtained from measuring
the point spread function for the on-axis position (<< note, currently off axis measurement used,
waiting for on axis fitting parameters >>) and fitting this with three gaussians. (See the preamble
of get_psf_array.pro for details). Future iterations of this code will include some functionality
to include variance in the psf for a given off axis source position and also for convolving at
different spatial points in the optics cross section.


WARNING: Run time is dependent on the size of the FOV. The default FOV is 150x150 pixels,
or 2.5'x2.5', this runs in a few seconds. Simulating the entire FOXSI FOV (~16.5'x16.5')
will take ~9 Hours.


Peripheral Functions:
- get_source_map.pro                      (located in /response folder)
- get_psf_array.pro                       (located in /response folder)
