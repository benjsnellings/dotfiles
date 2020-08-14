#!/bin/python3
"""
The xrandr names (DP-1, {monitor_names[monitor_positions['m']]}) for my monitors tends to flip around depending on
which one happens to become active first. This script figures out which is which
by the EDID, and runs xrandr to apply the layout correctly.
"""


import re
import subprocess

monitor_positions = {
    'l': '4d10d01400000000',
    'm': '1e6d0777fdcd0000',
    'r': '04720f0581630065',
}

edid_re = re.compile(r'([\w\d-]+)\sconnected.*?00ffffffffffff00([\d\w]{16})', re.S)

if __name__ == '__main__':
    monitor_names = {
        hexstr: name
        for name, hexstr in edid_re.findall(
            subprocess.check_output(['xrandr', '--verbose']).decode('utf-8'))
    }

    print(monitor_names)

    cmd = '''

    '''

    if monitor_positions['m'] in monitor_names and monitor_positions['r'] in monitor_names:
        cmd += f'''
			i3-msg workspace 1 output {monitor_names[monitor_positions['l']]}
			i3-msg workspace 2 output {monitor_names[monitor_positions['l']]}
			i3-msg workspace 3 output {monitor_names[monitor_positions['l']]}
			i3-msg workspace 4 output {monitor_names[monitor_positions['m']]}
			i3-msg workspace 5 output {monitor_names[monitor_positions['m']]}
			i3-msg workspace 6 output {monitor_names[monitor_positions['m']]}
			i3-msg workspace 7 output {monitor_names[monitor_positions['m']]}
			i3-msg workspace 8 output {monitor_names[monitor_positions['m']]}
			i3-msg workspace 9 output {monitor_names[monitor_positions['m']]}
			i3-msg workspace 10 output {monitor_names[monitor_positions['m']]}
			i3-msg workspace 17 output {monitor_names[monitor_positions['l']]}
			i3-msg workspace 18 output {monitor_names[monitor_positions['l']]}
			i3-msg workspace 19 output {monitor_names[monitor_positions['l']]}
			i3-msg workspace 20 output {monitor_names[monitor_positions['l']]}
			i3-msg workspace 1 
        '''
    else:
        cmd += f'''
			i3-msg workspace 1 output {monitor_names[monitor_positions['l']]}
			i3-msg workspace 2 output {monitor_names[monitor_positions['l']]}
			i3-msg workspace 3 output {monitor_names[monitor_positions['l']]}
			i3-msg workspace 4 output {monitor_names[monitor_positions['l']]}
			i3-msg workspace 5 output {monitor_names[monitor_positions['l']]}
			i3-msg workspace 6 output {monitor_names[monitor_positions['l']]}
			i3-msg workspace 7 output {monitor_names[monitor_positions['l']]}
			i3-msg workspace 8 output {monitor_names[monitor_positions['l']]}
			i3-msg workspace 9 output {monitor_names[monitor_positions['l']]}
			i3-msg workspace 10 output {monitor_names[monitor_positions['l']]}
			i3-msg workspace 17 output {monitor_names[monitor_positions['l']]}
			i3-msg workspace 18 output {monitor_names[monitor_positions['l']]}
			i3-msg workspace 19 output {monitor_names[monitor_positions['l']]}
			i3-msg workspace 20 output {monitor_names[monitor_positions['l']]}
        '''

    print(cmd.split())
    subprocess.check_call(cmd.split())

    aftercmd = f'''
			i3-msg workspace 1 
        '''
    print(aftercmd.split())
    subprocess.check_call(aftercmd.split())
