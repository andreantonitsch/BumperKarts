import sys
import numpy as np
from matplotlib import pyplot as plt
import os 

path = sys.argv[1]

count =  len(os.listdir(path))


print(count)

fitness = {}
max_fit = []
avg_fit = []

for i in range(count):

    f = open(path + "/generation" + str(i) + ".txt")
    
    fitness[i] = []

    while f:
        line = f.readline()[:-1]
        if not line:
            break
        info = line.split()
        if len(info) == 1:
            continue
        fitness[i].append(float(info[0]))

    max_fit.append(max(fitness[i]))
    print(max(fitness[i]))
    avg_fit.append(sum(fitness[i])/len(fitness[i]))
    
    f.close()

# # cria uma sequencia de len(x) pontos de 0 a 1
n = np.arange(count)

plt.plot(n, max_fit,  label='max_fit')
plt.plot(n, avg_fit, label='avg_fit')
plt.show()
