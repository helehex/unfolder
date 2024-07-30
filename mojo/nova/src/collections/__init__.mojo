# x----------------------------------------------------------------------------------------------x #
# | Helehex 2024
# x----------------------------------------------------------------------------------------------x #
"""Nova Collections."""

from .span_bound import *
from .array import *
from .small_array import *
from .table import *
from .vector import *
from .freq import *
from .mgraph import *
from .lgraph import *

from ..io import *
from sys.intrinsics import _type_is_eq


# homogeneous utils
@always_inline("nodebug")
fn _constrain_homo[T: Movable, *Ts: Movable]():
    @parameter
    for i in range(_len[Ts]()):
        constrained[_type_is_eq[T, Ts[i]](), "non homogeneous types"]()


@always_inline("nodebug")
fn _constrain_len[capacity: Int, *Ts: Movable]():
    constrained[_len[Ts]() <= capacity, "variadic exceeds capacity"]()


@always_inline("nodebug")
fn _len[*Ts: Movable]() -> Int:
    return len(VariadicList(Ts))
