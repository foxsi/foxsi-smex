Response
========

The effective area is provided by the `~pyfoxsi.response.Response` object. The following code shows
how to initialize the object and plot the results.

.. plot::
    :include-source:

    import matplotlib.pyplot as plt
    from pyfoxsi.response import Response
    resp = Response(shutter_state=0)

    plt.figure()
    resp.plot()
    plt.show()

On initialization we can also define the shutter state so that one of the
shutters is in to block the low energy x-rays. The following plot shows
a comparison of the areas for each shutter strategy

.. plot::
    :include-source:

    import matplotlib.pyplot as plt
    from pyfoxsi.response import Response

    resp0 = Response(shutter_state=0)
    resp1 = Response(shutter_state=1)
    resp2 = Response(shutter_state=2)

    fig = plt.subplots()
    resp0.effective_area['total'].plot(label='Shutter state 0')
    resp1.effective_area['total'].plot(label='Shutter state 1')
    resp2.effective_area['total'].plot(label='Shutter state 2')
    plt.legend()

It is also possible to take a look at the area provided by the optics only
compared to that acted upon by material in the optical path such as the
thermal blankets and detectors.

.. plot::
    :include-source:

    import matplotlib.pyplot as plt
    from pyfoxsi.response import Response

    resp0 = Response(shutter_state=0)

    fig = plt.subplots()
    resp0.optics_effective_area['total'].plot(label='Optics')
    resp0.effective_area['total'].plot(label='Optics + path')
    plt.legend()

Material
========
The optical path is composed of various materials which affect the transmission
(or absorption in the case of the detectors). You can inspect how these materials
are affecting the path by looking at the `factor` variable in the effective area.

.. plot::
    :include-source:

    import matplotlib.pyplot as plt
    from pyfoxsi.response import Response

    resp0 = Response(shutter_state=0)

    fig = plt.subplots()
    resp0.effective_area['factor'].plot()
    plt.title('This factor multiplies the effective area')
    plt.show()

To see what materials are in the path check out the `optical_path` property.
The `Material` object provides it's own plot function.

.. plot::
    :include-source:

    import matplotlib.pyplot as plt
    from pyfoxsi.response import Response

    resp0 = Response(shutter_state=0)

    fig = plt.subplots()
    resp0.optical_path[0].plot()
    plt.legend()
