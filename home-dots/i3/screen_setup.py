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
    'internal': '4d10d01400000000',
    'm': '04721c07076d7102',
    'r': '1e6d0777fdcd0000',
    'work': '10acdfa04c364731',
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

    xrdb_merge_file = '''

    '''

    i3_workspace_move = '''

    '''

    # Home Setup
    if monitor_positions['m'] in monitor_names and monitor_positions['r'] in monitor_names:
        subprocess.check_call("notify-send 'Home Workstation'".split())
        xrandrcmd += f'''
            --output {monitor_names[monitor_positions['internal']]} --mode 3840x2400 --pos 0x0 
            --output {monitor_names[monitor_positions['m']]} --primary --mode 3840x2160 --rate 60.00 --pos 3840x0 
            --output {monitor_names[monitor_positions['r']]} --mode 3840x2160 --pos 7680x0 
        '''
        xrdb_merge_file += f'''
            i3.output.0.name: {monitor_names[monitor_positions['internal']]}
            i3.output.1.name: {monitor_names[monitor_positions['m']]}
            i3.output.2.name: {monitor_names[monitor_positions['r']]}
        '''

    # Work Display
    elif monitor_positions['work'] in monitor_names :
        subprocess.check_call("notify-send 'Office Workstation'".split())
        xrandrcmd += f'''
            --output {monitor_names[monitor_positions['internal']]} --mode 2560x1600 --pos 0x0 
            --output {monitor_names[monitor_positions['work']]} --primary --mode 3440x1440 --scale 1.4x1.4 --pos 2560x0 
        '''

        # Use this one so that the laptop display is 4K
        xrandrcmd += f'''
            --output {monitor_names[monitor_positions['internal']]} --mode 3840x2400 --pos 0x0 
            --output {monitor_names[monitor_positions['work']]} --primary --mode 3440x1440 --scale 1.4x1.4 --pos 3840x0 
        '''
        xrdb_merge_file += f'''
            i3.output.0.name: {monitor_names[monitor_positions['internal']]}
            i3.output.1.name: {monitor_names[monitor_positions['work']]}
            i3.output.2.name: {monitor_names[monitor_positions['work']]}
        '''

          #  i3-msg move workspace 1 to {monitor_names[monitor_positions['internal']]}
          #  i3-msg move workspace 2 to {monitor_names[monitor_positions['internal']]}
          #  i3-msg move workspace 3 to {monitor_names[monitor_positions['internal']]}
          #  i3-msg move workspace 4 to {monitor_names[monitor_positions['internal']]}
          #  i3-msg move workspace 5 to {monitor_names[monitor_positions['internal']]}
          #  i3-msg move workspace 6 to {monitor_names[monitor_positions['work']]}
          #  i3-msg move workspace 7 to {monitor_names[monitor_positions['work']]}
          #  i3-msg move workspace 8 to {monitor_names[monitor_positions['work']]}
          #  i3-msg move workspace 9 to {monitor_names[monitor_positions['work']]}
          #  i3-msg move workspace 10 to {monitor_names[monitor_positions['work']]}
          #  i3-msg move workspace 11 to {monitor_names[monitor_positions['work']]}
          #  i3-msg move workspace 12 to {monitor_names[monitor_positions['work']]}
          #  i3-msg move workspace 13 to {monitor_names[monitor_positions['work']]}
          #  i3-msg move workspace 14 to {monitor_names[monitor_positions['work']]}
          #  i3-msg move workspace 15 to {monitor_names[monitor_positions['work']]}
          #  i3-msg move workspace 16 to {monitor_names[monitor_positions['work']]}
          #  i3-msg move workspace 17 to {monitor_names[monitor_positions['work']]}
          #  i3-msg move workspace 18 to {monitor_names[monitor_positions['work']]}


          #  i3-msg move workspace 20 to {monitor_names[monitor_positions['work']]}
        i3_workspace_move += f'''
            i3-msg workspace 19 && i3-msg move workspace to output {monitor_names[monitor_positions['internal']]}

            '''
    
    # Internal Display Only
    else:
        subprocess.check_call("notify-send 'Internal Display'".split())
        xrandrcmd += '''
            --output eDP-1 --primary --mode 3840x2400 --pos 0x0 --rotate normal 
            --output DP-1 --off
            --output DP-2 --off
            --output DP-5 --off
            --output DP-6 --off
            --output DP-8 --off
            --output DP-2-3 --off
            --output DP-1-1 --off
            --output DP-1-2 --off
        '''
        xrdb_merge_file += f'''
            i3.output.0.name: {monitor_names[monitor_positions['internal']]}
            i3.output.1.name: {monitor_names[monitor_positions['internal']]}
            i3.output.2.name: {monitor_names[monitor_positions['internal']]}
        '''



    print(xrandrcmd.split())
    subprocess.check_call(xrandrcmd.split())

    i3_xresources_file = "/tmp/i3-Xresources"
    f = open(i3_xresources_file, "w")
    f.write(xrdb_merge_file)
    f.close()

    subprocess.check_call(f"xrdb -merge {i3_xresources_file}".split())
    
    # subprocess.check_call(i3_workspace_move.split()) 
