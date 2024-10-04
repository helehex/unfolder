# x----------------------------------------------------------------------------------------------x #
# | Helehex 2024
# x----------------------------------------------------------------------------------------------x #

from testing import *
from nova.testing import *

from sys.intrinsics import _type_is_eq
from nova import Array, SpanBound


def main():
    test_equal()
    test_init()
    test_is()
    # test_iter()
    test_subscript()
    test_contains()
    test_string()
    test_length()
    test_truthy()
    test_add()
    test_mul()
    test_insert()
    test_append()
    test_index()
    test_resize()
    test_count()
    test_pop()
    test_remove()
    test_clear()
    test_fill()


def test_equal():
    assert_true(Array(1, 2, 3).__eq__(Array(1, 2, 3)))
    assert_true(Array(1, 2, 3).__ne__(Array(1, 2, 4)))
    assert_true(Array(1, 2, 3).__ne__(Array(1, 2, 3, 4)))


def test_init():
    assert_true(_type_is_eq[__type_of(Array(1, 2, 3, 4)), Array[Int]]())
    assert_true(_type_is_eq[__type_of(Array(Array(0, 1))), Array[Array[Int]]]())

    var rc = CopyCounter()
    var a = Array[CopyCounter](size=6)
    a = Array(rc, rc, rc, rc, rc, rc)
    a = Array(rc, rc, size=6)
    var b = Array[CopyCounter](a)
    b = Array[CopyCounter](a, a)
    b = Array[CopyCounter](a, a, size=10)
    b = Array(a.__iter__())
    assert_false(rc)


def test_is():
    var a = Array(1, 2, 3)
    var b = a
    var c = Pointer.address_of(a)
    assert_is(a, a)
    assert_is_not(a, b)
    assert_is(a, c[])


def test_subscript():
    var a = Array(0, 1, 2, 3, 4, 5)
    a[0] = 6
    a[1] = 8
    a[5] = 7
    assert_equal(a[0], 6)
    assert_equal(a[1], 8)
    assert_equal(a[2], 2)
    assert_equal(a[5], 7)
    assert_equal(a[-1], 7)
    assert_equal(Array(a[2:]), Array(2, 3, 4, 7))
    assert_equal(Array(a[:3]), Array(6, 8, 2))

    # x------ span
    var s = a[1:-1]
    assert_equal(s[0], 8)
    assert_equal(s[1], 2)
    assert_equal(Array(s[::2]), Array(8, 3))
    assert_equal(Array(s[::-2]), Array(4, 2))

    # x------ rebound
    alias clamp = SpanBound.Clamp
    alias wrap = SpanBound.Wrap

    a = Array(0, 0, 0, 0, 0, 0)
    a.__getitem__[clamp](-1) = 1
    a.__getitem__[clamp](3) = 2
    a.__getitem__[clamp](6) = 3
    assert_equal(a.__getitem__[clamp](-2), 1)
    assert_equal(a.__getitem__[clamp](-1), 1)
    assert_equal(a.__getitem__[clamp](0), 1)
    assert_equal(a.__getitem__[clamp](3), 2)
    assert_equal(a.__getitem__[clamp](5), 3)
    assert_equal(a.__getitem__[clamp](6), 3)
    assert_equal(a.__getitem__[clamp](7), 3)

    a = Array(0, 0, 0, 0, 0, 0)
    a.__getitem__[wrap](6) = 1
    a.__getitem__[wrap](3) = 2
    a.__getitem__[wrap](-1) = 3
    assert_equal(a.__getitem__[wrap](12), 1)
    assert_equal(a.__getitem__[wrap](6), 1)
    assert_equal(a.__getitem__[wrap](0), 1)
    assert_equal(a.__getitem__[wrap](3), 2)
    assert_equal(a.__getitem__[wrap](5), 3)
    assert_equal(a.__getitem__[wrap](-1), 3)
    assert_equal(a.__getitem__[wrap](-7), 3)

    a = Array(0, 0, 0, 0, 0, 0)
    var a1 = a.rebound[clamp]()
    a1[-1] = 1
    a1[3] = 2
    a1[6] = 3
    assert_equal(a1[-2], 1)
    assert_equal(a1[-1], 1)
    assert_equal(a1[0], 1)
    assert_equal(a1[3], 2)
    assert_equal(a1[5], 3)
    assert_equal(a1[6], 3)
    assert_equal(a1[7], 3)

    var a2 = a.rebound[wrap]()
    a2[6] = 1
    a2[3] = 2
    a2[-1] = 3
    assert_equal(a2[12], 1)
    assert_equal(a2[6], 1)
    assert_equal(a2[0], 1)
    assert_equal(a2[3], 2)
    assert_equal(a2[5], 3)
    assert_equal(a2[-1], 3)
    assert_equal(a2[-7], 3)


