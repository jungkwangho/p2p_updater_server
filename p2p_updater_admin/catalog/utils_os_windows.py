import os
import pefile

def get_windows_file_version_from_buffer(data, filename):
    try:
        pe = pefile.PE(data=data)
        string_version_info = {}
        for fileinfo in pe.FileInfo[0]:
            if fileinfo.Key.decode() == 'StringFileInfo':
                for st in fileinfo.StringTable:
                    for entry in st.entries.items():
                        string_version_info[entry[0].decode()] = entry[1].decode()
        return string_version_info['FileVersion']
    except Exception as e:
        return ''