from mpl_toolkits.mplot3d import Axes3D
from matplotlib import rcParams
import matplotlib
matplotlib.use("TkAgg")
import matplotlib.pyplot as plt
import matplotlib.colors as colors
import numpy as np
import math 
from scipy.optimize import fsolve
import itertools
import csv
import serial
from threading import Thread
import queue as queue
import sys, traceback
import matplotlib.animation as animation
import asyncio
import time
import socket
from scipy import ndimage
from collections import deque


TCP_IP = '127.0.0.1'
TCP_PORT = 2337
BUFFER_SIZE = 1024
DATA_LENGTH = 64
NA = np.array([-1., -1.])
MAX_NUM_CENTORS = 5
slope = np.array([2.301677934,2.063762825,1.03391249,0.3649959796,0.3400758869,2.244405441,0.359399465,0.2173722835,3.966966,0.5443625948,0.8671992347,1.260503994,0.2565711195,0.237680805,0.373553397,0.3338440363]).astype(np.float)
# intercept = np.array([760.7200811,469.0137383,498.3055184,292.3110538,343.9096552,536.6512874,509.6089657,463.0360338,430.0406523,707.4647486,628.8670323,338.9216782,454.0888636,455.2027609,1261.830357,413.938095]).astype(np.float)

Animate = True
Write_to_file = False

## Output to file
gesture_set = ["swipe_left", "swipe_right", "open", "close"]
gesture = gesture_set[2]
session = "01"
filename = gesture + session + ".data"
file = open(filename, "w")

##Use a queue to store data from serial
global data, n, start, centors, mhi
data = queue.Queue(maxsize=96000)

max_value = 3.6
background = 0
threshold = 0.4 #threshold of touch
centors = np.array([[-1.0, -1.0], [-1.0, -1.0], [-1.0, -1.0], [-1.0, -1.0], [-1.0, -1.0]])
bac_avg = np.zeros(DATA_LENGTH)

mhi = np.ones([8, 8])*max_value

## Add to queue
def addToQueue(q, input, write_to_file = False, file = ""):
    global n, start, bac_avg
    while True:
        try:
            new_input = process(input)

            # ## Calibration
            # n += 1
            # if n == 5:
            #     bac = [new_input]
            # elif n < 25 and n > 5:
            #     bac = np.append(bac,[new_input], axis = 0)
            # elif n == 25:
            #     bac_avg = np.mean(bac, axis = 0)
            # elif n == 100:
            #     end = time.time()
            #     print((end - start) / 100)

            # new_input = new_input - bac_avg + max_value/2
            # print(new_input.tolist())

            q.put(new_input, block=False)
            if write_to_file:
                file.write(" ".join(map(str, new_input)))
                file.write("\n")

        except Exception as err:
            traceback.print_exc(file=sys.stdout)

## Process data from serial. Modify to work with your Arduino code output.
## Current incoming data format (XX is a number): XX XX XX XX ...
def process(input):
    # line = input.readline().decode().replace("\r\n", "").replace("\x00", "").split(" ")
    # line = input.readline().decode().replace("\r\n", "").replace("\x00", "").split(" ")
    line = input.recv(BUFFER_SIZE)
    # print(line)
    line = line.decode().replace("\r\n", "").replace("\x00", "").split(" ")
    line = line[:DATA_LENGTH]
    # print(line)
    rst = np.array(line).astype(np.float) * 3.6 / 256
    # calibrated_rst = rst/slope
    calibrated_rst = rst
    # print(calibrated_rst.tolist())
    # print(rst)
    # rst = np.array([line]).astype(np.float)
    return calibrated_rst

## Process data from serial. Modify to work with your Arduino code output.
## Current incoming data format (XX is a number): XX XX XX XX ...
# def process(input):
#     rst = []
#     while(len(rst) != 20):
#         line = input.readline().decode()
#         rst = []
#         while(line != '\r\r\n' and line != '\r\n'):
#             rst.append(line.replace("\r\n", "").replace("\r", ""))
#             line = input.readline().decode()
#             # print(line)
#         # print(rst)
#     rst = np.array([rst]).astype(np.float)/2500000.0*5.0
#     return rst

