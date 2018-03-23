#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Mar 19 10:11:49 2018

@author: emmacreeves
"""
import scipy.io as sio
import numpy as np
import pickle
import glob
from sklearn.decomposition import PCA
import matplotlib.pyplot as plt
import random

savepath = 'data/VLA2/'

inputs = sorted(glob.glob('input_*.mat'))
ranges = sorted(glob.glob('range_*.mat'))

# add the previous data sets
#ranges = ranges + sorted(glob.glob('label_V*'))

#del inputs[0]
#del ranges[0]
#del inputs[1]
#del ranges[1]


delind = [] # list of potential indices to remove
useall = True
total_data = []
total_range = []


train_range = [i for i in range(0,len(inputs)-1)]
test_range = [i for i in range(len(inputs)-1, len(inputs))]
if useall:
    file_range = test_range
else:
    file_range = train_range

for ii in file_range:
    
    if inputs[ii][-3:] == 'txt':
         D = np.loadtxt(inputs[ii])
         data = D
         rng = np.loadtxt(ranges[ii])
         rng = rng[0:int(len(rng)/2)]
    elif inputs[ii][-3:] == 'mat':
         D = sio.loadmat(inputs[ii])
         label = sio.loadmat(ranges[ii])
         data = D['out']
         rng = label['range'][0,:]
    else:
         print('Error loading file type!')

    print(inputs[ii],data.shape)
    if data.shape[0]>len(rng):
        data = data[0:len(rng),:]
        print('Im not using data of mismatched length at this time: ' + inputs[ii])
        delind.append(int(ii))
        continue;
    elif len(rng)>data.shape[0]:
        rng = rng[0:data.shape[0]]
        print('Im not using data of mismatched length at this time:' + inputs[ii])
        delind.append(int(ii))
        continue;
    total_data.append(data)
    total_range.append(rng)
        
data = total_data[0]
for i in range(1, len(total_data)):
    data=np.concatenate([data, total_data[i]])


rng = total_range[0]
for i in range(1, len(total_range)):
    rng=np.concatenate([rng, total_range[i]])

        
 

cutoff = int(np.floor(len(rng)*0.3))
randshuff = np.arange(0,len(rng))
random.shuffle(randshuff)
    
    
if useall: # turn the whole track into a test set
    x_val = data
    y_val = rng
    print(data.shape, x_val.shape)
else:
    x_val = data[sorted(randshuff[0:cutoff]),:]
    x_train = data[sorted(randshuff[cutoff:]),:]
    y_val = rng[sorted(randshuff[0:cutoff])]
    y_train = rng[sorted(randshuff[cutoff:])]
    print(x_train.shape, x_val.shape)

    
if 'x_train' in locals():
    pca = PCA(n_components=50)
    pca.fit(x_train)
    pickle.dump(pca,open(savepath + 'pca.p','wb'))
    print("pca object saved!")
    x_train = pca.transform(x_train) 
    pickle.dump(x_train, open(savepath + 'x_train' + '.p','wb'))
    pickle.dump(y_train, open(savepath + 'y_train' +  '.p','wb'))
    test_file = "_val"
else:
    pca = pickle.load(open(savepath + 'pca.p', 'rb'))
    print("pca object loaded!")
    test_file = "_test"
    
x_val = pca.transform(x_val)
pickle.dump(x_val, open(savepath + 'x'+test_file + '.p', 'wb'))
pickle.dump(y_val, open(savepath + 'y'+test_file + '.p', 'wb'))


inputs = [ item for i,item in enumerate(inputs) if i not in delind ]
ranges = [ item for i,item in enumerate(ranges) if i not in delind ]   
