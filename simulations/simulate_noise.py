#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon May 21 16:11:29 2018

@author: emmacreeves
"""
import scipy.io as sio
import numpy as np
import pickle
import random
import os
import time

savepath = 'Mud_lowf/'
datapath = ''
pm = sio.loadmat(datapath + 'SCE17_simulation_Mud_lowf.mat')
p = pm['pm'][0][0]
f = pm['f']
SNR = np.float(15)
NTracks = 5 # number of tracks desired
ref_range = 500 # reference range bin to define SNR = range (m) /10
midf = np.int(np.floor(f.shape[1]/2))

root = np.arange(13,13+NTracks)
rnl = 10**(-SNR/20)*np.linalg.norm(np.squeeze(p[:,ref_range,midf]))

if not os.path.exists(savepath):
    os.makedirs(savepath)
        
for i in np.arange(0,len(root)):
    stat = time.time()
    out = np.zeros((p.shape[1],p.shape[0]-1, p.shape[2], 2))   
    
    for r in np.arange(0,p.shape[1]):
    
        for fi in np.arange(0,f.shape[1]):
            random.seed(root[i])
            
            d = np.squeeze(p[:,i,fi]) # select vector
            d = d + rnl*(np.random.normal(size=(p.shape[0])) + # add random noise
                         1j*np.random.normal(size=(p.shape[0]))) 
            
            # use magnitude and phase unwrapped re. top phone
            fr = np.abs(d[1:])
            fim = np.unwrap(np.angle(d[1:]) - np.angle(d[0]))
            out[r,:,fi,0] = fr
            out[r,:,fi,1] = fim
    pickle.dump(out, open(savepath + 'track_' + str(root[i]) + '.p','wb'))
    print('%s seconds' % (time.time()-stat))


