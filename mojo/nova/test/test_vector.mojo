from testing import *
from nova.testing import *

from sys.intrinsics import _type_is_eq
from nova import Vector

def main():
    test_dtype[DType.bool]()
    test_dtype[DType.int8]()
    test_dtype[DType.int16]()
    test_dtype[DType.int32]()
    test_dtype[DType.int64]()
    test_dtype[DType.uint8]()
    test_dtype[DType.uint16]()
    test_dtype[DType.uint32]()
    test_dtype[DType.uint64]()
    test_dtype[DType.float16]()
    test_dtype[DType.float32]()
    test_dtype[DType.float64]()
    test_dtype[DType.index]()

    @parameter
    if not has_neon():
        test_dtype[DType.bfloat16]()


def test_dtype[type: DType]():
    test_equal[type]()
    test_init[type]()
    test_is[type]()
    test_length[type]()
    # test_truthy[type]()
    test_subscript[type]()
    test_contains[type]()
    test_any[type]()
    test_all[type]()
    test_fill[type]()
    test_clear[type]()
    test_comparison[type]()
    test_add[type]()
    test_sub[type]()
    test_and[type]()
    test_or[type]()


def test_equal[type: DType]():
    assert_equal(Vector[type](), Vector[type]())
    assert_equal(Vector[type](0), Vector[type](0))
    assert_equal(Vector[type](9), Vector[type](9))
    assert_equal(Vector[type](0, 1, 2), Vector[type](0, 1, 2))
    assert_equal(Vector[type](2, 1, 0), Vector[type](2, 1, 0))
    assert_not_equal(Vector[type](0, 1, 2), Vector[type]())
    assert_not_equal(Vector[type](0, 1, 2), Vector[type](0))
    assert_not_equal(Vector[type](0, 1, 2), Vector[type](0, 1))
    assert_not_equal(Vector[type](0, 1, 2), Vector[type](2, 1, 0))
    assert_not_equal(Vector[type](0, 1, 2), Vector[type](0, 1, 2, 3))


def test_init[type: DType]():
    assert_true(_type_is_eq[__type_of(Vector(Scalar[type](1))), Vector[type]]())
    assert_true(_type_is_eq[__type_of(Vector(SIMD[type,2](1, 2))), Vector[type]]())
    assert_true(_type_is_eq[__type_of(Vector(Vector[type](1))), Vector[type]]())

    assert_equal(Vector[type](size = 0), Vector[type]())
    assert_equal(Vector[type](size = 1), Vector[type](0))
    assert_equal(Vector[type](size = 2), Vector[type](0, 0))
    assert_equal(Vector[type](size = 3), Vector[type](0, 0, 0))
    assert_equal(Vector[type](1, size = 0), Vector[type]())
    assert_equal(Vector[type](2, size = 1), Vector[type](2))
    assert_equal(Vector[type](3, size = 2), Vector[type](3, 3))
    assert_equal(Vector[type](4, size = 3), Vector[type](4, 4, 4))
    assert_equal(Vector[type](0, 1, size = 0), Vector[type]())
    assert_equal(Vector[type](0, 1, size = 1), Vector[type](0))
    assert_equal(Vector[type](0, 1, size = 2), Vector[type](0, 1))
    assert_equal(Vector[type](0, 1, size = 3), Vector[type](0, 1, 0))
    assert_equal(Vector[type](0, 1, size = 4), Vector[type](0, 1, 0, 1))
    assert_equal(Vector[type](0, 1, size = 5), Vector[type](0, 1, 0, 1, 0))
    assert_equal(Vector[type](2, 1, 0, size = 0), Vector[type]())
    assert_equal(Vector[type](2, 1, 0, size = 1), Vector[type](2))
    assert_equal(Vector[type](2, 1, 0, size = 2), Vector[type](2, 1))
    assert_equal(Vector[type](2, 1, 0, size = 3), Vector[type](2, 1, 0))
    assert_equal(Vector[type](2, 1, 0, size = 4), Vector[type](2, 1, 0, 2))
    assert_equal(Vector[type](2, 1, 0, size = 5), Vector[type](2, 1, 0, 2, 1))
    assert_equal(Vector[type](2, 1, 0, size = 6), Vector[type](2, 1, 0, 2, 1, 0))
    assert_equal(Vector[type](2, 1, 0, size = 7), Vector[type](2, 1, 0, 2, 1, 0, 2))

    var x1 = SIMD[type, 2](0, 1)
    var x2 = SIMD[type, 2](2, 3)
    assert_equal(Vector[type](x1), Vector[type](0, 1))
    assert_equal(Vector[type](x1, size = 0), Vector[type]())
    assert_equal(Vector[type](x1, size = 1), Vector[type](0))
    assert_equal(Vector[type](x1, size = 2), Vector[type](0, 1))
    assert_equal(Vector[type](x1, size = 3), Vector[type](0, 1, 0))
    assert_equal(Vector[type](x1, x2), Vector[type](0, 1, 2, 3))
    assert_equal(Vector[type](x1, x2, size = 0), Vector[type]())
    assert_equal(Vector[type](x1, x2, size = 1), Vector[type](0))
    assert_equal(Vector[type](x1, x2, size = 2), Vector[type](0, 1))
    assert_equal(Vector[type](x1, x2, size = 3), Vector[type](0, 1, 2))
    assert_equal(Vector[type](x1, x2, size = 4), Vector[type](0, 1, 2, 3))
    assert_equal(Vector[type](x1, x2, size = 5), Vector[type](0, 1, 2, 3, 0))
    assert_equal(Vector[type](x1, x2, size = 6), Vector[type](0, 1, 2, 3, 0, 1))
    assert_equal(Vector[type](x1, x2, size = 7), Vector[type](0, 1, 2, 3, 0, 1, 2))
    assert_equal(Vector[type](x1, x2, size = 8), Vector[type](0, 1, 2, 3, 0, 1, 2, 3))
    assert_equal(Vector[type](x1, x2, size = 9), Vector[type](0, 1, 2, 3, 0, 1, 2, 3, 0))

    var v1 = Vector[type](3, 2, 1)
    var v2 = Vector[type](0)
    assert_equal(Vector[type](v1), Vector[type](3, 2, 1))
    assert_equal(Vector[type](v1, size = 0), Vector[type]())
    assert_equal(Vector[type](v1, size = 1), Vector[type](3))
    assert_equal(Vector[type](v1, size = 2), Vector[type](3, 2))
    assert_equal(Vector[type](v1, size = 3), Vector[type](3, 2, 1))
    assert_equal(Vector[type](v1, size = 4), Vector[type](3, 2, 1, 3))
    assert_equal(Vector[type](v1, v2), Vector[type](3, 2, 1, 0))
    assert_equal(Vector[type](v1, v2, size = 0), Vector[type]())
    assert_equal(Vector[type](v1, v2, size = 1), Vector[type](3))
    assert_equal(Vector[type](v1, v2, size = 2), Vector[type](3, 2))
    assert_equal(Vector[type](v1, v2, size = 3), Vector[type](3, 2, 1))
    assert_equal(Vector[type](v1, v2, size = 4), Vector[type](3, 2, 1, 0))
    assert_equal(Vector[type](v1, v2, size = 5), Vector[type](3, 2, 1, 0, 3))
    assert_equal(Vector[type](v1, v2, size = 6), Vector[type](3, 2, 1, 0, 3, 2))
    assert_equal(Vector[type](v1, v2, size = 7), Vector[type](3, 2, 1, 0, 3, 2, 1))
    assert_equal(Vector[type](v1, v2, size = 8), Vector[type](3, 2, 1, 0, 3, 2, 1, 0))
    assert_equal(Vector[type](v1, v2, size = 9), Vector[type](3, 2, 1, 0, 3, 2, 1, 0, 3))


