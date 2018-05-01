#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Feb  8 12:51:33 2018

@author: emmacreeves
"""

from sklearn.ensemble import RandomForestClassifier
import numpy as np
import glob
import time

fdir = glob.glob('HLA_Mar*.txt')
Els = np.arange(27,37)

#Xtrain, Xlabel = MLprocess(fdir,Els)
Xtrain = {}
Xlabel = {}
##############################################################################
#ADDED
#Function name: data_process
#Description: To combine Data_PreProcess with RandomForest; Create raw, 
#             processed and label files after calling data_process, store 
#Param: 
#      fdir: file to read in 
#       Els: index at which we strat read in the file
#Return:
#       Xtrain: dic containing training sets
#       Xlabel: dic containing labels
##############################################################################
def data_process(fdir, Els):
    
    for ii in np.arange(len(fdir)):
        print('Loading file "' + fdir[ii] + '"')
        start_time = time.time()
        datatmp = np.loadtxt( fdir[ii] )
        data = datatmp[0:int((datatmp.shape[0]/2)),:] + 1j*datatmp[int(datatmp.shape[0]/2):,:]
        data = np.reshape(data,[data.shape[0],64,int(data.shape[1]/64)],order='F')
        
        D = data[:,Els,:]
        #Create raw file
        np.save('raw_'+fdir[ii][4:][:-4], D)

        ''' Find the phase (delay) of the data '''
        F1 = np.unwrap(np.angle(D),axis=1)
        F1 = np.reshape(F1,[D.shape[0],len(Els)*D.shape[2]])
        
        ''' Find the absolute value of the data '''
        F2 = np.abs(D)
        F2 = np.reshape(F2,[D.shape[0], len(Els)*D.shape[2]])
        
        ''' Make features from the phases and absolute values '''
        #Create processed file
        D = np.concatenate((F1,F2), axis=1)
        np.save('process_'+fdir[ii][4:][:-4], D)
        Xtrain[fdir[ii]] = np.load('process_'+fdir[ii][4:][:-4]+'.npy')
        # #of elements in Xtrain
        print "Loop at index: ", ii, "# of elements in Xtrain: ", len(Xtrain.keys())

        #print fdir[ii][0:12], "label", fdir[ii][4:]
        label = np.loadtxt('label_' + fdir[ii][4:])
        #Create new Label file which is later half of the original one
        np.save('newLabel_'+fdir[ii][4:][:-4], label[int((label.shape[0]/2)):])
        Xlabel[fdir[ii]] = np.load('newLabel_'+fdir[ii][4:][:-4]+'.npy')
        # #of elements in Xlabel
        print "Loop at index: ", ii, "# of elements in Xlabel: ", len(Xlabel.keys())
        print("--- %s seconds ---" % (time.time() - start_time))

    return Xtrain, Xlabel


data_process(fdir, Els)
''' Random Forest beamformer'''
TRAINEL = 3 # here you can choose which file to use as the training
print "Test with the following file: ", fdir[TRAINEL]
X = Xtrain[fdir[TRAINEL]]
Y = Xlabel[fdir[TRAINEL]]


# turn the y labels into strings, that's how RFC likes it
tmp = np.array(['%.1f' % x for x in Y.reshape(Y.size)])
Ylabel = tmp.reshape(Y.shape)

''' training '''
clf = RandomForestClassifier(random_state=0,max_depth=20)
clf.fit(X,Ylabel)


''' testing '''
TESTEL = 2 # choose which file/s to use as the test
pred = clf.predict(Xtrain[fdir[TESTEL]])
true_label = Xlabel[fdir[TESTEL]]