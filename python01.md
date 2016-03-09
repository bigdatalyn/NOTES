

DaShiBuilding,Gate7,KejiNanRoad,Hi-TechPark,NanShan

导入模块

### 1.tab.py

	#python starup file
	import sys
	import readline
	import rlcompleter
	import atexit
	import os
	#tab completion
	readline.parse_and_bind('tab: complete')
	#history file
	histfile=os.path.join(os.environ['HOME'], '.pythonhistory')
	try:
		readline.read_history_file(histfile)
	except IOError:
		pass
	atexit.register(readline.write_history_file, histfile)

### 2.注释：
三个单引号或者双引号 多行内容

### 3.from os import system

system('df')

### 4.sys.path
import sys
sys.path
导入模块顺序

自定义的一般放到这个 目录下：
/usr/lib/python2.7/dist-packages





