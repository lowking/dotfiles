# grep color
export GREP_OPTIONS='--color=auto'

# linux time style
# export TIME_STYLE='+%Y-%m-%d %H:%M:%S'
export HOMEBREW_NO_AUTO_UPDATE=true
export ELECTRON_MIRROR='https://npm.taobao.org/mirrors/electron/'
export SASS_BINARY_SITE='https://npm.taobao.org/mirrors/node-sass'
export PATH=$PATH:"/usr/local/bin"

# lazygit
export XDG_CONFIG_HOME="$HOME/.config"

# 加载目录映射
source ~/.path_profile
source ~/.secret

# rust相关
export PATH=$PATH:$HOME/.cargo/bin

# mysql相关
export PATH=$PATH:/usr/local/mysql/bin
export PATH=$PATH:/usr/local/mysql/support-files

# go相关
export GOROOT=/usr/local/bin
export GOPATH=/Users/lowking/Desktop
export GOBIN=$GOPATH/bin

# 加载别名
source ~/.bash_alias

export LS_OPTIONS='--color=auto'
#export CLICOLOR='Yes'
export CLICOLOR=1
export LSCOLORS=CxfxcxdxbxegedabagGxGx
#export LSCOLORS=gxfxaxdxcxegedabagacad

export PATH=$PATH:/Users/lowking/bin

mkcd() { mkdir -p "$@" && cd "$@"; }

function pmtu(){
    ping -D -s $3 $1 -c $2
}

function pl(){
    echo 查询【$1】端口占用
    lsof -Pn -i4|grep $1
}

function pl2(){
    echo 查询【$1】端口占用
    lsof -i tcp:$1
}

function proxyoff(){
    unset http_proxy
    unset https_proxy
    unset HTTP_PROXY
    unset HTTPS_PROXY
    export proxystate="http代理已关闭"
    echo $proxystate
}
function proxyon() {
    export http_proxy="http://127.0.0.1:6152"
    export https_proxy=$http_proxy
    export proxystate="http代理已开启"
    echo $proxystate
}

function ftpproxyoff(){
    unset ftp_proxy
    unset FTP_PROXY
    export ftpproxystate="ftp代理已关闭"
    echo $ftpproxystate
}
function ftpproxyon() {
    export ftp_proxy="http://127.0.0.1:1087"
    export ftpproxystate="ftp代理已开启"
    echo $ftpproxystate
}

gifInfoCache="/tmp/gifInfo"
function scaledWH() {
    w=$1
    h=$2
    ts=$3
    k=`echo "$w $h $ts" |awk '{printf "%.2f", sqrt($3 / ( $1 * $2 ))}'`
    W=`echo "$k $w" |awk '{printf "%d", $1 * $2}'`
    H=`echo "$k $h" |awk '{printf "%d", $1 * $2}'`
    echo "$W $H"
}
function ysgif() {
    if [[ "x$1" == "x" ]] then;
        echo "请传入gif路径"
        return
    fi
    # 处理文件名，便于之后保存压缩文件
    filePath="$1"
    filePath=`echo ${filePath%.*}`

    height="$2"
    # 获取原文件的高度
    sourceHeight=`nohup ffprobe "$filePath.gif" |grep "Stream" |awk -F ", " '{print $3}' |awk -F "x" '{print $2}'`
    fileSize=`ls -l "$filePath.gif" |awk '{print $4}'`
    if [[ $fileSize -gt 5242880 ]] then;
        # 大小大于5M，进行压缩
        # 未传入高度，则使用文件原本的高度
        if [[ "$height" == "" ]] then;
            height=$sourceHeight
        fi
        echo y | ffmpeg -i "$filePath.gif" -filter_complex "[0:v] scale=-1:$height,mpdecimate,split [a][b];[a] palettegen=max_colors=64 [p];[b][p] paletteuse=dither=bayer:bayer_scale=5" "$filePath..gif"
        echo "source file height: "$sourceHeight
        echo "target file height: "$height
        ll -rth "$filePath.gif" "$filePath..gif" |awk '{for(i=8;i<=NF;i++) printf $i""FS; print $4""}' |awk -F "/" '{print $NF}' |awk -F ".gif" '{print $NF" "$1}'
        # 第一次压缩结果如果还是大于5M的话，根据目前的压缩比，计算小于等于5M时候的图像高度，然后再次进行压缩
        fileSize=`ls -l "$filePath..gif" |awk '{print $4}'`
        if [[ $fileSize -gt 5242880 ]] then;
            echo "开始二次压缩"
            sourceWidth=`nohup ffprobe "$filePath.gif" |grep "Stream" |awk -F ", " '{print $3}' |awk -F "x" '{print $1}'`
            ts=`echo "$fileSize $sourceWidth $sourceHeight" |awk '{printf "%d", ($2 * $3) * ( 1 - ($1 - 4700000) / $1 )}'`
            wh=`scaledWH $sourceWidth $sourceHeight $ts`
            th=`echo "$wh" |awk '{print $2}'`
            echo y | ffmpeg -i "$filePath.gif" -filter_complex "[0:v] scale=-1:$th,mpdecimate,split [a][b];[a] palettegen=max_colors=64 [p];[b][p] paletteuse=dither=bayer:bayer_scale=5" "$filePath..gif"
            echo "source file height: "$sourceHeight
            echo "target file height: "$th
            ll -rth "$filePath.gif" "$filePath..gif" |awk '{for(i=8;i<=NF;i++) printf $i""FS; print $4""}' |awk -F "/" '{print $NF}' |awk -F ".gif" '{print $NF" "$1}'
        fi
    fi

    filePath=`echo ${filePath##*/}`
    echo "$filePath" | pbcopy
}

function flushdns() {
    sudo dscacheutil -flushcache
    sudo killall -HUP mDNSResponder
}

function sq() {
    s -S $1 -X quit 
}

unset TMUX

# 设置宝可梦背景
#pokemon zzz

#export PS1='%{%f%b%k%}$(build_prompt)'

source "$HOME/.config/chopin/.chopinrc"
source "$HOME/.bash_shortcut"
. "$HOME/.cargo/env"