def test_contains():
    assert_true(Array(1, 2, 3).__contains__(3))
    assert_false(Array(1, 2, 3).__contains__(4))


def test_string():
    assert_equal(Array[Int]().__str__(), "[]")
    assert_equal(Array(1).__str__(), "[1]")
    assert_equal(Array(1, 2, 3).__str__(), "[1, 2, 3]")


def test_length():
    assert_equal(Array[Int]().__len__(), 0)
    assert_equal(Array(1, 2, 3).__len__(), 3)

    var a = Array(1, 2, 3, 4, 5, 6)
    assert_equal(a.__len__(), 6)

    # x------ Span
    assert_equal(a[:].__len__(), 6)

    assert_equal(a[1:].__len__(), 5)
    assert_equal(a[-1:].__len__(), 1)
    assert_equal(a[2:].__len__(), 4)
    assert_equal(a[-2:].__len__(), 2)

    assert_equal(a[:1].__len__(), 1)
    assert_equal(a[:-1].__len__(), 5)
    assert_equal(a[:2].__len__(), 2)
    assert_equal(a[:-2].__len__(), 4)

    assert_equal(a[1:1].__len__(), 0)
    assert_equal(a[1:-1].__len__(), 4)
    assert_equal(a[-1:1].__len__(), 0)
    assert_equal(a[-1:-1].__len__(), 0)

    assert_equal(a[::1].__len__(), 6)
    assert_equal(a[::-1].__len__(), 6)
    assert_equal(a[::2].__len__(), 3)
    assert_equal(a[::-2].__len__(), 3)
    assert_equal(a[::3].__len__(), 2)
    assert_equal(a[::-3].__len__(), 2)

    assert_equal(a[1::-1].__len__(), 2)
    assert_equal(a[-1::-1].__len__(), 6)

    assert_equal(a[:1:-1].__len__(), 4)
    assert_equal(a[:-1:-1].__len__(), 0)

    assert_equal(a[1:1:-1].__len__(), 0)
    assert_equal(a[1:-1:-1].__len__(), 0)
    assert_equal(a[-1:1:-1].__len__(), 4)
    assert_equal(a[-1:-1:-1].__len__(), 0)

    # x------ Iter
    assert_equal(a.__iter__().__len__(), 6)
    assert_equal(a[:].__iter__().__len__(), 6)

    assert_equal(a[1:].__iter__().__len__(), 5)
    assert_equal(a[-1:].__iter__().__len__(), 1)
    assert_equal(a[2:].__iter__().__len__(), 4)
    assert_equal(a[-2:].__iter__().__len__(), 2)

    assert_equal(a[:1].__iter__().__len__(), 1)
    assert_equal(a[:-1].__iter__().__len__(), 5)
    assert_equal(a[:2].__iter__().__len__(), 2)
    assert_equal(a[:-2].__iter__().__len__(), 4)

    assert_equal(a[1:1].__iter__().__len__(), 0)
    assert_equal(a[1:-1].__iter__().__len__(), 4)
    assert_equal(a[-1:1].__iter__().__len__(), 0)
    assert_equal(a[-1:-1].__iter__().__len__(), 0)

    assert_equal(a[::1].__iter__().__len__(), 6)
    assert_equal(a[::-1].__iter__().__len__(), 6)
    assert_equal(a[::2].__iter__().__len__(), 3)
    assert_equal(a[::-2].__iter__().__len__(), 3)
    assert_equal(a[::3].__iter__().__len__(), 2)
    assert_equal(a[::-3].__iter__().__len__(), 2)

    assert_equal(a[1::-1].__iter__().__len__(), 2)
    assert_equal(a[-1::-1].__iter__().__len__(), 6)

    assert_equal(a[:1:-1].__iter__().__len__(), 4)
    assert_equal(a[:-1:-1].__iter__().__len__(), 0)

    assert_equal(a[1:1:-1].__iter__().__len__(), 0)
    assert_equal(a[1:-1:-1].__iter__().__len__(), 0)
    assert_equal(a[-1:1:-1].__iter__().__len__(), 4)
    assert_equal(a[-1:-1:-1].__iter__().__len__(), 0)


def test_truthy():
    assert_false(Array[Int]().__bool__())
    assert_false(Array[Array[Int]]().__bool__())
    assert_true(Array[Int](0).__bool__())
    assert_true(Array[Array[Int]](0).__bool__())
    assert_true(Array[Int](1, 2).__bool__())
    assert_true(Array[Array[Int]](1, 2).__bool__())


