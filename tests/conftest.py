import pytest
import os
import asyncio

from starkware.starknet.testing.starknet import Starknet

# contract and library paths
FP_CONTRACT = os.path.join(os.path.dirname(__file__), "../src/fixed_point.cairo")

DECIMALS = 10**18
HALF_DECIMALS = 10**9


@pytest.fixture(scope="module", autouse=True)
def event_loop():
    return asyncio.new_event_loop()


# contract and object factories
@pytest.fixture(scope="module", autouse=True)
async def starknet_factory():
    starknet = await Starknet.empty()
    return starknet


@pytest.fixture(scope="module", autouse=True)
async def fp_factory(starknet_factory):
    starknet = starknet_factory

    # Deploy the fixed_point contract
    fp_contract = await starknet.deploy(source=FP_CONTRACT)

    return fp_contract
