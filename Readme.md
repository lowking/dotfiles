# 使用说明
> stow dir 就是本仓库的目录，target dir 默认是本仓库的上一级目录
- 先创建一个目录，用于独立存放配置，比如：nvim
- 当使用 stow --adopt nvim 初始化的时候，需要在nvim下创建个 .config/nvim 目录，因为nvim的配置文件需要存到上一级的.config/nvim下，之后再次执行stow --adopt nvim 就可以把配置直接初始化到stow dir中了（注意：是直接替换）
- 之后需要还原配置只要输入：stow -R nvim 即可。
