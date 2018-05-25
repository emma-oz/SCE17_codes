#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Apr 19 13:09:52 2018

@author: ecreeves
"""

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
import random

savepath = 'Mud_lowf_15dB/1train/'
datapath = '../simulations/Mud_lowf_15dB/'

inputs = sorted(glob.glob(datapath + 'track*'))
ranges = np.arange(1,15,0.010)

Ntrain = 1
useall = False# False if training, True if testing
total_data = []
total_range = []

# switch between training and testing data
if useall:
    test_range = [i for i in range(len(inputs)-1, len(inputs))]
    file_range = test_range
else:
    inputs = inputs[0:(Ntrain+1)]
    train_range = [i for i in range(0,len(inputs)-1)]
    file_range = train_range

for ii in file_range:   
    if inputs[ii][-3:] == 'txt':
         D = np.loadtxt(inputs[ii])
         data = D
         rng = np.loadtxt(ranges[ii])
         rng = rng[0:int(len(rng)/2)]
    elif inputs[ii][-3:] == 'mat':
         D = sio.loadmat(inputs[ii])
         data = D['out']
         print(data.shape)
         rng = ranges
         print(rng.shape)
    elif inputs[ii][-1:] == 'p':
         D = pickle.load(open(inputs[ii],'rb'))
         data = D
         rng = ranges
         print(data.shape, rng.shape)
    else:
         print('Error loading file type!')

    print(inputs[ii],len(rng))
    if data.shape[0]>len(rng):
        data = data[0:len(rng),:]
        print('Im not using data of mismatched length at this time: ' + inputs[ii])
        continue;
    elif len(rng)>data.shape[0]:
        rng = rng[0:data.shape[0]]
        print('Im not using data of mismatched length at this time:' + inputs[ii])
        continue;
    total_data.append(data)
    total_range.append(rng)
        
data = total_data[0]
for i in range(1, len(total_data)):
    data=np.concatenate([data, total_data[i]],axis=0)


rng = total_range[0]
for i in range(1, len(total_range)):
    rng=np.concatenate([rng, total_range[i]])

        
# randomly split into training and validation

cutoff = int(np.floor(len(rng)*0))
randshuff = np.arange(0,len(rng))
random.shuffle(randshuff)
    
    
if useall: # turn the whole track into a test set
    x_val = data
    y_val = rng
    print(data.shape, x_val.shape)
else:   # split between training and validation
    x_val = data[sorted(randshuff[0:cutoff]),:,:,:]
    x_train = data[sorted(randshuff[cutoff:]),:,:,:]
    y_val = rng[sorted(randshuff[0:cutoff])]
    y_train = rng[sorted(randshuff[cutoff:])]
    print(x_train.shape, x_val.shape)

if 'x_train' in locals(): # make training data
    pickle.dump(x_train,open(savepath + 'x_train' + '.p','wb'),protocol=4)
    pickle.dump(y_train,open(savepath + 'y_train' + '.p','wb'))
    test_file = "_val"
else: # make test data
    print("pca object loaded!")
    test_file = "_test"
  

pickle.dump(x_val, open(savepath + 'x'+test_file + '.p', 'wb'))
pickle.dump(y_val, open(savepath + 'y'+test_file + '.p', 'wb'))
