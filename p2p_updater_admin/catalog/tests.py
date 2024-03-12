#from django.test import TestCase
import os
import pefile

def get_windows_file_version_from_buffer(data, filename):
    try:
        
        #pe = pefile.PE(data=data)
        pe = pefile.PE(filename)
        string_version_info = {}
        for fileinfo in pe.FileInfo[0]:
            if fileinfo.Key.decode() == 'StringFileInfo':
                for st in fileinfo.StringTable:
                    for entry in st.entries.items():
                        string_version_info[entry[0].decode()] = entry[1].decode()
        return string_version_info['FileVersion']
    except Exception as e:
        return ''
# Create your tests here.

f = open('1.exe', 'rb')
data = f.read()
print(get_windows_file_version_from_buffer(data,"1.exe"))

