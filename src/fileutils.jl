
"""
    dpng(x)

Displays `x` as PNG. Can be used when the default representation
(SVG or PDF) is too heavy.
"""
dpng(x) = display("image/png", x)
