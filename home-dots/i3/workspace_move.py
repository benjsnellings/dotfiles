import sys
import os
import i3py.i3 as i3


# parser = argparse.ArgumentParser(description='Get movement direction')
# parser.add_argument('direction', metavar='D', help='an integer for the accumulator')

# args = parser.parse_args()
direction = sys.argv[1]
if direction == "left":
	os.system("i3-msg workspace prev")
elif direction == "right":
	os.system("i3-msg workspace next")

# direction = sys.argv[1]
# if direction == "left" and not i3.get_workspaces()[0]['focused']:
# 	os.system("i3-msg workspace prev")
# elif direction == "right" and not i3.get_workspaces()[-1]['focused']:
# 	os.system("i3-msg workspace next")
