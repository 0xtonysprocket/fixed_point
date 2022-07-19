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


@pytest.mark.asyncio
async def test_mul(fp_factory):
    fixed_point = fp_factory

    a = to_uint(2345152673865427896541)
    b = to_uint(768102938476645378273)

    res = await fixed_point.mul(a, b).call()
    assert from_uint(res.result[0]) == 2345152673865 * 768102938476


@given(
    x=st.integers(min_value=10**10, max_value=10**45),
    y=st.integers(min_value=10**10, max_value=10**45),
)
@settings(deadline=None)
@pytest.mark.asyncio
async def test_hyp_mul(fp_factory, x, y):
    fixed_point = fp_factory

    a = to_uint(x)
    b = to_uint(y)

    res = await fixed_point.mul(a, b).call()
    assert from_uint(res.result[0]) == (x // HALF_DECIMALS) * (y // HALF_DECIMALS)


@pytest.mark.asyncio
async def test_div(fp_factory):
    fixed_point = fp_factory

    a = to_uint(2345152673865427896541)
    b = to_uint(768102938476645378273)

    res = await fixed_point.div(a, b).call()
    assert (
        from_uint(res.result[0])
        == (2345152673865427896541 * DECIMALS) // 768102938476645378273
    )


@given(
    x=st.integers(min_value=10**10, max_value=10**45),
    y=st.integers(min_value=10**10, max_value=10**45),
)
@settings(deadline=None)
@pytest.mark.asyncio
async def test_hyp_div(fp_factory, x, y):
    fixed_point = fp_factory

    a = to_uint(x)
    b = to_uint(y)

    res = await fixed_point.div(a, b).call()
    assert from_uint(res.result[0]) == (x * DECIMALS) // y