def test_add():
    var a1 = Array(0, 1)
    var a2 = Array(2) + 3
    assert_equal(a1 + a2, Array(0, 1, 2, 3))
    a1 += a2
    assert_equal(a1, Array(0, 1, 2, 3))


def test_mul():
    assert_equal(Array[Int]() * 0, Array[Int]())
    assert_equal(Array[Int]() * 1, Array[Int]())
    assert_equal(Array[Int]() * 2, Array[Int]())
    assert_equal(Array[Int]() * 4, Array[Int]())
    assert_equal(Array[Int](8) * 0, Array[Int]())
    assert_equal(Array[Int](8) * 1, Array[Int](8))
    assert_equal(Array[Int](8) * 2, Array[Int](8, 8))
    assert_equal(Array[Int](8) * 3, Array[Int](8, 8, 8))
    assert_equal(Array[Int](0, 1) * 0, Array[Int]())
    assert_equal(Array[Int](0, 1) * 1, Array[Int](0, 1))
    assert_equal(Array[Int](0, 1) * 2, Array[Int](0, 1, 0, 1))
    assert_equal(Array[Int](0, 1) * 3, Array[Int](0, 1, 0, 1, 0, 1))

    var a: Array[Int]
    a = Array(8, 7, 6)
    a *= 3
    assert_equal(a, Array(8, 7, 6, 8, 7, 6, 8, 7, 6))


def test_insert():
    var a = Array(0, 1, 3, 4, 5)
    a.insert(2, 2)
    a.insert(6, 6)
    assert_equal(a, Array(0, 1, 2, 3, 4, 5, 6))


def test_append():
    var a = Array(0, 1, 2)

    a.append(3)
    assert_equal(a, Array(0, 1, 2, 3))

    a.append(Array(4, 5))
    assert_equal(a, Array(0, 1, 2, 3, 4, 5))


def test_index():
    var a = Array(3, 4, 5, 6, 4, 5)
    assert_equal(a.index(4), 1)
    assert_equal(a.index(6), 3)
    with assert_raises():
        _ = a.index(10)

    # x------ span
    var s = a[:0:-1]
    assert_equal(s.index(5), 0)
    assert_equal(s.index(6), 2)
    with assert_raises():
        _ = s.index(3)


def test_resize():
    var a = Array(0, 1, 2, 3, 4, 5)
    a.resize(3)
    assert_equal(a, Array(0, 1, 2))
    a.resize(5)
    assert_equal(a, Array(0, 1, 2, 0, 0))


def test_count():
    var a = Array(7, 8, 9, 7, 8, 7)
    assert_equal(a.count(7), 3)
    assert_equal(a.count(8), 2)
    assert_equal(a.count(9), 1)
    assert_equal(a.count(10), 0)

    # x------ span
    var s = a[3:]
    assert_equal(s.count(7), 2)
    assert_equal(s.count(8), 1)
    assert_equal(s.count(9), 0)


def test_pop():
    var a = Array(4, 6, 5, 7, 3)
    assert_equal(a.pop(), 3)
    assert_equal(a, Array(4, 6, 5, 7))
    assert_equal(a.pop(0), 4)
    assert_equal(a, Array(6, 5, 7))
    assert_equal(a.pop(-2), 5)
    assert_equal(a, Array(6, 7))


def test_remove():
    var a = Array(4, 6, 5, 4, 3)
    a.remove(5)
    assert_equal(a, Array(4, 6, 4, 3))
    a.remove(3)
    assert_equal(a, Array(4, 6, 4))
    a.remove(4)
    assert_equal(a, Array(6, 4))


def test_clear():
    var a = Array(0, 1, 2, 3, 4, 5)
    a.clear()
    assert_equal(a, Array(0, 0, 0, 0, 0, 0))

    # x------ span
    a = Array(0, 1, 2, 3, 4, 5)
    a[2:5].clear()
    assert_equal(a, Array(0, 1, 0, 0, 0, 5))

    a = Array(0, 1, 2, 3, 4, 5)
    a[::2].clear()
    assert_equal(a, Array(0, 1, 0, 3, 0, 5))

    # x------ lifecycle
    rc = CopyCounter()
    var m = Array(rc, rc, rc, rc)
    m.clear()
    assert_false(rc)


def test_fill():
    var a = Array(0, 1, 2, 3, 4, 5)
    a.fill(6)
    assert_equal(a, Array(6, 6, 6, 6, 6, 6))

    # x------ span
    a[2:5].fill(7)
    assert_equal(a, Array(6, 6, 7, 7, 7, 6))

    a[::2].fill(8)
    assert_equal(a, Array(8, 6, 8, 7, 8, 6))