def test_is[type: DType]():
    var a = Vector[type](1, 2, 3)
    var b = a
    var c = Reference(a)
    assert_is(a, a)
    assert_is_not(a, b)
    assert_is(a, c[])


def test_length[type: DType]():
    assert_equal(Vector[type]().__len__(), 0)
    assert_equal(Vector[type](0).__len__(), 1)
    assert_equal(Vector[type](1,2).__len__(), 2)
    assert_equal(Vector[type](3,4,5).__len__(), 3)


# def test_truthy[type: DType]():
#     assert_false(Vector[type]())
#     assert_true(Vector[type](0))
#     assert_true(Vector[type](1,2))
#     assert_true(Vector[type](3,4,5))


def test_subscript[type: DType]():
    var a = Vector[type](0, 0, 0, 0, 0)
    a[0] = 2
    a[1] = 6
    a[4] = 3
    assert_equal(a[0], 2)
    assert_equal(a[1], 6)
    assert_equal(a[4], 3)


def test_contains[type: DType]():
    var a = Vector[type]()
    assert_false(a.__contains__(0))
    assert_false(a.__contains__(1))
    a = Vector[type](0)
    assert_true(a.__contains__(0))
    assert_false(a.__contains__(1))
    a = Vector[type](1)
    assert_false(a.__contains__(0))
    assert_true(a.__contains__(1))

    @parameter
    if type == DType.bool:
        a = Vector[type](0, 0)
        assert_true(a.__contains__(0))
        assert_false(a.__contains__(1))
        a = Vector[type](0, 1)
        assert_true(a.__contains__(0))
        assert_true(a.__contains__(1))
        a = Vector[type](1, 0)
        assert_true(a.__contains__(0))
        assert_true(a.__contains__(1))
        a = Vector[type](1, 1)
        assert_false(a.__contains__(0))
        assert_true(a.__contains__(1))
        a = Vector[type](0, 0, 0, 0, 0, 0)
        assert_true(a.__contains__(0))
        assert_false(a.__contains__(1))
        a = Vector[type](0, 0, 0, 0, 1, 0)
        assert_true(a.__contains__(0))
        assert_true(a.__contains__(1))
        a = Vector[type](1, 1, 1, 0, 1, 1)
        assert_true(a.__contains__(0))
        assert_true(a.__contains__(1))
        a = Vector[type](1, 1, 1, 1, 1, 1)
        assert_false(a.__contains__(0))
        assert_true(a.__contains__(1))
    else:
        a = Vector[type](2, 5)
        assert_true(a.__contains__(2))
        assert_true(a.__contains__(5))
        assert_false(a.__contains__(0))
        assert_false(a.__contains__(1))
        a = Vector[type](0, 1, 2)
        assert_true(a.__contains__(0))
        assert_true(a.__contains__(1))
        assert_true(a.__contains__(2))
        assert_false(a.__contains__(3))
        a = Vector[type](4, 3, 2, 1, 0)
        assert_true(a.__contains__(0))
        assert_false(a.__contains__(5))
        a = Vector[type](0, 1, 2, 3, 4, 5, 6, 7, 8)
        assert_true(a.__contains__(4))
        assert_false(a.__contains__(9))