if Animate:
    ## Modify according to your Arduino serial port
    # input = serial.Serial('/dev/tty.usbmodem0006820370001', 115200)
    # input = serial.Serial('/dev/ttyUSB0', 115200)
    # input = serial.Serial('/dev/cu.usbmodem54', 19200)
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.bind((TCP_IP, TCP_PORT))
    s.listen(5)
    input,addr=s.accept()
    print ('connected with ',addr)
    # Skip first 10 lines
    for i in range(10):
        # print(input.readline())
        print(input.recv(BUFFER_SIZE))

global q
q = deque()

def labelling(i, j, ii, jj, curdist, lab, dist):
    global q
    NIT = -1
    MASK = -2
    WSHED = 0
    if dist[ii, jj] < curdist and (lab[ii, jj] > 0 or lab[ii, jj] == WSHED):
        if lab[ii, jj] > 0:
            if lab[i, j] == MASK or lab[i, j] == WSHED:
                lab[i, j] = lab[ii, jj]
            elif lab[i, j] != lab[ii, jj]:
                lab[i, j] = WSHED
        elif lab[i, j] == MASK:
            lab[i, j] = WSHED
    elif lab[ii, jj] == MASK and dist[ii, jj] == 0:
        dist[ii,jj] = curdist + 1
        q.append(np.array([ii, jj]))  

## Watershed algorithm:
def watershed(input):
    global q
    INIT = -1
    MASK = -2
    WSHED = 0
    FICTITIOUS = np.array([-1, -1])
    curlab = 0
    k = input.shape[0]
    dist = np.zeros([k, k])
    lab = np.ones([k, k])*INIT
    hs = np.sort(input.reshape(-1))
    prev_h = -1
    for h in hs:
        if prev_h == h:
            continue
        else:
            prev_h = h
        # print("lab")
        # print(lab)
        for i in range(k):
            for j in range(k):
                if input[i,j] == h:
                    lab[i,j] = MASK
                    flag = 0
                    if i > 0:
                        ii = i - 1
                        if lab[ii,j] > 0 or lab[ii,j] == WSHED:
                            flag = 1
                    if i < k - 1:
                        ii = i + 1
                        if lab[ii,j] > 0 or lab[ii,j] == WSHED:
                            flag = 1
                    if j > 0:
                        jj = j - 1
                        if lab[i,jj] > 0 or lab[i,jj] == WSHED:
                            flag = 1
                    if j < k - 1:
                        jj = j + 1
                        if lab[i,jj] > 0 or lab[i,jj] == WSHED:
                            flag = 1
                    if flag == 1:
                        dist[i,j] = 1
                        q.append(np.array([i,j]))
        curdist = 1
        q.append(FICTITIOUS)
        while len(q) > 0:
            p = q.popleft()
            if p[0] == FICTITIOUS[0] and p[1] == FICTITIOUS[1]:
                if len(q) == 0:
                    break
                else:
                    q.append(FICTITIOUS)
                    curdist += 1
                    p = q.popleft()
            i = p[0]
            j = p[1]
            
            if i > 0:
                ii = i - 1
                labelling(i, j, ii, j, curdist, lab, dist)
            if i < k - 1:
                ii = i + 1
                labelling(i, j, ii, j, curdist, lab, dist)
            if j > 0:
                jj = j - 1
                labelling(i, j, i, jj, curdist, lab, dist)
            if j < k - 1:
                jj = j + 1
                labelling(i, j, i, jj, curdist, lab, dist)
     
        for i in range(k):
            for j in range(k):
                if input[i,j] == h:
                    dist[i,j] = 0
                    if lab[i,j] == MASK:
                        curlab = curlab + 1
                        q.append(np.array([i, j]))
                        lab[i,j] = curlab
                        while len(q) > 0:
                            qq = q.popleft()
                            ii = qq[0]
                            jj = qq[1]
                            if ii > 0:
                                iii = ii - 1
                                if lab[iii,jj] == MASK:
                                    q.append(np.array([iii, jj]))
                                    lab[iii,jj] = curlab
                            if ii < k - 1:
                                iii = ii + 1
                                if lab[iii,jj] == MASK:
                                    q.append(np.array([iii, jj]))
                                    lab[iii,jj] = curlab
                            if jj > 0:
                                jjj = jj - 1
                                if lab[ii,jjj] == MASK:
                                    q.append(np.array([ii, jjj]))
                                    lab[ii,jjj] = curlab
                            if jj < k - 1:
                                jjj = jj + 1
                                if lab[ii,jjj] == MASK:
                                    q.append(np.array([ii, jjj]))
                                    lab[ii,jjj] = curlab
    return lab
                        

             
