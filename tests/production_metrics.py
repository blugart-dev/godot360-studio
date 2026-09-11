"""Windows PDH memory telemetry for a benchmark process tree, without extra packages.

GPU process counters and whole-adapter counters are retained separately. Shared
GPU memory is system RAM and must not be added to process RAM as independent use.
Sampled peaks are lower bounds; engine allocation counters supply another view.
"""
import ctypes as C
from ctypes import wintypes as W
import os
import re


class Value(C.Structure):
    _fields_ = [("status", W.DWORD), ("value", C.c_double)]


class Item(C.Structure):
    _fields_ = [("name", W.LPWSTR), ("value", Value)]


class Memory(C.Structure):
    _fields_ = [("length", W.DWORD), ("load", W.DWORD)] + [
        (name, C.c_ulonglong) for name in ["total", "available", "page_total", "page_available", "virtual_total", "virtual_available", "extended"]]


class ProcessEntry(C.Structure):
    _fields_ = [("size", W.DWORD), ("usage", W.DWORD), ("pid", W.DWORD), ("heap", C.c_size_t),
                ("module", W.DWORD), ("threads", W.DWORD), ("parent", W.DWORD),
                ("priority", W.LONG), ("flags", W.DWORD), ("name", W.WCHAR * 260)]


class ProcessMemory(C.Structure):
    _fields_ = [("size", W.DWORD), ("faults", W.DWORD)] + [(name, C.c_size_t) for name in
        ["peak_rss", "rss", "peak_paged", "paged", "peak_nonpaged", "nonpaged", "pagefile", "peak_pagefile", "private"]]


def process_tree(root_pid, extra_pids):
    # PID-based APIs avoid legacy PDH Process(*) name collisions when several
    # workers use the same executable. Process V2 is not installed everywhere.
    api = C.WinDLL("kernel32", use_last_error=True)
    api.CreateToolhelp32Snapshot.argtypes = [W.DWORD, W.DWORD]
    api.CreateToolhelp32Snapshot.restype = W.HANDLE
    api.Process32FirstW.argtypes = api.Process32NextW.argtypes = [W.HANDLE, C.POINTER(ProcessEntry)]
    api.OpenProcess.argtypes = [W.DWORD, W.BOOL, W.DWORD]
    api.OpenProcess.restype = W.HANDLE
    api.K32GetProcessMemoryInfo.argtypes = [W.HANDLE, C.POINTER(ProcessMemory), W.DWORD]
    api.CloseHandle.argtypes = [W.HANDLE]
    handle = api.CreateToolhelp32Snapshot(2, 0)
    if handle == W.HANDLE(-1).value:
        raise C.WinError(C.get_last_error())
    inventory = {}
    try:
        entry = ProcessEntry()
        entry.size = C.sizeof(entry)
        valid = api.Process32FirstW(handle, C.byref(entry))
        while valid:
            inventory[entry.pid] = (entry.parent, entry.name)
            valid = api.Process32NextW(handle, C.byref(entry))
    finally:
        api.CloseHandle(handle)
    selected = {pid for pid in [root_pid, *extra_pids] if pid}
    while True:
        updated = selected | {pid for pid, (parent, _) in inventory.items() if parent in selected and pid}
        if updated == selected:
            break
        selected = updated
    rows = {}
    for pid in selected & inventory.keys():
        handle = api.OpenProcess(0x410, False, pid)
        if not handle:
            continue  # The worker may exit between enumeration and sampling.
        try:
            memory = ProcessMemory()
            memory.size = C.sizeof(memory)
            if api.K32GetProcessMemoryInfo(handle, C.byref(memory), memory.size):
                rows[str(pid)] = {"name": inventory[pid][1], "private_bytes": memory.private, "working_set_bytes": memory.rss}
        finally:
            api.CloseHandle(handle)
    return rows


