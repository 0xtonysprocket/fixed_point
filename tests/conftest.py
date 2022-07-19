import pytest
import os
import asyncio

from starkware.starknet.testing.starknet import Starknet

# contract and library paths
FP_CONTRACT = os.path.join(os.path.dirname(__file__), "../contracts/fp.cairo")

DECIMALS = 1 * 10**18


@pytest.fixture(scope="module")
def event_loop():
    return asyncio.new_event_loop()


# contract and object factories
@pytest.fixture(scope="module")
async def starknet_factory():
    starknet = await Starknet.empty()
    return starknet


@pytest.fixture(scope="module")
async def fp_factory(starknet_factory):
    starknet = starknet_factory

    # Deploy the account contract
    fp_contract = await starknet.deploy(source=FP_CONTRACT)

    return fp_contract
