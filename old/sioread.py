

def sioread( filename, p1, npi, channels):
    import numpy as np
    import os
    
    # coding: utf-8

    # # This is an sioread file for Jupyter Notebook and Python 3.6
    #   
    #   *originally written by Aaron Thode.  Modified by Geoff Edelmann and 
    #  James Murray. (Final Version: July, 2001)*
    # 
    #  *read bug fixed by Dave Ensberg (July 2003)
    #  modified to have read all channel option  Dave Ensberg (Feb 2005)*
    # 
    #  *rewritten for Python and Jupyter Notebook suite by Emma Ozanich (Mar 2018)*
    # 
    #  Inputs:
    #  filename: Name of sio file to read
    #  p1: Point to start reading ( 0 < p1 < np)
    #  npi: Number of points to read in
    #  channels: Single number or vector containing the channels to read **            
    #      **if 'channels' == 0 then read all channels in file.
    # 
    #  Example:  xdata = sioread('../data.dir/test1.sio',10,100,[1 2 4:6]);
    #  xdata will be a matlab array of 100 points and 5 channels.  The
    #  points start at the siofile point #10 and the channels extracted are
    #  channels 1,2,4,5,6
    # 
    #
    #  since the majority of sio files will be created as 'SUN' sio
    #  files, we will assume they are 'big endian' and check for
    #  compliance.
    # 

    fid=open(filename,'rb')
    fid.seek(28,os.SEEK_SET)
    bs=np.fromfile(fid,dtype='>i4',count=1)  # should be 32677

    if bs != 32677:
      fid.close()
      fid=open(filename,'rb');
      fid.seek(28,os.SEEK_SET)
      bs=np.fromfile(fid,dtype='<i4',count=1) # should be 32677
      if bs != 32677:
        print('Problem with byte swap constant: bs = ' + bs)


    # I can just use fseek(fid,0,-1) to position to beginning of file
    # but I think that closing and reopening is cleaner.
    fid.close();
    fid=open(filename,'rb');

    id=np.fromfile(fid,dtype='>i4',count=1)  # ID Number
    nr=np.fromfile(fid,dtype='>i4',count=1)  # Number of Records in File
    rl=np.fromfile(fid,dtype='>i4',count=1)  # Record Length in Bytes
    nc=np.fromfile(fid,dtype='>i4',count=1)  # Number of Channels in File
    sl=np.fromfile(fid,dtype='>i4',count=1)  # Bytes/ Point
    
    # Mar. 7, 2018 note: the Matlab version uses 'long' and 'short' formats, but I just int. here. Might not work for data that are stored as floats.
    type = '>i4'
    if sl==2:
        type='>i4'
    f0=np.fromfile(fid,dtype='>i4',count=1)  # 0 = integer, 1 = real
    nop=np.fromfile(fid,dtype='>i4',count=1)  # Number of Points per Channel
    bs=np.fromfile(fid,dtype='>i4',count=1)  # should be 32677
    #fn=np.fromfile(fid,dtype='str',count=24) # Read in the file name
    #com= np.fromfile(fid,dtype='str',count=72) # Read in the Comment String

    rechan=np.ceil(nr/nc)     #records per channel
    ptrec=int(rl/sl)          #points/record

#    print('# Records: ' + str(nr) + ', # Channels: ' + str(nc) + ', Points per Channel: ' + 
#          str(nop))# + ', filename: ' + str(fn))

    if channels == 0:
        channels = np.arange(0,nc)
    else:
        for ii in np.arange(0,len(channels)):
            if (channels(ii) < 0): 
                print('Channel must be positive: ' + channels[ii])
            if (channels(ii) > nc): 
                print('Channel does not exist:'  + str(channels[ii]))
            if (channels(ii) == 0 ):
                #generate vector that will extract all channels
                channels = np.arange(0,nc)

    r1=np.floor((p1-1)/ptrec)+1 #record where we wish to start recording

    #if npi is 0, use all points
    if npi <= 0: 
        npi = nop-p1+1
        p2=int(p1+npi-1) #ending position in points for each channel.
        r2=np.ceil(p2/ptrec) #record where we end recording
    #disp(sprintf(' npi ==0 , npi = %7d, p2 = %7d, r2 = %7d = p2/%4d ',npi,p2,r2,ptrec));

    if p2>nop: #-- Error checking to prevent reading past EOF
        print('Warning:  p1 + npi > nop')
        p2=int(nop)
        r2=rechan
    totalrec=int(r2-r1+1) #number of records desired read.


    pp1 = np.mod(p1-1,ptrec) # p1's position in record
    x = np.empty([p2-p1+1,len(channels)]) # "allocate" a matrix for final result
    tmpx = np.empty([totalrec*ptrec]) # make a temporary matrix

    # # Loop over the desired channels # #
    for J in np.arange(0,len(channels)):
        count = 0 # Start 
        trec = (r1-1)*nc + channels[J] # First Record to read for this channel
        for R in np.arange(0,totalrec):
            status = fid.seek(int(rl*trec),os.SEEK_SET) # position to the desired record
            if status == -1:
                print('ERROR')

          # Read in a record's worth of points
            zz = np.fromfile(fid,dtype=type,count=ptrec);
            countRead = len(zz)
            if ( (countRead != rl/sl) ):
                print(' record ' + str(R) + ' returned short read ' + str(countRead) + ' of '+ str(rl/sl))
                x[0:(p2-p1+1),J] = tmpx[pp1:(pp1+p2-p1)]

            if ( zz.size == 0):
                print('  record ' + R + ' returned empty read.')
                x[0:(p2-p1+1),J] = tmpx[pp1:(pp1+p2-p1)]
            tmpx[count:(count+ptrec)] = zz

            count = count+ptrec # adjust for the next set of points
            trec = trec + nc # Next record for this channel is nc records away
            
        x[0:(p2-p1+1),J] = tmpx[pp1:(pp1+p2-p1+1)]


    fid.close();
    return x

#-- end of program

