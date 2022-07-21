from decimal import *

getcontext().prec = 18

a = Decimal(1.152673865427896541)
b = Decimal(0.00993333)

c = a**b

print(c)
