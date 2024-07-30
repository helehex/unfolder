# x----------------------------------------------------------------------------------------------x #
# | Helehex 2024
# x----------------------------------------------------------------------------------------------x #
"""Ansi Color Characters."""


struct Color:
    """Ansi Color Characters."""

    alias none = ""
    alias clear = "\033[0m"
    alias grey = "\033[0;30m"
    alias red = "\033[0;31m"
    alias green = "\033[0;32m"
    alias yellow = "\033[0;33m"
    alias blue = "\033[0;34m"
    alias pink = "\033[0;35m"
    alias cyan = "\033[0;36m"
    alias white = "\033[0;37m"
