import pytest
from hypothesis import given, strategies as st, settings
from .conftest import DECIMALS, HALF_DECIMALS

# from OZ utils.py
def to_uint(a):
    """Takes in value, returns uint256-ish tuple."""
    return (a & ((1 << 128) - 1), a >> 128)


def from_uint(uint):
    """Takes in uint256-ish tuple, returns value."""
    return uint[0] + (uint[1] << 128)


@pytest.mark.asyncio
async def test_floor_intermediate(fp_factory):
    fixed_point = fp_factory

    a = to_uint(2345152673865427896541)

    res = await fixed_point.floor_intermediate(a).call()
    assert from_uint(res.result[0]) == (2345)


@given(
    x=st.integers(min_value=10**17, max_value=10**42),
)
@settings(deadline=None)
@pytest.mark.asyncio
async def test_hyp_floor_intermediate(fp_factory, x):
    fixed_point = fp_factory

    a = to_uint(x)

    res = await fixed_point.floor_intermediate(a).call()
    assert from_uint(res.result[0]) == (x // DECIMALS)


@pytest.mark.asyncio
async def test_floor(fp_factory):
    fixed_point = fp_factory

    a = to_uint(2345152673865427896541)

    res = await fixed_point.floor(a).call()
    assert from_uint(res.result[0]) == (2345 * DECIMALS)


@given(
    x=st.integers(min_value=10**17, max_value=10**42),
)
@settings(deadline=None)
@pytest.mark.asyncio
async def test_hyp_floor(fp_factory, x):
    fixed_point = fp_factory

    a = to_uint(x)

    res = await fixed_point.floor(a).call()
    assert from_uint(res.result[0]) == ((x // DECIMALS) * DECIMALS)


@pytest.mark.asyncio
async def test_half_scaling(fp_factory):
    fixed_point = fp_factory

    a = to_uint(2345152673865427896541)

    res = await fixed_point.half_scaling(a).call()
    assert from_uint(res.result[0]) == (2345152673865)


@pytest.mark.asyncio
async def test_double_scaling(fp_factory):
    fixed_point = fp_factory

    a = to_uint(2345152673865427896541)

    res = await fixed_point.double_scaling(a).call()
    assert from_uint(res.result[0]) == (2345152673865427896541 * 10**18)


@pytest.mark.asyncio
async def test_add(fp_factory):
    fixed_point = fp_factory

    a = to_uint(2345152673865427896541)
    b = to_uint(768102938476645378273)

    res = await fixed_point.add(a, b).call()
    assert from_uint(res.result[0]) == (2345152673865427896541 + 768102938476645378273)


@pytest.mark.asyncio
async def test_sub(fp_factory):
    fixed_point = fp_factory

    a = to_uint(2345152673865427896541)
    b = to_uint(768102938476645378273)

    res = await fixed_point.sub(a, b).call()
    assert from_uint(res.result[0]) == (2345152673865427896541 - 768102938476645378273)


@pytest.mark.asyncio
async def test_diff_and_sign_false(fp_factory):
    fixed_point = fp_factory

    a = to_uint(2345152673865427896541)
    b = to_uint(768102938476645378273)

    res = await fixed_point.diff_and_sign(a, b).call()
    assert from_uint(res.result[0]) == (2345152673865427896541 - 768102938476645378273)
    assert res.result[1] == 0


@pytest.mark.asyncio
async def test_diff_and_sign_true(fp_factory):
    fixed_point = fp_factory

    a = to_uint(2345152673865427896541)
    b = to_uint(768102938476645378273)

    res = await fixed_point.diff_and_sign(b, a).call()
    assert from_uint(res.result[0]) == (2345152673865427896541 - 768102938476645378273)
    assert res.result[1] == 1


'''
@given(
    x=st.integers(min_value=1, max_value=100000),
    y=st.integers(min_value=1, max_value=100000),
    z=st.integers(min_value=1, max_value=100000),
    k=st.integers(min_value=1, max_value=100000),
)
@settings(deadline=None)
@pytest.mark.asyncio
async def test_ratio_le_eq(fp_factory, x, y, z, k):
    fixed_point = fp_factory

    base = (to_uint(x), to_uint(y))  # x/y
    other = (to_uint(z), to_uint(k))  # z/k

    root = await fixed_point.ratio_less_than_or_eq(base, other).call()
    print(root.result)
    print(root.result[0])
    assert root.result[0] == (1 if x / y <= z / k else 0)


@given(
    x=st.integers(min_value=1, max_value=100000),
    y=st.integers(min_value=1, max_value=100000),
    z=st.integers(min_value=1, max_value=100000),
    k=st.integers(min_value=1, max_value=100000),
)
@settings(deadline=None)
@pytest.mark.asyncio
async def test_ratio_mul(fp_factory, x, y, z, k):
    ratio = fp_factory

    base = (to_uint(x), to_uint(y))  # x/y
    other = (to_uint(z), to_uint(k))  # exponent

    root = await ratio.ratio_mul(base, other).call()
    assert (from_uint(root.result[0][0]), from_uint(root.result[0][1])) == (
        x * z,
        y * k,
    )


@given(
    x=st.integers(min_value=1, max_value=100),
    y=st.integers(min_value=1, max_value=100),
    z=st.integers(min_value=1, max_value=9),
)
@settings(deadline=None)
@pytest.mark.asyncio
async def test_ratio_pow(fp_factory, x, y, z):
    ratio = fp_factory

    base = (to_uint(x), to_uint(y))  # x/y
    power = to_uint(z)  # exponent

    root = await ratio.ratio_pow(base, power).call()
    assert (from_uint(root.result[0][0]), from_uint(root.result[0][1])) == (
        x**z,
        y**z,
    )


"""
"""


@given(
    x=st.integers(min_value=1, max_value=100000),
    y=st.integers(min_value=1, max_value=100000),
    z=st.integers(min_value=1, max_value=100000),
    k=st.integers(min_value=1, max_value=100000),
)
@settings(deadline=None)
@pytest.mark.asyncio
async def test_ratio_add(fp_factory, x, y, z, k):
    ratio = fp_factory

    base = (to_uint(x), to_uint(y))  # x/y
    other = (to_uint(z), to_uint(k))  # exponent

    root = await ratio.ratio_add(base, other).call()
    assert (from_uint(root.result[0][0]), from_uint(root.result[0][1])) == (
        (x * k + y * z, y * k) if y != k else (x + z, y)
    )


@given(
    x=st.integers(min_value=1, max_value=10000),
    y=st.integers(min_value=1, max_value=10000),
    m=st.integers(min_value=1, max_value=7),
    p=st.integers(min_value=5, max_value=11),
)
@settings(deadline=None)
@pytest.mark.asyncio
async def test_nth_root_by_digit(fp_factory, x, y, m, p):
    ratio = fp_factory

    base = (to_uint(x), to_uint(y))  # x/y
    root = to_uint(m)  # which root
    precision = p  # how many digits

    root = await ratio.nth_root_by_digit(base, root, precision).call()
    res = math.floor(((x / y) ** (1 / m)) * 10**p) / (10**p)
    assert (from_uint(root.result[0][0]) / from_uint(root.result[0][1]) - res) < (
        5 / (10**p)
    )
    '''
