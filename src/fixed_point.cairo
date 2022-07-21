# inspired by https://github.com/balancer-labs/balancer-core/blob/master/contracts/BNum.sol
# We already have badd, bsub, bsubSign from openzeppelin-cairo-contracts SafeUint256
# Apache License 2.0

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_eq, uint256_le
from starkware.cairo.common.bool import TRUE, FALSE
from openzeppelin.security.safemath import SafeUint256
from src.config import (
    DECIMALS, HALF_DECIMALS, PRECISION, MAX_DECIMAL_POW_BASE, MIN_DECIMAL_POW_BASE)

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

    # addition wrapper
    @view
    func add{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
            a : Uint256, b : Uint256) -> (c : Uint256):
        alloc_locals

        let (local c : Uint256) = SafeUint256.add(a, b)

        return (c)
    end

    # subtraction wrapper
    @view
    func sub{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
            a : Uint256, b : Uint256) -> (c : Uint256):
        alloc_locals

        let (local c : Uint256) = SafeUint256.sub_le(a, b)

        return (c)
    end

    # difference and boolean to inform sign
    @view
    func diff_and_sign{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
            a : Uint256, b : Uint256) -> (c : Uint256, bool : felt):
        alloc_locals

        let (local b_le_a : felt) = uint256_le(b, a)
        if b_le_a == TRUE:
            let (local diff : Uint256) = SafeUint256.sub_le(a, b)
            return (diff, FALSE)
        else:
            let (local diff : Uint256) = SafeUint256.sub_lt(b, a)
            return (diff, TRUE)
        end
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
            return (Uint256(DECIMALS, 0))
        end

        let (local is_one : felt) = uint256_eq(exponent, Uint256(1, 0))
        if is_one == TRUE:
            return (base)
        end

        let (local product : Uint256) = _recursive_integer_pow(base, base, exponent)

        return (product)
    end

    @view
    func _recursive_integer_pow{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
            current_product : Uint256, base : Uint256, exponent : Uint256) -> (c : Uint256):
        alloc_locals

        let (local is_one : felt) = uint256_eq(exponent, Uint256(1, 0))
        if is_one == TRUE:
            return (current_product)
        end

        let (local new_product : Uint256) = mul(current_product, base)

        let (local new_exponent : Uint256) = SafeUint256.sub_le(exponent, Uint256(1, 0))
        let (local final_product : Uint256) = _recursive_integer_pow(
            new_product, base, new_exponent)

        return (final_product)
    end

    # x^y where y in real numbers in (0, 1) and
    # x is fixed point representation between MIN_DECIMAL_POW_BASE and MAX_DECIMAL_POW_BASE
    # this function is a taylor series expansion of x^y and stops being effcient as x approaches 0 or 2
    # thus it is advised to keep MIN_DECIMAL_POW_BASE > 0 and MAX_DECIMAL_POW_BASE < 2
    @view
    func bounded_decimal_pow{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
            base : Uint256, exponent : Uint256, precision : Uint256) -> (result : Uint256):
        alloc_locals

        # first element in taylor expansion
        local first_element : Uint256 = Uint256(DECIMALS, 0)
        local initial_index : Uint256 = Uint256(1, 0)
        let (local base_minus_one : Uint256, base_minus_center_sign : felt) = diff_and_sign(
            base, Uint256(DECIMALS, 0))

        let (local result : Uint256) = _recursive_decimal_pow(
            base_minus_one,
            exponent,
            precision,
            first_element,
            initial_index,
            first_element,
            base_minus_center_sign,
            FALSE)

        return (result)
    end

    # product(exponent - index - 1, for index 1 through n) * x^n/n!
    # each new term we multiply previous term by
    # (exponent - index - 1) * base / index
    # this is taylor series expansion of x^y centered at 1
    # thus x bounded between (0, 2) practically
    @view
    func _recursive_decimal_pow{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
            base_minus_one : Uint256, exponent : Uint256, precision : Uint256,
            previous_element : Uint256, index : Uint256, current_sum : Uint256,
            base_minus_center_sign : felt, previous_sign : felt) -> (final_sum : Uint256):
        alloc_locals

        # if the last term is less than our desired precision
        # then end the recursion
        let (local precision_met : felt) = uint256_le(previous_element, precision)
        if precision_met == TRUE:
            return (current_sum)
        end

        let (local n : Uint256) = SafeUint256.mul(index, Uint256(DECIMALS, 0))
        let (local index_for_derivative : Uint256) = sub(n, Uint256(DECIMALS, 0))
        let (local derivative_coefficient : Uint256, derivative_sign : felt) = diff_and_sign(
            exponent, index_for_derivative)
        let (local new_part_of_numerator : Uint256) = mul(derivative_coefficient, base_minus_one)
        let (local new_element_numerator : Uint256) = mul(previous_element, new_part_of_numerator)
        let (local new_element : Uint256) = div(new_element_numerator, n)

        # equal TRUE - previous_sign if derivative_sign == 1 and base_minus_center_sign == 0 or derivative_sign == 0 and base_minus_center_sign == 1
        # else previous_sign
        local is_negative : felt = base_minus_center_sign + derivative_sign
        local new_sign : felt = ((TRUE - base_minus_center_sign) * derivative_sign + (TRUE - derivative_sign) * base_minus_center_sign) * (TRUE - previous_sign) + (base_minus_center_sign * derivative_sign + ((TRUE - base_minus_center_sign) * (TRUE - derivative_sign)) * previous_sign)

        let (local new_index : Uint256) = add(index, Uint256(1, 0))

        if new_sign == TRUE:
            let (local new_sum : Uint256) = sub(current_sum, new_element)
            let (local final_sum : Uint256) = _recursive_decimal_pow(
                base_minus_one,
                exponent,
                precision,
                new_element,
                new_index,
                new_sum,
                base_minus_center_sign,
                new_sign)
            return (final_sum)
        else:
            let (local new_sum : Uint256) = add(current_sum, new_element)
            let (local final_sum : Uint256) = _recursive_decimal_pow(
                base_minus_one,
                exponent,
                precision,
                new_element,
                new_index,
                new_sum,
                base_minus_center_sign,
                new_sign)
            return (final_sum)
        end
    end

    # x^y where y is fixed point representation and x between MIN and MAX bounds
    @view
    func bounded_pow{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
            base : Uint256, exponent : Uint256) -> (result : Uint256):
        alloc_locals

        assert_base_within_bound(base)

        let (local integer_part_exponent : Uint256) = floor(exponent)
        let (local precision_part_exponent : Uint256) = sub(exponent, integer_part_exponent)

        let (local integer_pow_no_fixed_point : Uint256) = floor_intermediate(integer_part_exponent)
        let (local integer_part_pow) = integer_pow(base, integer_pow_no_fixed_point)

        # if there is no precision part then return
        let (local is_zero : felt) = uint256_eq(precision_part_exponent, Uint256(0, 0))
        if is_zero == 1:
            return (integer_part_pow)
        end

        let (local precision_part_pow : Uint256) = bounded_decimal_pow(
            base, precision_part_exponent, Uint256(PRECISION, 0))

        let (local is_z : felt) = uint256_eq(precision_part_pow, Uint256(0, 0))
        if is_z == 1:
            local r : Uint256 = Uint256(2, 0)
            return (r)
        end

        let (local result : Uint256) = mul(integer_part_pow, precision_part_pow)

        return (result)
    end

    # helper to check base is in range
    @view
    func assert_base_within_bound{
            syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(base : Uint256):
        alloc_locals

        let (local less_than_max : felt) = uint256_le(base, Uint256(MAX_DECIMAL_POW_BASE, 0))
        let (local min_less_than : felt) = uint256_le(Uint256(MIN_DECIMAL_POW_BASE, 0), base)

        with_attr error_message("ERROR: BASE FOR EXP FUNCTION GREATER THAN MAX BOUND"):
            assert less_than_max = 1
        end

        with_attr error_message("ERROR: BASE FOR EXP FUNCTION LESS THAN MIN"):
            assert min_less_than = 1
        end
        return ()
    end
end
