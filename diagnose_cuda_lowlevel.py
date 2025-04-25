import ctypes
import os

def test_cuda_runtime():
    try:
        # Load CUDA runtime library
        cuda = ctypes.CDLL('libcudart.so')
        
        # Define function prototypes
        cuda.cudaGetDeviceCount.argtypes = [ctypes.POINTER(ctypes.c_int)]
        cuda.cudaGetDeviceCount.restype = ctypes.c_int
        
        # Get device count
        device_count = ctypes.c_int()
        result = cuda.cudaGetDeviceCount(ctypes.byref(device_count))
        
        print(f"CUDA Runtime device count: {device_count.value}")
        print(f"CUDA Runtime result code: {result}")
        
        # Try to set device
        cuda.cudaSetDevice.argtypes = [ctypes.c_int]
        cuda.cudaSetDevice.restype = ctypes.c_int
        
        set_result = cuda.cudaSetDevice(0)
        print(f"CUDA SetDevice result code: {set_result}")
        
    except Exception as e:
        print(f"Error: {e}")

test_cuda_runtime()
