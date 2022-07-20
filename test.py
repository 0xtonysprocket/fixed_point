from decimal import *

getcontext().prec = 18

a = Decimal(1.152673865427896541)
b = Decimal(28.102938476645378273)

c = a**b

print(c)
