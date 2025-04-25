import torch
import ctypes
import os

def detailed_cuda_check():
    print("Detailed CUDA Diagnostics:")
    print("-------------------------")

    # Check if CUDA runtime can be loaded
    try:
        cuda_runtime = ctypes.CDLL('libcudart.so')
        print("✓ libcudart.so loaded successfully")
    except Exception as e:
        print(f"✗ Error loading libcudart.so: {e}")

    # Check CUDA environment
    print(f"\nCUDA_HOME: {os.environ.get('CUDA_HOME', 'Not set')}")
    print(f"CUDA_PATH: {os.environ.get('CUDA_PATH', 'Not set')}")
    print(f"LD_LIBRARY_PATH: {os.environ.get('LD_LIBRARY_PATH', 'Not set')}")

    # Check PyTorch internal state
    print(f"\nPyTorch internal checks:")
    print(f"torch.cuda._is_compiled(): {torch.cuda._is_compiled()}")
    print(f"torch.version.cuda: {torch.version.cuda}")
    print(f"torch.cuda.device_count(): {torch.cuda.device_count()}")

    # Try to get the error message
    print("\nTrying to get CUDA error message:")
    try:
        torch.cuda.init()
    except Exception as e:
        print(f"CUDA initialization error: {e}")

detailed_cuda_check()
 