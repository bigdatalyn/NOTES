

1.查看当前目录下最大的文件

du -amx |sort -nr|more

du -amx |sort -nr| head -10

2.^M问题

2.1.我们可以在VI编辑器里把^M进行删除：

将VI切换至命令行模式，输入(注意输入这个^M,这个不是shift+^再加上M,应该是ctrl+v加上ctrl+m)

:%s/^M//g --该命令copy无效，注意^M的输入

在vi命令行模式执行上面的命令，可以将所有行末的^M去掉

2.2.可以使用dos2unix命令

dos2unix filename

3.标准unix/linux下的grep通过以下参数控制上下文

grep -C 5 foo file 显示file文件中匹配foo字串那行以及上下5行

grep -B 5 foo file 显示foo及前5行

grep -A 5 foo file 显示foo及后5行





