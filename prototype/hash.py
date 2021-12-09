import time
import random


ts = str(int(time.time()))  # int for removing the decimals from time.time()
hash = str(random.getrandbits(32))

transctionID = ts+'.'+hash
print(transctionID)

1637536487.1624276202