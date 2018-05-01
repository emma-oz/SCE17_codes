#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Feb  5 17:11:15 2018

@author: emmacreeves
"""
import numpy as np
import glob
import time

''' some fundamental, but probably NOT USED HERE, parameters of the data '''
fs = 5000 # HLA data

''' spacings of the HLA elements relative to first element '''
R = np.array([0, 4, 8, 80.7, 143.1, 196.3, 242, 281.1, 314.6, 343.2, 367.7, 388.6, 406.6, 
              422, 435.1, 446.4, 456, 464.3, 471.3, 477.4, 482.6, 487.1, 490.8, 494.1, 496.9,
              499.2, 501.3, 503, 504.5, 505.8, 506.9, 507.8, 509.4, 510.3, 511.4, 512.7, 
              514.2, 515.9, 518, 520.3, 523.1, 526.4, 531.1, 534.6, 539.7, 545.8, 552.8, 
              561.1, 570.8, 582.1, 595.2, 610.6, 628.5, 649.4, 674, 702.6, 736, 775.2, 
              820.8, 874.1, 936.5, 1009.2, 1013.2, 1017.1])

''' select the center elements with the smallest spacing '''
Els = np.arange(27,37) 
R = R[Els] # shortened array for better resolution
R = R-R[0]

''' load and process each ship track acoustic recording and its measured azimuth. save them in a dictionary. '''
def MLprocess(fdir, Els ): 
    ii = 0
    Xtrain = {}
    Xlabel = {}
    for ii in np.arange(0,2):#len(fdir)!!!!!!!!!!!!!!!
        print('Loading file "' + fdir[ii] + '"')
        start_time = time.time()
        datatmp = np.loadtxt( fdir[ii] )
        data = datatmp[0:int((datatmp.shape[0]/2)),:] + 1j*datatmp[int(datatmp.shape[0]/2):,:]
        data = np.reshape(data,[data.shape[0],64,int(data.shape[1]/64)],order='F')
        
        D = data[:,Els,:]
        #ADDED RAW
        np.savez('raw_'+fdir[ii][4:][:-4], D)

        ''' Find the phase (delay) of the data '''
        F1 = np.unwrap(np.angle(D),axis=1)
        F1 = np.reshape(F1,[D.shape[0],len(Els)*D.shape[2]])
        
        ''' Find the absolute value of the data '''
        F2 = np.abs(D)
        F2 = np.reshape(F2,[D.shape[0], len(Els)*D.shape[2]])
        
        ''' Make features from the phases and absolute values '''
        #ADDED PROCESSED
        D = np.concatenate((F1,F2), axis=1)
        np.savez('process_'+fdir[ii][4:][:-4], D)
        " Xtrain[fdir[ii]] = D "
        Xtrain[fdir[ii]] = np.load('process_'+fdir[ii][4:][:-4]+'.npz')
        #CHANGE BACK LATER
        #Xtrain[fdir[ii]] = np.divide(D - np.mean(D,axis=0),np.tile(np.std(D - np.mean(D,axis=0),axis=0),(D.shape[0],1)))
        print ii, ": ", len(Xtrain.keys())

        #print fdir[ii][0:12], "label", fdir[ii][4:]
        label = np.loadtxt('label_' + fdir[ii][4:])
        #ADDED label npz
        np.savez('newLabel_'+fdir[ii][4:][:-4], label[int((label.shape[0]/2)):])
        Xlabel[fdir[ii]] = np.load('newLabel_'+fdir[ii][4:][:-4]+'.npz')
        '''
        label = label[int((label.shape[0]/2)):]
        #ADDED label npz
        np.savez('newLabel_'+fdir[ii][4:][:-4], label)
        Xlabel[fdir[ii]] = label
        '''
        print ii, ": ", len(Xlabel.keys())
        print("--- %s seconds ---" % (time.time() - start_time))
        
    return Xtrain, Xlabel

''' Find all files, run data processor '''
fdir = glob.glob('HLA_Mar*.txt')
Xtrain, Xlabel = MLprocess(fdir, Els)


    


    


