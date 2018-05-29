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

savepath = 'TwoLayer_hif'
datapath = ''
pm = sio.loadmat(datapath + 'SCE17_simulation_TwoLayer_hif.mat')
p = pm['pm'][0][0]
f = pm['f']
SNR = np.float(15)
NTracks = 10 # number of tracks desired
ref_range = 100 # reference range bin to define SNR = range (m) /10

savepath = savepath + '_' + str(np.int(SNR)) + 'dB/'
root = np.arange(13,13+NTracks)
rnl = np.empty((f.shape[1]))
for ff in np.arange(0,f.shape[1]):
    rnl[ff] = 10**(-SNR/20)*np.linalg.norm(np.squeeze(p[:,ref_range,ff]))

if not os.path.exists(savepath):
    os.makedirs(savepath)
        
for i in np.arange(0,len(root)):
    stat = time.time()
    out = np.zeros((p.shape[1]-100,p.shape[0], p.shape[2], 2))   
    
    for r in np.arange(100,p.shape[1]):
    
        for fi in np.arange(0,f.shape[1]):
            random.seed(root[i])
            
            d = np.squeeze(p[:,r,fi]) # select vector
            d = d + rnl[fi]*(np.random.normal(size=(p.shape[0])) + # add random noise
                         1j*np.random.normal(size=(p.shape[0])))/np.sqrt(2*p.shape[0]) 
            
            # use magnitude and phase unwrapped re. top phone
            fr = np.abs(d)
            fr = fr - np.mean(fr)
            fr = fr/np.std(fr)
            fim = np.unwrap(np.angle(d))# - np.angle(d[0])
            fim = fim - np.mean(fim)
           # fr = fr - np.mean(fr)
            out[r-100,:,fi,0] = fr
            out[r-100,:,fi,1] = fim
            
        #    break;
    pickle.dump(out, open(savepath + 'track_' + str(root[i]) + '.p','wb'))
    print('%s seconds' % (time.time()-stat))


