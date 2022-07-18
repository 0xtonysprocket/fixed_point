# inspired by https://github.com/balancer-labs/balancer-core/blob/master/contracts/BNum.sol
# We already have badd, bsub, bsubSign from openzeppelin-cairo-contracts SafeUint256
# Apache License 2.0

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_eq
from starkware.cairo.common.bool import TRUE, FALSE
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

    # x^y where x is fixed point representation and y is an integer
    @view
    func integer_pow{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
            base : Uint256, exponent : Uint256) -> (c : Uint256):
        alloc_locals

        let (local is_zero : felt) = uint256_eq(exponent, Uint256(0, 0))
        if is_zero == TRUE:
            return (1)
        end

        let (local is_one : felt) = uint256_eq(exponent, Uint256(1, 0))
        if is_one == TRUE:
            return (base)
        end

        let (local product : Uint256) = _recurse_integer_pow(base, base, exponent)

        return (product)
    end

    @view
    func _recurse_integer_pow{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
            current_product : Uint256, base : Uint256, exponent : Uint256) -> (c : Uint256):
        alloc_locals

        let (local is_one : felt) = uint256_eq(exponent, Uint256(1, 0))
        if is_one == TRUE:
            return (current_product)
        end

        let (local new_product : Uint256) = mul(current_product, base)

        let (local new_exponent : Uint256) = SafeUint256.sub(exponent, 1)
        let (local final_product : Uint256) = _recurse_integer_pow(new_product, base, new_exponent)

        return (final_product)
    end
end
