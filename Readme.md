# 使用说明
> stow dir 就是本仓库的目录，target dir 默认是本仓库的上一级目录
- 先创建一个目录当作配置管理的标识，用于独立存放配置，比如：nvim
- 在nvim创建.config目录之后把新增的~/.config/nvim目录直接移动到之前创建的nvim/.config目录下
- 之后需要还原配置只要输入：stow -R nvim 即可。

> [!NOTE]
> 已经在~/bin/t s配置映射目录
```
t s _jj -R
```