## Extract centors from watershed result as weighted centroid
def extract_centors(input, threshold):
    input_inv = (input / 10.0).astype(int)
    count = np.zeros([5])
    count_pixel = np.zeros([5])
    x_s = np.zeros([5])
    y_s = np.zeros([5])
    addup = 0.0
    label = watershed(input_inv)
    # print(label)
    for i in range(input.shape[0]):
        for j in range(input.shape[1]):
            index = (int)(label[i, j])
            addup += input[i, j]
            if index > 0:
                count[index] += input[i, j]
                x_s[index] += input[i,j]*i
                y_s[index] += input[i,j]*j
                count_pixel[index] += 1.0
    rst = []
    mean = addup / input.shape[0] / input.shape[1]
    level = mean * threshold + mean ## greater than this level
    for i in range(5):
        value = count[i] / count_pixel[i]
        if count[i] > 0 and value > level:
            x = x_s[i] / count[i]
            y = y_s[i] / count[i]
            rst = rst + [[y, x]] ## Reverse orders
    return np.array(rst)    


## Extract touch location as local maxima
def extract_touch(input, threshold):
    input_inv = (input / 10.0).astype(int)
    maxima = np.zeros([5])
    x_s = np.zeros([5])
    y_s = np.zeros([5])
    addup = 0.0
    label = watershed(input_inv)
    # print(label)
    for i in range(input.shape[0]):
        for j in range(input.shape[1]):
            index = (int)(label[i, j])
            addup += input[i, j]
            if index > 0 and index < 5:
                if(maxima[index] < input[i, j]):
                    x_s[index] = i
                    y_s[index] = j
                    maxima[index] = input[i, j]
    rst = []
    mean = addup / input.shape[0] / input.shape[1]
    level = mean * threshold + mean ## greater than this level
    for i in range(5):
        if maxima[i] > level:
            x = x_s[i]
            y = y_s[i]
            rst = rst + [[y, x]] ## Reverse orders
    return np.array(rst)     

## Extracting nearest pairs
def pair(centors, new_centors, nearest, pair_list, pair_list_current, rst_centors, count_paired, count_prev):
    nearest_dis = 100000000 * np.ones(MAX_NUM_CENTORS)## Stores distances of nearest CURRENT touches for the previous touch
    for i in range(MAX_NUM_CENTORS): ## Produce a list of unparied previous touch with its closest unpaired current touch
        if not np.array_equal(centors[i], NA):
            if pair_list[i] == -1:
                for j in range(new_centors.shape[0]):
                    if pair_list_current[j] == -1:
                        dis = (centors[i][0] - new_centors[j][0]) ** 2 + (centors[i][1] - new_centors[j][1]) ** 2
                        if nearest_dis[i] > dis:
                            nearest_dis[i] = dis
                            nearest[i] = j
                    
    index_sorted = np.argsort(nearest_dis)
    for i in range(MAX_NUM_CENTORS):
        current_pair = (nearest[index_sorted[i]]).astype(int)
        if current_pair != -1:
            if pair_list_current[current_pair] == -1: ## CURRENT touch is unpaired
                pair_list_current[current_pair] = index_sorted[i]
                pair_list[index_sorted[i]] = current_pair
                rst_centors[index_sorted[i]] = new_centors[current_pair]
                count_paired += 1
                if count_paired == new_centors.shape[0]: ## all CURRENT touches are paired
                    return rst_centors
                elif count_paired == count_prev: ## all PREVIOUS touches are paired
                    for j in range(new_centors.shape[0]):
                        if pair_list_current[j] == -1: ## unpaired CURRENT touches
                            for k in range(MAX_NUM_CENTORS):
                                if np.array_equal(rst_centors[k], NA):
                                    rst_centors[k] = new_centors[j]
                                    break
                    return rst_centors
            else:
                # print(centors)
                # print(new_centors)
                # print(nearest_dis)
                # print(count_paired)
                # print(pair_list)
                # print(pair_list_current)
                return pair(centors, new_centors, nearest, pair_list, pair_list_current, rst_centors, count_paired, count_prev)

