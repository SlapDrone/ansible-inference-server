import torch
import sys
import subprocess

def diagnose_cuda():
    print("System Information:")
    print(f"Python: {sys.version}")
    print(f"PyTorch: {torch.__version__}")

    print("\nCUDA Information:")
    print(f"CUDA Available: {torch.cuda.is_available()}")

    if not torch.cuda.is_available():
        print("\nTrying to find why CUDA is not available...")
        try:
            print(torch.zeros(1).cuda())
        except Exception as e:
            print(f"Error: {e}")

    print("\nEnvironment Check:")
    try:
        result = subprocess.run(['which', 'nvcc'], capture_output=True, text=True)
        print(f"nvcc location: {result.stdout.strip()}")
    except:
        print("nvcc not found in PATH")

    try:
        result = subprocess.run(['nvidia-smi'], capture_output=True, text=True)
        print("nvidia-smi works")
    except:
        print("nvidia-smi not working")

diagnose_cuda()
 