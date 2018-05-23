import numpy as np
import os

class Dataset:
    
    def __init__(self, dir_path):
        self.data_dir = dir_path
        self.read_data()


    def read_data(self):
        x_train = np.load(os.path.join(self.data_dir, "X_train.p"))
        y_train = np.load(os.path.join(self.data_dir, "Y_train.p"))
        
        x_val = np.load(os.path.join(self.data_dir, "X_val.p"))
        y_val = np.load(os.path.join(self.data_dir, "Y_val.p"))
        
        self.x_test = np.load(os.path.join(self.data_dir, "X_test.p"))
        self.t_test = np.load(os.path.join(self.data_dir, "Y_test.p"))

        self.x_train = np.concatenate( (x_train, x_val), axis=0 )
        self.y_train = np.concatenate( (y_train, y_val), axis=0 )

    
    def preprocess(self, normalize=True, preprocess_method=None, *args):        
        if normalize:
            mux = np.mean(self.x_train, axis=0)
            stdx = np.std(self.x_train, axis=0)
            self.x_train = (self.x_train - mux)/stdx
            self.x_test = (self.x_test - mux)/stdx

        if preprocess_method is not None:
            self.x_train, self.y_train, self.x_test, self.y_test = \
                    preprocess_method(self.x_train, self.y_train, self.x_test, self.y_test, *args)

        
    def get_data(self):
        return self.x_train, self.y_train, self.x_test, self.y_test
