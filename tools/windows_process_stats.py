"""Read-only counters for one explicitly launched child; no window/input hooks."""
import ctypes
from ctypes import wintypes as w
class Counters(ctypes.Structure):
    _fields_=[('cb',w.DWORD),('PageFaultCount',w.DWORD)]+[(n,ctypes.c_size_t) for n in ['PeakWorkingSetSize','WorkingSetSize','QuotaPeakPagedPoolUsage','QuotaPagedPoolUsage','QuotaPeakNonPagedPoolUsage','QuotaNonPagedPoolUsage','PagefileUsage','PeakPagefileUsage','PrivateUsage']]
class WindowsProcessStats:
    def __init__(self,pid):
        self.kernel=ctypes.WinDLL('kernel32',use_last_error=True)
        self.psapi=ctypes.WinDLL('psapi',use_last_error=True)
        self.kernel.OpenProcess.argtypes=[w.DWORD,w.BOOL,w.DWORD];self.kernel.OpenProcess.restype=w.HANDLE
        self.kernel.CloseHandle.argtypes=[w.HANDLE];self.kernel.CloseHandle.restype=w.BOOL
        self.kernel.GetProcessHandleCount.argtypes=[w.HANDLE,ctypes.POINTER(w.DWORD)];self.kernel.GetProcessHandleCount.restype=w.BOOL
        self.psapi.GetProcessMemoryInfo.argtypes=[w.HANDLE,ctypes.POINTER(Counters),w.DWORD];self.psapi.GetProcessMemoryInfo.restype=w.BOOL
        self.handle=self.kernel.OpenProcess(0x400|0x10,False,pid)
        if not self.handle:raise ctypes.WinError(ctypes.get_last_error())
    def read(self):
        c=Counters();c.cb=ctypes.sizeof(c);handles=w.DWORD()
        if not self.psapi.GetProcessMemoryInfo(self.handle,ctypes.byref(c),c.cb):return {'available':False,'error':ctypes.get_last_error()}
        self.kernel.GetProcessHandleCount(self.handle,ctypes.byref(handles))
        return {'available':True,'working_set_bytes':c.WorkingSetSize,'peak_working_set_bytes':c.PeakWorkingSetSize,'private_commit_bytes':c.PrivateUsage,'page_fault_count':c.PageFaultCount,'handles':handles.value}
    def close(self):
        if self.handle:self.kernel.CloseHandle(self.handle);self.handle=None
