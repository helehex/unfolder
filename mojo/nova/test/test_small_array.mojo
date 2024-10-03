# x----------------------------------------------------------------------------------------------x #
# | Helehex 2024
# x----------------------------------------------------------------------------------------------x #

from testing import *
from nova.testing import *

from sys.intrinsics import _type_is_eq
from nova import SmallArray


def main():
    test_init()
    test_subscript()


def test_init():
    var rc = CopyCounter()
    var a = SmallArray[CopyCounter, 6]()
    a = SmallArray[CopyCounter, 6](rc, rc, rc, rc, rc, rc)
    a = SmallArray[CopyCounter, 6](fill=rc)
    var b = a
    b = SmallArray[CopyCounter, 6](rc, rc, rc, rc, rc, rc)
    b = SmallArray[CopyCounter, 6](fill=rc)
    assert_false(rc)


def test_subscript():
    var a = SmallArray[Int, 3](3, 4, 5)
    assert_equal(a[0], 3)
    assert_equal(a[1], 4)
    assert_equal(a[2], 5)
    a[0] = 6
    a[1] = 7
    a[2] = 8
    assert_equal(a[0], 6)
    assert_equal(a[1], 7)
    assert_equal(a[2], 8)
