"""Price an order line: quantity discounts and a capped shipping charge."""

BULK_QUANTITY = 10
BULK_DISCOUNT_PERCENT = 15
FREE_SHIPPING_ABOVE_CENTS = 5000
SHIPPING_CENTS = 499


def line_total_cents(unit_price_cents: int, quantity: int) -> int:
    """Return the price of a line in cents, with the bulk discount applied.

    Raises `ValueError` when the quantity is below one or the unit price is negative.
    """
    if quantity < 1:
        raise ValueError(f"quantity is {quantity}; expected at least 1")
    if unit_price_cents < 0:
        raise ValueError(f"unit_price_cents is {unit_price_cents}; expected 0 or more")
    gross = unit_price_cents * quantity
    if quantity >= BULK_QUANTITY:
        return gross - gross * BULK_DISCOUNT_PERCENT // 100
    return gross


def shipping_cents(subtotal_cents: int) -> int:
    """Return the shipping charge in cents; orders above the free-shipping line pay none."""
    if subtotal_cents >= FREE_SHIPPING_ABOVE_CENTS:
        return 0
    return SHIPPING_CENTS


def order_total_cents(lines: list[tuple[int, int]]) -> int:
    """Return the order total in cents for a list of (unit_price_cents, quantity) lines."""
    subtotal = sum(line_total_cents(price, quantity) for price, quantity in lines)
    return subtotal + shipping_cents(subtotal)
