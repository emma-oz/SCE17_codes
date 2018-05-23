import numpy as np
import scipy.misc
import keras.backend as K
import os

from sklearn.metrics import mean_squared_error
from keras.models import Sequential, load_model  
from keras.layers.core import Dense, Activation  
from keras.layers import Input, Dense, LSTM, Flatten, Dropout, Reshape, GRU,\
                         Conv1D, MaxPooling1D, Convolution1D,\
                         Convolution2D, MaxPooling2D,\
                         Convolution3D, MaxPooling3D
from keras.models import Sequential
from keras.models import Model
from keras.preprocessing import sequence
from keras import optimizers
from keras.layers.normalization import BatchNormalization
from keras.callbacks import EarlyStopping


class Model:
    def __init__(self):
        self.models={}


    def model1(self, data_dim = 50):
        """ Multi-Layer Perceptron """
        drop_per = 0.0
        input_layer = Input(shape=(data_dim,))
        hidden_layer1 = Dense(256, activation="tanh", name="hidden_layer1")(input_layer)
        batch_norm1 = BatchNormalization( name = "batch_norm_1")(hidden_layer1)
        drop1 = Dropout(drop_per)(hidden_layer1)#(batch_norm1)
        
        hidden_layer2 = Dense(128, activation="tanh", name="hidden_layer2")(drop1)
        batch_norm2 = BatchNormalization( name = "batch_norm_2")(hidden_layer2)
        drop2 = Dropout(drop_per)(batch_norm2)
        
        hidden_layer3 = Dense(64, activation="relu", name="hidden_layer3")(drop2)
        batch_norm3 = BatchNormalization( name = "batch_norm_3")(hidden_layer3)
        drop3 = Dropout(drop_per)(hidden_layer3)#(batch_norm3)
        
        hidden_layer4 = Dense(128, activation="relu", name="hidden_layer4")(drop3)
        batch_norm4 = BatchNormalization( name = "batch_norm_4")(hidden_layer4)
        drop4 = Dropout(drop_per)(batch_norm4)
        
        hidden_layer5 = Dense(256, activation="relu", name="hidden_layer5")(drop4)
        batch_norm5 = BatchNormalization( name = "batch_norm_5")(hidden_layer5)
        drop5 = Dropout(drop_per)(hidden_layer5)#(batch_norm5)
        
        output_layer = Dense(1, activation="linear")(drop5)
        model = Model(inputs = input_layer, output = output_layer)
        
        return model


    def model2(self, time_steps = 30, data_dim = 50):
        """ LSTM Network """
        in_neurons = 50
        out_neurons= 1
        hidden_neurons = 20
        
        layer1Dim = 256#100
        layer2Dim = 50
        inputs = Input(shape=(time_steps, data_dim))
    #     batchNorm1 = BatchNormalization( name = "batch_norm_1")(inputs)
        lstm1 = LSTM(layer1Dim, return_sequences = True, name = 'lstm_1', activation="tanh")(inputs)
    #     batchNorm2 = BatchNormalization( name = "batch_norm_2")(lstm1)
        dropout1 = Dropout(0.0)(lstm1)
        lstm2 = LSTM(layer2Dim, return_sequences = True, name = 'lstm_2', activation="relu")(dropout1)
        batchNorm3 = BatchNormalization( name = "batch_norm_3")(lstm2)
        flatten = Flatten()(lstm1)
        dense1 = Dense(512, activation="relu", name="Dense1")(flatten)
        dropout2 = Dropout(0.0)(dense1)
        output = Dense(1, activation='linear', name="Output")(dropout2)
        model = Model(inputs = inputs, outputs = output)
        
        op = dense1._keras_shape
        print(op[0], op[1])
        
        return model  


    def model3(self, data_dim, time_steps):
        """ CNN_LSTM Network for real data """
        nb_filters = 200
        
        ip_shape = (time_steps, data_dim, 1)
        inputs = Input(shape = ip_shape)
        
        conv_1 = Convolution2D(filters = 32, kernel_size = 5, strides=(1,1), padding="same",
                        activation='relu', name="Conv1")(inputs)
        batch_norm1 = BatchNormalization( name = "batch_norm_1")(conv_1)
        maxpool_1 = MaxPooling2D(pool_size=(1,7), padding="same", name="maxpool1")(batch_norm1)
        
        conv_2 = Convolution2D(filters = 16, kernel_size = 5, strides=(1,1), padding="same",
                         activation='relu', name="Conv2")(maxpool_1)
        batch_norm2 = BatchNormalization( name = "batch_norm_2")(conv_2)
        maxpool_2 = MaxPooling2D(pool_size=(1,3), padding="same", name="maxpool2")(batch_norm2)
        
        conv_3 = Convolution2D(filters = 1, kernel_size = (1,3), strides=(1,1), padding="same",
                         activation='relu', name="Conv3")(batch_norm2)
        batch_norm3 = BatchNormalization( name = "batch_norm_3")(conv_3)
        maxpool_3 = MaxPooling2D(pool_size=(1,1), padding="same", name="maxpool3")(batch_norm3)
        layer_shape = maxpool_3._keras_shape
        maxpool_3 = Reshape(target_shape=(layer_shape[1], layer_shape[2]*layer_shape[3]),
                            name="maxpool3_RS")(maxpool_3)
        
        lstm_1 = LSTM(32, return_sequences=True, name="lstm_1")(maxpool_3)
        flatten = Flatten()(lstm_1)
        
        dense_1 = Dense(64, activation='relu', name="Dense1")(flatten)
        batch_norm4 = BatchNormalization( name = "batch_norm_4")(dense_1)
        dropout_1 = Dropout(0.4, name="dropout_1")(batch_norm4)
        
        dense_2 = Dense(32, activation='relu', name="Dense2")(dropout_1)
        batch_norm5 = BatchNormalization( name = "batch_norm_5")(dense_2)
        dropout_2 = Dropout(0.4, name="dropout_2")(batch_norm5)
        
        output = Dense(1, name="output")(dropout_1)
        model = Model(inputs = inputs, output = output)
        
        return model


    def model4(self, batch_size, data_dim = 100):
        """ 1D-CNN """
        nb_filters = 200
        
        inputs = Input(shape = (data_dim, 1))
        conv_1 = Convolution1D(filters = nb_filters, kernel_size = 3,
                        activation='tanh', name="Conv1")(inputs)
        maxpool_1 = MaxPooling1D(name="maxpool1")(conv_1)
        batch_norm1 = BatchNormalization( name = "batch_norm_1")(maxpool_1)
        conv_2 = Convolution1D(filters = nb_filters, kernel_size = 2, 
                         activation='relu', name="Conv2")(batch_norm1)
        maxpool_2 = MaxPooling1D(name="maxpool2")(conv_2)
        batch_norm2 = BatchNormalization( name = "batch_norm_2")(maxpool_2)
        
        conv_3 = Convolution1D(filters = nb_filters, kernel_size = 2, 
                         activation='relu', name="Conv3")(batch_norm2)
        maxpool_3 = MaxPooling1D(name="maxpool3")(conv_3)
    #     batch_norm2 = BatchNormalization( name = "batch_norm_2")(maxpool_2)
        
        flatten = Flatten()(maxpool_3)
        dense_1 = Dense(1024, activation='relu', name="Dense1")(flatten)
        dropout_1 = Dropout(0.4)(dense_1)
        dense_2 = Dense(512, activation='relu', name="Dense2")(dropout_1)
        dropout_1 = Dropout(0.4)(dense_2)
        output = Dense(1, name="output")(dense_2)
        model = Model(inputs = inputs, output = output)
        
        return model


    def model5(self, batch_size, data_dim = 100):
        """ 2D-CNN """
        nb_filters = 200
    
        inputs = Input(shape = (16,201,2))
        conv_1 = Convolution2D(filters = 512, kernel_size = (7,7),
                        activation='tanh', name="Conv1")(inputs)
        maxpool_1 = MaxPooling2D(name="maxpool1")(conv_1)
    #     batch_norm1 = BatchNormalization( name = "batch_norm_1")(maxpool_1)
        conv_2 = Convolution2D(filters = 256, kernel_size = (3,3),
                         activation='relu', name="Conv2")(conv_1)
        maxpool_2 = MaxPooling2D(name="maxpool2")(conv_2)
    #     batch_norm2 = BatchNormalization( name = "batch_norm_2")(maxpool_2)
    
        conv_3 = Convolution2D(filters = nb_filters, kernel_size = (3,3),
                         activation='relu', name="Conv3")(conv_2)
        maxpool_3 = MaxPooling2D(name="maxpool3")(conv_3)
    #     batch_norm2 = BatchNormalization( name = "batch_norm_2")(maxpool_2)
    
        flatten = Flatten()(maxpool_3)
        dense_1 = Dense(1024, activation='relu', name="Dense1")(flatten)
    #     dropout_1 = Dropout(0.2)(dense_1)
        dense_2 = Dense(512, activation='relu', name="Dense2")(dense_1)
    #     dropout_1 = Dropout(0.2)(dense_2)
        output = Dense(1, name="output")(dense_2)
        model = Model(inputs = inputs, output = output)
    
        return model


    def model6(self, data_dim, time_steps):
        """ CNN-LSTM for simulated data """
        nb_filters = 200
        
        ip_shape = (time_steps, data_dim[0], data_dim[1], data_dim[2])
        inputs = Input(shape = ip_shape)
        conv_1 = Convolution3D(filters = 256, kernel_size = (1,5,1),
                        activation='tanh', name="Conv1")(inputs)
    #     maxpool_1 = MaxPooling3D(pool_size=(1,3,1), padding="valid", name="maxpool1")(conv_1)
    #     batch_norm1 = BatchNormalization( name = "batch_norm_1")(maxpool_1)
        conv_2 = Convolution3D(filters = 128, kernel_size = (1,3,1), 
                         activation='relu', name="Conv2")(conv_1)
    #     maxpool_2 = MaxPooling3D(pool_size=(1,3,1), padding="valid", name="maxpool2")(conv_2)
    #     batch_norm2 = BatchNormalization( name = "batch_norm_2")(maxpool_2)
        
        conv_3 = Convolution3D(filters = 1, kernel_size = (1,3,1), 
                         activation='relu', name="Conv3")(conv_2)
        maxpool_3 = MaxPooling3D(pool_size=(1,3,1), padding="valid", name="maxpool3")(conv_3)
    #     batch_norm2 = BatchNormalization( name = "batch_norm_2")(maxpool_2)
        layer_shape = maxpool_3._keras_shape
        maxpool_3 = Reshape(target_shape=(layer_shape[1], layer_shape[2]*layer_shape[3]*layer_shape[4]),
                            name="maxpool3_RS")(maxpool_3)
        
        flatten = Flatten()(maxpool_3)
        
        lstm_1 = LSTM(128, return_sequences=False, name="lstm_1")(maxpool_3)
    #     lstm_2 = LSTM(128, return_sequences="True", name="lstm_2")(lstm_1)
        
        
    #     dense_1 = Dense(1024, activation='relu', name="Dense1")(flatten)
    #     dropout_1 = Dropout(0.2)(dense_1)
    #     dense_2 = Dense(512, activation='relu', name="Dense2")(dense_1)
    #     dropout_1 = Dropout(0.2)(dense_2)
        output = Dense(1, name="output")(flatten)
        model = Model(inputs = inputs, output = output)
        
        return model


    def model7(self, data_dim, time_steps):
        """ CNN-LSTM for real data """ 
        nb_filters = 200
        
        ip_shape = (time_steps, data_dim, 1)
        inputs = Input(shape = ip_shape)
        
        conv_1 = Convolution2D(filters = 32, kernel_size = 5, strides=(1,1), padding="same",
                        activation='relu', name="Conv1")(inputs)
        batch_norm1 = BatchNormalization( name = "batch_norm_1")(conv_1)
        maxpool_1 = MaxPooling2D(pool_size=(1,7), padding="same", name="maxpool1")(batch_norm1)
        
        conv_2 = Convolution2D(filters = 16, kernel_size = 5, strides=(1,1), padding="same",
                         activation='relu', name="Conv2")(maxpool_1)
        batch_norm2 = BatchNormalization( name = "batch_norm_2")(conv_2)
        maxpool_2 = MaxPooling2D(pool_size=(1,3), padding="same", name="maxpool2")(batch_norm2)
        
        conv_3 = Convolution2D(filters = 1, kernel_size = (1,3), strides=(1,1), padding="same",
                         activation='relu', name="Conv3")(batch_norm2)
        batch_norm3 = BatchNormalization( name = "batch_norm_3")(conv_3)
        maxpool_3 = MaxPooling2D(pool_size=(1,1), padding="same", name="maxpool3")(batch_norm3)
        layer_shape = maxpool_3._keras_shape
        maxpool_3 = Reshape(target_shape=(layer_shape[1], layer_shape[2]*layer_shape[3]),
                            name="maxpool3_RS")(maxpool_3)
        
    #     flatten = Flatten()(maxpool_3)
        
        lstm_1 = LSTM(32, return_sequences=True, name="lstm_1")(maxpool_3)
    #     lstm_2 = LSTM(128, return_sequences="True", name="lstm_2")(lstm_1)
        
        flatten = Flatten()(lstm_1)
        
        dense_1 = Dense(64, activation='relu', name="Dense1")(flatten)
        batch_norm4 = BatchNormalization( name = "batch_norm_4")(dense_1)
        dropout_1 = Dropout(0.4, name="dropout_1")(batch_norm4)
        
        dense_2 = Dense(32, activation='relu', name="Dense2")(dropout_1)
        batch_norm5 = BatchNormalization( name = "batch_norm_5")(dense_2)
        dropout_2 = Dropout(0.4, name="dropout_2")(batch_norm5)
        
        output = Dense(1, name="output")(dropout_1)
        model = Model(inputs = inputs, output = output)
        
        return model 