## Tracking using minimum distance first (MDF) algorithm
def track(centors, new_centors):
    nearest = -1 * np.ones(MAX_NUM_CENTORS) ## Stores nearest CURRENT touches for the previous touch
    pair_list = -1 * np.ones(MAX_NUM_CENTORS) ## Stores paired CURRENT touches for the previous touch
    pair_list_current = -1 * np.ones(new_centors.shape[0]) ## Stores paired PREVIOUS touches for the current touch
    rst_centors = np.array([[-1.0, -1.0], [-1.0, -1.0], [-1.0, -1.0], [-1.0, -1.0], [-1.0, -1.0]])
    count_paired = 0
    count_prev = 0
    for i in range(MAX_NUM_CENTORS): ## Produce a list of unparied previous touch with its closest unpaired current touch
        if not np.array_equal(centors[i], NA):
            count_prev += 1
    if count_prev == 0:
        for i in range(new_centors.shape[0]):
            centors[i] = new_centors[i]
        return centors
    return pair(centors, new_centors, nearest, pair_list, pair_list_current, rst_centors, count_paired, count_prev)
    


# In[ ]:


## Realtime plot function

fig = plt.figure()
ax = fig.add_subplot(111)
ax.set_xlabel('X')
ax.set_ylabel('Y')


window = None

## Update example, to be implemented
def update(frame, sensor_data, layout, max_value=5.0, background = 0, threshold = 0, normalize=False, smoothing_over=1):
    global window, centors, mhi
    d = sensor_data.get().reshape(-1)
    # print(np.mean(d[:12]))
    # print(d)
    # print(d.shape[0])
    if smoothing_over > 1:
#         print(d.shape[0])
        if frame < 1:
            window = np.zeros((smoothing_over, d.shape[0]))
            window[0] = d
            # for a in range(smoothing_over - 1):
            #     window[a + 1] = sensor_data.get().reshape(-1)
        else:
            if frame > smoothing_over: 
                window = np.delete(window, 0, 0)
            window = np.append(window, [d], axis=0)
            # print(window.shape)
        d = np.median(window, axis=0)
#     print(d)
    vis = np.copy(layout)
    k = 0
    magnitude = 0
    if normalize:
        d = d/np.sum(d)
#     print(d)
    for i, j in itertools.product(range(vis.shape[0]), range(vis.shape[1])):
        if vis[i, 7-j] != 0: # replacing the placeholders in order
            vis[i, 7-j] = max_value - (d[k] - background)
            # magnitude += vis[i, j]
#             print(d[k])
            k += 1
#         print("Normalized confusion matrix")
#     else:
#         print('Confusion matrix, without normalization')
        
#     for i, j in itertools.product(range(vis.shape[0]), range(vis.shape[1])):
#         plt.text(j, i, vis[i, j],
#                  horizontalalignment="center",
#                  color="white" if vis[i, j] > thresh else "black")

#     xdata.append(frame*0.01)
#     ydata.append(np.sin(frame))
#     ln.set_data(xdata, ydata)
    ln.set_array(max_value - vis)
    # if magnitude > threshold:
    remap = vis[:, :]
        # print(remap)
        # for ix,iy in np.ndindex(remap.shape):
        #     remap[ix,iy] = (remap[ix,iy])*(remap[ix,iy])*(remap[ix,iy])*(remap[ix,iy])*(remap[ix,iy])*(remap[ix,iy])*(remap[ix,iy])*(remap[ix,iy])*100000

        # com = ndimage.measurements.center_of_mass(remap)
        # offset_coeff = 1
        # centor = 1.5
        # new_offset_y = centor + (com[1] - centor) * offset_coeff
        # new_offset_x = centor + (com[0] - centor) * offset_coeff
        # sc.set_offsets([new_offset_y, new_offset_x])

    # new_centors = extract_centors(max_value, vis, threshold)
    new_centors = extract_touch(vis, threshold)
    if new_centors.shape[0] > 0:
        cur_centors = track(centors, new_centors)
        centors = cur_centors
    else:
        centors = np.array([[-1.0, -1.0], [-1.0, -1.0], [-1.0, -1.0], [-1.0, -1.0], [-1.0, -1.0]])
    # sc0.set_offsets(centors[0])
    # sc1.set_offsets(centors[1])
    # sc2.set_offsets(centors[2])
    # sc3.set_offsets(centors[3])
    # sc4.set_offsets(centors[4])
