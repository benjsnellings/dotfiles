#!/bin/python3
"""
The xrandr names (DP-1, DP-2) for my monitors tends to flip around depending on
which one happens to become active first. This script figures out which is which
by the EDID, and runs xrandr to apply the layout correctly.
"""

import re
import subprocess

# {'4d10d01400000000': 'eDP-1', '1e6d0777fdcd0000': 'DP-1', '04720f0581630065': 'DP-2-3'}

monitor_positions = {
    'l': '4d10d01400000000',
    'm': '1e6d0777fdcd0000',
    'r': '04720e05ffffffff',
}

edid_re = re.compile(r'([\w\d-]+)\sconnected.*?00ffffffffffff00([\d\w]{16})', re.S)

if __name__ == '__main__':
    monitor_names = {
        hexstr: name
        for name, hexstr in edid_re.findall(
            subprocess.check_output(['xrandr', '--verbose']).decode('utf-8'))
    }

    print(monitor_names)

    xrandrcmd = '''
        xrandr
    '''
    if monitor_positions['m'] in monitor_names and monitor_positions['r'] in monitor_names:
        subprocess.check_call("notify-send 'Home' 'Full-Workstation'".split())
        xrandrcmd += f'''
            --output {monitor_names[monitor_positions['l']]} --mode 3840x2400 --pos 0x0 --scale 0.9999x0.9999 
            --output {monitor_names[monitor_positions['m']]} --primary --mode 3840x2160 --rate 60.00 --pos 3840x0 --scale 0.9999x0.9999 
            --output {monitor_names[monitor_positions['r']]} --mode 1920x1080 --scale 2x2 --pos 7680x0 --rate 60.00 --panning 3840x2160+7680+0
        '''
    else:
        subprocess.check_call("notify-send 'Internal Display only'".split())
        xrandrcmd += '''
            --output eDP-1 --primary --mode 3840x2400 --pos 0x0 --rotate normal --scale 1x1
            --output DP-1 --off
            --output DP-2 --off
            --output DP-8 --off
            --output DP-2-3 --off
        '''

    print(xrandrcmd)
    print(xrandrcmd.split())
    # subprocess.check_call(xrandrcmd.split())
