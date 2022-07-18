# inspired by https://github.com/balancer-labs/balancer-core/blob/master/contracts/BNum.sol
# We already have badd, bsub, bsubSign, bmul, and bdiv from openzeppelin-cairo-contracts SafeUint256
# Apache License 2.0

%lang starknet

from starkware.cairo.common.uint256 import Uint256
from openzeppelin.security.safemath import SafeUint256
from config import DECIMALS, HALF_DECIMALS, PRECISION

namespace FixedPoint:
    @view
    func floor_intermediate{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
            a : Uint256) -> (b : Uint256):
        alloc_locals

        let (local b : Uint256, _) = SafeUint256.div_rem(a, DECIMALS)

        return (b)
    end

    # computes the integer floor given DECIMALS
    @view
    func floor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(a : Uint256) -> (
            floor : Uint256):
        alloc_locals

        let (local b : Uint256) = floor_intermediate(a)
        let (local floor : Uint256) = SafeUint256.mul(b, DECIMALS)

        return (floor)
    end

    # Change scaling factor to half the decimal places
    @view
    func half_scaling{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
            a : Uint256) -> (b : Uint256):
        alloc_locals

        let (local b : Uint256, _) = SafeUint256.div_rem(a, HALF_DECIMALS)

        return (b)
    end

    # Change scaling factor to double the decimal places
    @view
    func double_scaling{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
            a : Uint256) -> (b : Uint256):
        alloc_locals

        let (local b : Uint256, _) = SafeUint256.mul(a, DECIMALS)

        return (b)
    end
end