class WindowsMemory:
    PATHS = {
        "gpu_dedicated": r"\GPU Process Memory(*)\Dedicated Usage",
        "gpu_shared": r"\GPU Process Memory(*)\Shared Usage",
        "adapter_dedicated": r"\GPU Adapter Memory(*)\Dedicated Usage",
        "adapter_shared": r"\GPU Adapter Memory(*)\Shared Usage",
    }

    def __init__(self):
        if os.name != "nt":
            raise RuntimeError("This memory collector requires Windows PDH; native Linux/Mac collectors need separate validation.")
        self.api = C.WinDLL("pdh")
        self.api.PdhOpenQueryW.argtypes = [W.LPCWSTR, C.c_size_t, C.POINTER(W.HANDLE)]
        self.api.PdhAddEnglishCounterW.argtypes = [W.HANDLE, W.LPCWSTR, C.c_size_t, C.POINTER(W.HANDLE)]
        self.api.PdhCollectQueryData.argtypes = [W.HANDLE]
        self.api.PdhCloseQuery.argtypes = [W.HANDLE]
        self.api.PdhGetFormattedCounterArrayW.argtypes = [W.HANDLE, W.DWORD, C.POINTER(W.DWORD), C.POINTER(W.DWORD), C.c_void_p]
        self.query = W.HANDLE()
        self.handles = {}
        self.errors = {}
        self._check(self.api.PdhOpenQueryW(None, 0, C.byref(self.query)))
        try:
            for name, path in self.PATHS.items():
                handle = W.HANDLE()
                status = self.api.PdhAddEnglishCounterW(self.query, path, 0, C.byref(handle))
                if status:
                    self.errors[name] = hex(status & 0xffffffff)
                else:
                    self.handles[name] = handle
            self._check(self.api.PdhCollectQueryData(self.query))
        except BaseException:
            self.close()
            raise

    @staticmethod
    def _check(status):
        if status:
            raise RuntimeError(f"PDH failed: {status & 0xffffffff:#x}")

    def _values(self, name):
        if name not in self.handles:
            return {}
        # Retry a sizing race with a fresh zero-size request, as required by PDH.
        for _ in range(3):
            size, count = W.DWORD(), W.DWORD()
            status = self.api.PdhGetFormattedCounterArrayW(self.handles[name], 0x200, C.byref(size), C.byref(count), None)
            if not size.value:
                self.errors[name] = hex(status & 0xffffffff)
                return {}
            buffer = C.create_string_buffer(size.value)
            status = self.api.PdhGetFormattedCounterArrayW(self.handles[name], 0x200, C.byref(size), C.byref(count), buffer)
            if not status:
                items = C.cast(buffer, C.POINTER(Item))
                return {items[i].name: int(items[i].value.value) for i in range(count.value) if items[i].value.status in (0, 1)}
        self.errors[name] = hex(status & 0xffffffff)
        return {}

    def sample(self, root_pid=None, extra_pids=()):
        self._check(self.api.PdhCollectQueryData(self.query))
        values = {name: self._values(name) for name in self.PATHS}
        processes = process_tree(root_pid, extra_pids)
        for kind in ("gpu_dedicated", "gpu_shared"):
            for name, amount in values[kind].items():
                match = re.search(r"pid_(\d+)_", name)
                if match and match[1] in processes:
                    row = processes[match[1]]
                    row[kind + "_bytes"] = row.get(kind + "_bytes", 0) + amount
        memory = Memory()
        memory.length = C.sizeof(memory)
        if not C.windll.kernel32.GlobalMemoryStatusEx(C.byref(memory)):
            raise C.WinError()
        def total(key):
            numbers = [r[key] for r in processes.values() if r.get(key) is not None]
            return sum(numbers) if numbers else None
        return {"processes": processes, "process_private_bytes": total("private_bytes"),
                "process_working_set_bytes": total("working_set_bytes"),
                "process_gpu_dedicated_bytes": total("gpu_dedicated_bytes"),
                "process_gpu_shared_bytes": total("gpu_shared_bytes"),
                "adapter_dedicated_bytes": values["adapter_dedicated"], "adapter_shared_bytes": values["adapter_shared"],
                "system_total_bytes": memory.total, "system_available_bytes": memory.available,
                "system_used_bytes": memory.total - memory.available, "counter_errors": self.errors.copy()}

    def close(self):
        if self.query:
            self.api.PdhCloseQuery(self.query)
            self.query = W.HANDLE()
