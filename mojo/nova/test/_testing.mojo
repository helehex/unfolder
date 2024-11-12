# x----------------------------------------------------------------------------------------------x #
# | Helehex 2024
# x----------------------------------------------------------------------------------------------x #
"""Nova Testing."""

from nova import Value
from memory import UnsafePointer
from builtin._location import __call_location, _SourceLocation
from testing.testing import _assert_error


struct CopyCounter(Value):
    var rc: UnsafePointer[Int]

    fn __init__(out self):
        self.rc = UnsafePointer[Int].alloc(1)
        self.rc[] = 0

    fn __copyinit__(inout self, other: Self):
        self.rc = other.rc
        self.rc[] += 1

    fn __moveinit__(inout self, owned other: Self):
        self.rc = other.rc

    fn __del__(owned self):
        if self:
            self.rc[] -= 1
        else:
            self.rc.free()

    fn __bool__(self) -> Bool:
        return self.rc[] != 0

    fn __str__(self) -> String:
        return str(self.rc[])

    fn __eq__(self, rhs: Self) -> Bool:
        return self.rc == rhs.rc

    fn __ne__(self, rhs: Self) -> Bool:
        return self.rc != rhs.rc