def test_any[type: DType]():
    assert_false(Vector[type]().__any__())
    assert_false(Vector[type](0).__any__())
    assert_false(Vector[type](0, 0).__any__())
    assert_true(Vector[type](1, 0).__any__())
    assert_true(Vector[type](0, 2).__any__())
    assert_true(Vector[type](3, 4).__any__())
    assert_false(Vector[type](0, 0, 0, 0, 0, 0, 0, 0, 0, 0).__any__())
    assert_true(Vector[type](1, 0, 0, 0, 0, 0, 0, 0, 0, 0).__any__())
    assert_true(Vector[type](0, 0, 0, 0, 0, 1, 0, 0, 0, 0).__any__())
    assert_true(Vector[type](0, 0, 0, 0, 0, 0, 0, 0, 0, 1).__any__())


def test_all[type: DType]():
    assert_true(Vector[type]().__all__())
    assert_true(Vector[type](1).__all__())
    assert_true(Vector[type](2, 3).__all__())
    assert_false(Vector[type](0, 4).__all__())
    assert_false(Vector[type](5, 0).__all__())
    assert_false(Vector[type](0, 0).__all__())
    assert_true(Vector[type](1, 1, 1, 1, 1, 1, 1, 1, 1, 1).__all__())
    assert_false(Vector[type](0, 1, 1, 1, 1, 1, 1, 1, 1, 1).__all__())
    assert_false(Vector[type](1, 1, 1, 1, 1, 0, 1, 1, 1, 1).__all__())
    assert_false(Vector[type](1, 1, 1, 1, 1, 1, 1, 1, 1, 0).__all__())


def test_fill[type: DType]():
    var a = Vector[type]()
    a.fill(1)
    assert_equal(a, Vector[type]())
    a = Vector[type](1)
    a.fill(2)
    assert_equal(a, Vector[type](2))
    a = Vector[type](1, 2)
    a.fill(3)
    assert_equal(a, Vector[type](3, 3))
    a = Vector[type](1, 2, 3)
    a.fill(4)
    assert_equal(a, Vector[type](4, 4, 4))
    a = Vector[type](0, 1, 2, 3, 4, 5, 6, 7, 8, 9)
    a.fill(5)
    assert_equal(a, Vector[type](5, 5, 5, 5, 5, 5, 5, 5, 5, 5))


def test_clear[type: DType]():
    var a = Vector[type]()
    a.clear()
    assert_equal(a, Vector[type]())
    a = Vector[type](1)
    a.clear()
    assert_equal(a, Vector[type](0))
    a = Vector[type](1, 2)
    a.clear()
    assert_equal(a, Vector[type](0, 0))
    a = Vector[type](1, 2, 3)
    a.clear()
    assert_equal(a, Vector[type](0, 0, 0))
    a = Vector[type](0, 1, 2, 3, 4, 5, 6, 7, 8, 9)
    a.clear()
    assert_equal(a, Vector[type](0, 0, 0, 0, 0, 0, 0, 0, 0, 0))


def test_comparison[type: DType]():
    @parameter
    if type.is_numeric():
        assert_equal(Vector[type](1,2,3,4,5) > Vector[type](5,4,3,2,1), Vector[DType.bool](0,0,0,1,1))


def test_add[type: DType]():
    @parameter
    if type.is_numeric():
        assert_equal(Vector[type](1,2,3,4,5) + Vector[type](5,4,3,2,1), Vector[type](6,6,6,6,6))


def test_sub[type: DType]():
    @parameter
    if type.is_numeric():
        assert_equal(Vector[type](6,6,6,6,6) - Vector[type](5,4,3,2,1), Vector[type](1,2,3,4,5))


def test_and[type: DType]():
    @parameter
    if type.is_integral():
        assert_equal(Vector[type](1,2,3,4,5) & Vector[type](5,4,3,2,1), Vector[type](1,0,3,0,1))


def test_or[type: DType]():
    @parameter
    if type.is_integral():
        assert_equal(Vector[type](1,2,3,4,5) | Vector[type](5,4,3,2,1), Vector[type](5,6,3,6,5))