#     print(vis)

    # tau = 10
    # if mhi.sum(axis=(0,1)) == 0:
    #     mhi = np.ones([4, 4])*max_value
    # for j in range(4):
    #     for k in range(4):
    #         if vis[j, k] < max_value - 10:
    #             if mhi[j, k] == max_value:
    #                 mhi[j, k] = frame
    #             else:
    #                 mhi[j, k] -= 1
    #         elif mhi[j, k] < frame - tau:
    #             mhi[j, k] = 0
    # print(mhi)
    # grad = np.gradient(mhi, axis=1)
    # grad_sum = grad.sum(axis=(0,1))
    # print(grad_sum)

    return ln, sc0, sc1, sc2, sc3, sc4


# In[ ]:

### Start realtime plotting

start = time.time()
n = 0

if Animate:
    # Start adding to the queue
    adder = Thread(target=addToQueue, args=(data, input, True, file))
    adder.setDaemon(True)
    adder.start()

# layout=np.array([[1.0,1.0,1.0,1.0], [1.0,1.0,1.0,1.0], [1.0,1.0,1.0,1.0], [1.0,1.0,1.0,1.0]]) # Layout of photodiodes with 1 as placeholders for photodiodes and 0 as blank

layout=np.array([[0.01,0.01,0.01,0.01,0.01,0.01,0.01,0.01], [0.01,0.01,0.01,0.01,0.01,0.01,0.01,0.01], [0.01,0.01,0.01,0.01,0.01,0.01,0.01,0.01], [0.01,0.01,0.01,0.01,0.01,0.01,0.01,0.01], [0.01,0.01,0.01,0.01,0.01,0.01,0.01,0.01], [0.01,0.01,0.01,0.01,0.01,0.01,0.01,0.01], [0.01,0.01,0.01,0.01,0.01,0.01,0.01,0.01], [0.01,0.01,0.01,0.01,0.01,0.01,0.01,0.01]]) # Layout of photodiodes with 1 as placeholders for photodiodes and 0 as blank

len_data = layout.shape[0]
title='Depth Map'
cmap=plt.cm.Reds

vis = layout        
ln = ax.imshow(vis, interpolation='nearest', cmap=cmap, vmin=0, vmax=2.0,animated=True)
sc0 = ax.scatter(-1, -1, marker='^', s=200, c='blue')
sc1 = ax.scatter(-1, -1, marker='*', s=200, c='green')
sc2 = ax.scatter(-1, -1, marker='o', s=200, c='yellow')
sc3 = ax.scatter(-1, -1, marker='s', s=200, c='cyan')
sc4 = ax.scatter(-1, -1, marker='v', s=200, c='black')
plt.title(title)
fig.colorbar(ln)
tick_marks = np.arange(len_data)
plt.xticks(tick_marks, tick_marks, rotation=45)
plt.yticks(tick_marks, tick_marks)


# print(vis)

#     for i, j in itertools.product(range(vis.shape[0]), range(vis.shape[1])):
#         plt.text(j, i, vis[i, j],
#                  horizontalalignment="center",
#                  color="white" if vis[i, j] > thresh else "black")

plt.tight_layout()
plt.ylabel('X axis')
plt.xlabel('Y axis')
plt.xlim([-0.5, layout.shape[0] - 0.5])
plt.ylim([-0.5, layout.shape[1] - 0.5])


if Animate:
    ani = animation.FuncAnimation(fig, update, frames=1000000,
                        fargs=(data, layout, max_value, background, threshold, False, 3),interval=10, blit=True, repeat=True)

# ani = animation.FuncAnimation(fig, update, fargs=([],), interval=75, init_func=init, blit=True, repeat=True)



plt.show()
data.join()


