# inspired by https://github.com/balancer-labs/balancer-core/blob/master/contracts/BNum.sol
# We already have badd, bsub, bsubSign from openzeppelin-cairo-contracts SafeUint256
# Apache License 2.0

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from openzeppelin.security.safemath import SafeUint256
from config import DECIMALS, HALF_DECIMALS, PRECISION

namespace FixedPoint:
    @view
    func floor_intermediate{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
            a : Uint256) -> (b : Uint256):
        alloc_locals

        let (local b : Uint256, _) = SafeUint256.div_rem(a, Uint256(DECIMALS, 0))

        return (b)
    end

    # computes the integer floor given DECIMALS
    @view
    func floor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(a : Uint256) -> (
            floor : Uint256):
        alloc_locals

        let (local b : Uint256) = floor_intermediate(a)
        let (local floor : Uint256) = SafeUint256.mul(b, Uint256(DECIMALS, 0))

        return (floor)
    end

    # Change scaling factor to half the decimal places
    @view
    func half_scaling{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
            a : Uint256) -> (b : Uint256):
        alloc_locals

        let (local b : Uint256, _) = SafeUint256.div_rem(a, Uint256(HALF_DECIMALS, 0))

        return (b)
    end

    # Change scaling factor to double the decimal places
    @view
    func double_scaling{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
            a : Uint256) -> (b : Uint256):
        alloc_locals

        let (local b : Uint256) = SafeUint256.mul(a, Uint256(DECIMALS, 0))

        return (b)
    end

    # fixed point multiplication
    # multiply the two underlying integers and then multiply the scaling factors
    # so we half the scaling factors then multiply to get an answer with DECIMALS precision
    @view
    func mul{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
            a : Uint256, b : Uint256) -> (c : Uint256):
        alloc_locals

        let (local scaled_a : Uint256) = half_scaling(a)
        let (local scaled_b : Uint256) = half_scaling(b)

        let (local c : Uint256) = SafeUint256.mul(scaled_a, scaled_b)

        return (c)
    end

    # fixed point division
    # divide the two underlying integers and then divide the scaling factors
    # so we double the scaling factor of the numerator then divide to get an answer with DECIMALS precision
    @view
    func div{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
            num : Uint256, den : Uint256) -> (c : Uint256):
        alloc_locals

        let (local scaled_num : Uint256) = double_scaling(num)

        let (local c : Uint256, _) = SafeUint256.div_rem(scaled_num, den)

        return (c)
    end
end
