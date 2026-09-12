import pytest

from pricing import line_total_cents, order_total_cents, shipping_cents


def test_single_unit_costs_its_unit_price():
    assert line_total_cents(250, 1) == 250


def test_nine_units_pay_full_price():
    assert line_total_cents(100, 9) == 900


def test_ten_units_get_fifteen_percent_off():
    assert line_total_cents(100, 10) == 850


def test_discount_rounds_down_to_whole_cents():
    assert line_total_cents(33, 10) == 281


def test_zero_unit_price_totals_zero():
    assert line_total_cents(0, 3) == 0


def test_rejects_zero_quantity():
    with pytest.raises(ValueError, match="quantity is 0; expected at least 1"):
        line_total_cents(100, 0)


def test_rejects_negative_unit_price():
    with pytest.raises(ValueError, match="unit_price_cents is -1; expected 0 or more"):
        line_total_cents(-1, 1)


def test_order_below_free_shipping_line_pays_shipping():
    assert shipping_cents(4999) == 499


def test_order_at_free_shipping_line_pays_nothing():
    assert shipping_cents(5000) == 0


def test_order_total_adds_shipping_to_lines():
    assert order_total_cents([(1000, 2), (500, 1)]) == 2999


def test_order_total_with_bulk_line_above_free_shipping_pays_no_shipping():
    assert order_total_cents([(600, 10)]) == 5100
