import numpy as np
import cv2
f = open('track.txt')

image = cv2.imread('track_downsample.bmp')

inner_lines = []
outer_lines = []

while True:
    a = f.readline().strip()
    if a == "inner":
        inner = True
    elif a == 'outer':
        inner = False
    else:
        if a == 'start':
            break
        split = a.split()
        print(split)
        tup = (int(split[0]), int(split[1]))
        if inner:
            inner_lines.append(tup)
        else:
            outer_lines.append(tup)
            
            
for i in range(len(inner_lines)):
    cv2.line(image, inner_lines[i], inner_lines[(i+1)%len(inner_lines)], (0, 0, 0))
    
for i in range(len(outer_lines)):
    cv2.line(image, outer_lines[i], outer_lines[(i+1)%len(outer_lines)], (0, 0, 0))
    
# cv2.imwrite("test.bmp", image)

f.close()

f = open("track_from_image_downsample.txt", 'w')

for i in range(image.shape[0]):
    for j in range(image.shape[0]):
        if image[i][j][0] == 0:
            f.write(str(1) + " ")
        else:
            f.write(str(0) + " ")
        
        
    f.write('\n')