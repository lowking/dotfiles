" let $BASH_ENV="~/.vim_bash_env"  " 已注释，直接使用 ~/.bashrc

" 让 y 复制到系统剪贴板
set clipboard=unnamed

syntax on
colorscheme jellybeans
set re=0
set ts=4
set so=5
set softtabstop=4
set shiftwidth=4
set expandtab
set autoindent
set nu
set relativenumber
set ignorecase
set infercase

imap ,, <ESC>
vmap ,, <ESC>

command Cg :w | !clear; cargo run
command CG :w | !clear; cargo run
command Ss :w | !clear; . ./%
command SS :w | !clear; . ./%
command Nd :w | !clear; node %
command ND :w | !clear; node %
command Ndp :w | !clear; node % p
command NDP :w | !clear; node % p
command Py :w | !clear; python3 %
command PY :w | !clear; python3 %

" 每次打开光标恢复到上次退出位置
autocmd BufReadPost *
\ if line("'\"") > 0 && line("'\"") <= line("$") |
\   exe "normal g`\"" |
\ endif

" 配置 <leader>] 快捷键：执行选中代码并将结果追加到下一行
" 支持数字前缀，如 10<leader>] 会执行10次
vnoremap <leader>] <Cmd>call ExecuteAndAppend(v:count1)<CR>
" 配置 <leader>c 快捷键：格式化选中的 curl 命令
vnoremap <leader>c :<C-U>call FormatCurl()<CR>
nnoremap <leader>c :<C-U>call FormatCurl()<CR>
" 配置 <leader>[ 快捷键：使用 jq 格式化 JSON
" 没选中文本：格式化当前行并替换
" 选中文本：将多行压缩成一行并替换
vnoremap <leader>[ :<C-U>call FormatJSON()<CR>
nnoremap <leader>[ :<C-U>call FormatJSON()<CR>
inoremap <leader>[ <Esc>:call FormatJSON()<CR>

" ============================================================================
" 并发执行指令
" ============================================================================
function! ExecuteAndAppend(count)
    " 第一时间保存最后编辑位置标记（在任何操作之前）
    let save_change_mark = getpos("'.")

    " 先退出再重新进入可视模式，确保 '< 和 '> 标记被正确设置
    execute "normal! \<Esc>gv"

    " count 默认为 1，如果用户输入了数字前缀则使用该数字
    let exec_count = a:count > 0 ? a:count : 1

    " 保存当前视图
    let save_view = winsaveview()

    " 保存选中的范围（在退出可视模式前）
    let start_line = line("'<")
    let end_line = line("'>")
    let start_col = col("'<")
    let end_col = col("'>")
    let visual_mode = visualmode()

    " 获取选中的文本（在退出可视模式前）
    let selected_text = GetVisualSelection()

    " 立即退出可视模式，避免重复触发
    execute "normal! \<Esc>"

    " 立即恢复视图（在调用 system 之前）
    call winrestview(save_view)
    redraw

    " 判断是否需要等待（检查第一行）
    let is_waiting = 0
    let scheduled_time = ''
    let delay_ms = 0
    let lines = split(selected_text, '\n', 1)
    if len(lines) > 0
        let first_line = lines[0]
        if first_line =~# '^#.*>20\d\d-\d\d-\d\d\s\+\d\d:\d\d:\d\d'
            " 提取时间
            let time_match = matchstr(first_line, '>20\d\d-\d\d-\d\d\s\+\d\d:\d\d:\d\d')
            let scheduled_time = substitute(time_match, '^>', '', '')

            " 提取延迟毫秒数（可选）
            let delay_match = matchstr(first_line, '>20\d\d-\d\d-\d\d\s\+\d\d:\d\d:\d\d\s\+\zs\d\+')
            let delay_ms = delay_match != '' ? str2nr(delay_match) : 0

            " 使用 Python 计算时间差：实际执行时间 = 调度时间 + 延迟毫秒
            let py_code = 'from datetime import datetime; '
            let py_code .= 'sched = datetime.strptime("' . scheduled_time . '", "%Y-%m-%d %H:%M:%S").timestamp() * 1000; '
            let py_code .= 'curr = datetime.now().timestamp() * 1000; '
            let py_code .= 'print(int(sched + ' . delay_ms . ' - curr))'
            let result = system('python3 -c ' . shellescape(py_code))
            let diff_ms = str2nr(result)

            " 只要实际执行时间晚于当前时间就显示等待中
            if diff_ms > 0
                let is_waiting = 1
            endif
        endif
    endif

    " 去除选中文本末尾的换行符
    let selected_text = substitute(selected_text, '\n$', '', '')

    " 如果命令为空，直接返回
    if selected_text == ""
        echoerr "选中的文本为空"
        return
    endif

    " 不做任何处理，直接使用选中的文本
    let processed_text = selected_text

    " 使用之前保存的结束行号（因为我们已经退出了可视模式）
    let last_line = end_line

    " 添加空行和动画
    lockmarks call appendbufline('%', last_line, "")
    let last_line = last_line + 1
    silent! undojoin
    " 根据是否需要等待显示不同的初始文本
    let status_text = is_waiting > 0 ? "等待中..." : (exec_count > 1 ? "并发执行中..." : "执行中...")
    lockmarks call appendbufline('%', last_line, "⠋ " . status_text)
    let spinner_line = last_line + 1

    " 初始化全局状态
    let g:exec_state = {
        \ 'spinner_line': spinner_line,
        \ 'spinner_idx': 0,
        \ 'start_time': reltime(),
        \ 'result_start_line': spinner_line - 1,
        \ 'exec_count': exec_count,
        \ 'save_view': save_view,
        \ 'save_change_mark': save_change_mark,
        \ 'is_waiting': is_waiting
        \ }

    " 启动动画 timer
    let g:exec_state.spinner_timer = timer_start(100, 'ExecSpinnerTick', {'repeat': -1})

    " 统一使用并发执行（单次执行就是 count=1）
    call ExecuteCommandConcurrent(processed_text, exec_count, scheduled_time, delay_ms)
endfunction

function! ExecuteCommandConcurrent(command_text, count, scheduled_time, delay_ms)
    " 创建临时 shell 脚本文件
    let temp_script = tempname() . ".sh"

    " 将选中的文本原样写入临时脚本文件
    call writefile(split(a:command_text, '\n', 1), temp_script)

    " 给脚本添加执行权限
    call system("chmod +x " . shellescape(temp_script))

    " 使用 Python 并发执行脚本
    let python_script = tempname() . ".py"
    let python_code = [
        \ "#!/usr/bin/env python3",
        \ "import subprocess, sys, time, os, pty, select",
        \ "from concurrent.futures import ThreadPoolExecutor, as_completed",
        \ "from datetime import datetime",
        \ "",
        \ "script_path = '" . temp_script . "'",
        \ "",
        \ "# Source zsh 配置（如不需要可注释此段以提升性能）",
        \ "zshrc = os.path.expanduser('~/.zshrc')",
        \ "if os.path.exists(zshrc):",
        \ "    source_cmd = f'. {zshrc} 2>/dev/null; '",
        \ "else:",
        \ "    source_cmd = ''",
        \ "",
        \ "# 使用 VimScript 传入的调度信息（避免重复解析）",
        \ "scheduled_time_str = '" . a:scheduled_time . "'",
        \ "delay_ms = " . a:delay_ms,
        \ "",
        \ "# 解析调度时间",
        \ "scheduled_time = None",
        \ "if scheduled_time_str:",
        \ "    try:",
        \ "        scheduled_time = datetime.strptime(scheduled_time_str, '%Y-%m-%d %H:%M:%S')",
        \ "    except ValueError:",
        \ "        pass",
        \ "",
        \ "# 如果有定时信息且时间未到，使用死循环 + 10ms 休眠等待",
        \ "if scheduled_time and datetime.now() < scheduled_time:",
        \ "    while True:",
        \ "        now = datetime.now()",
        \ "        if now >= scheduled_time:",
        \ "            # 到达时间后再休眠指定的毫秒数",
        \ "            time.sleep(delay_ms / 1000.0)",
        \ "            break",
        \ "        # 休眠 10ms",
        \ "        time.sleep(0.0001)",
        \ "    # 等待结束，发送信号",
        \ "    sys.stderr.write('__WAITING_DONE__\\n')",
        \ "    sys.stderr.flush()",
        \ "",
        \ "def run_command_with_pty(cmd):",
        \ "    \"\"\"使用 pty 运行命令，支持 sudo/su 等需要 tty 的命令\"\"\"",
        \ "    master, slave = pty.openpty()",
        \ "    try:",
        \ "        proc = subprocess.Popen(",
        \ "            cmd,",
        \ "            stdin=slave,",
        \ "            stdout=slave,",
        \ "            stderr=slave,",
        \ "            close_fds=True",
        \ "        )",
        \ "        os.close(slave)",
        \ "        ",
        \ "        output = []",
        \ "        while True:",
        \ "            try:",
        \ "                # 使用 select 检查是否有数据可读",
        \ "                r, w, e = select.select([master], [], [], 0.1)",
        \ "                if r:",
        \ "                    data = os.read(master, 4096)",
        \ "                    if not data:",
        \ "                        break",
        \ "                    output.append(data.decode('utf-8', errors='replace'))",
        \ "                ",
        \ "                # 检查进程是否结束",
        \ "                if proc.poll() is not None:",
        \ "                    # 进程已结束，读取剩余输出",
        \ "                    try:",
        \ "                        while True:",
        \ "                            data = os.read(master, 4096)",
        \ "                            if not data:",
        \ "                                break",
        \ "                            output.append(data.decode('utf-8', errors='replace'))",
        \ "                    except OSError:",
        \ "                        pass",
        \ "                    break",
        \ "            except OSError:",
        \ "                break",
        \ "        ",
        \ "        proc.wait()",
        \ "        return ''.join(output), proc.returncode",
        \ "    finally:",
        \ "        try:",
        \ "            os.close(master)",
        \ "        except OSError:",
        \ "            pass",
        \ "",
        \ "def run_command(index):",
        \ "    # 记录开始时间（只计算脚本执行时间）",
        \ "    start_time = time.time()",
        \ "    timestamp = datetime.fromtimestamp(start_time).strftime('%Y-%m-%d %H:%M:%S.%f')[:-3]",
        \ "    try:",
        \ "        # 使用 pty 执行脚本，支持 sudo/su",
        \ "        output, returncode = run_command_with_pty(['zsh', script_path])",
        \ "        end_time = time.time()",
        \ "        elapsed = f'{end_time - start_time:.3f}s'",
        \ "        ",
        \ "        # 清理输出",
        \ "        output = output.replace('\\r\\n', '\\n').replace('\\r', '\\n')",
        \ "        output = output.rstrip('\\n')",
        \ "        ",
        \ "        if returncode != 0 and output:",
        \ "            output = '【执行错误，退出码: ' + str(returncode) + '】\\n' + output",
        \ "        elif returncode != 0:",
        \ "            output = '【执行错误，退出码: ' + str(returncode) + '】'",
        \ "        ",
        \ "        return (index, timestamp, elapsed, output)",
        \ "    except Exception as e:",
        \ "        end_time = time.time()",
        \ "        elapsed = f'{end_time - start_time:.3f}s'",
        \ "        return (index, timestamp, elapsed, '【执行异常: ' + str(e) + '】')",
        \ "",
        \ "count = " . a:count,
        \ "",
        \ "# 单次执行：实时输出（使用 pty）",
        \ "if count == 1:",
        \ "    master, slave = pty.openpty()",
        \ "    proc = subprocess.Popen(['zsh', script_path], stdin=slave, stdout=slave, stderr=slave, close_fds=True)",
        \ "    os.close(slave)",
        \ "    ",
        \ "    while True:",
        \ "        try:",
        \ "            r, w, e = select.select([master], [], [], 0.1)",
        \ "            if r:",
        \ "                data = os.read(master, 4096)",
        \ "                if not data:",
        \ "                    break",
        \ "                sys.stdout.write(data.decode('utf-8', errors='replace'))",
        \ "                sys.stdout.flush()",
        \ "            if proc.poll() is not None:",
        \ "                try:",
        \ "                    while True:",
        \ "                        data = os.read(master, 4096)",
        \ "                        if not data:",
        \ "                            break",
        \ "                        sys.stdout.write(data.decode('utf-8', errors='replace'))",
        \ "                        sys.stdout.flush()",
        \ "                except OSError:",
        \ "                    pass",
        \ "                break",
        \ "        except OSError:",
        \ "            break",
        \ "    ",
        \ "    os.close(master)",
        \ "    proc.wait()",
        \ "    sys.exit(proc.returncode)",
        \ "",
        \ "# 并发执行：收集输出后统一显示",
        \ "results = [None] * count",
        \ "with ThreadPoolExecutor(max_workers=count) as executor:",
        \ "    # 创建 future 到 index 的映射",
        \ "    future_to_index = {executor.submit(run_command, i): i for i in range(count)}",
        \ "    # 使用 as_completed 处理完成的任务，但结果按索引存储",
        \ "    for future in as_completed(future_to_index):",
        \ "        index, timestamp, elapsed, output = future.result()",
        \ "        results[index] = (timestamp, elapsed, output)",
        \ "",
        \ "# 按索引顺序输出结果",
        \ "for i, (timestamp, elapsed, output) in enumerate(results):",
        \ "    if i > 0:",
        \ "        sys.stdout.write('\\n---RESULT_SEPARATOR---\\n')",
        \ "    sys.stdout.write(timestamp + '|' + elapsed + '|' + output)",
        \ "    if not output.endswith('\\n'):",
        \ "        sys.stdout.write('\\n')",
        \ ]
    call writefile(python_code, python_script)

    " 保存到全局状态
    let g:exec_state.temp_script = temp_script
    let g:exec_state.python_script = python_script

    " 异步执行 Python 脚本
    let job_opts = {
        \ 'out_cb': 'ExecConcurrentOutCb',
        \ 'err_cb': 'ExecConcurrentErrCb',
        \ 'exit_cb': 'ExecConcurrentExitCb',
        \ }

    " 单次执行使用行模式（实时输出），并发执行使用原始模式（收集输出）
    if a:count == 1
        let job_opts.out_mode = 'nl'
        let job_opts.err_mode = 'nl'
    else
        let job_opts.out_mode = 'raw'
        let job_opts.err_mode = 'raw'
    endif

    let job = job_start(['python3', python_script], job_opts)
endfunction

" 获取 Python 代码模板（修复单引号转义）
function! GetPythonFixQuoteEscapeCode()
    return [
        \ "# 修复单引号内的转义：将 \\' 替换为 '\\'' (POSIX shell 标准写法)",
        \ "def fix_single_quote_escape(s):",
        \ "    result = []",
        \ "    i = 0",
        \ "    in_single_quote = False",
        \ "    while i < len(s):",
        \ "        if s[i] == \"'\" and (i == 0 or s[i-1] != '\\\\'):",
        \ "            result.append(s[i])",
        \ "            in_single_quote = not in_single_quote",
        \ "            i += 1",
        \ "        elif in_single_quote and i < len(s) - 1 and s[i] == '\\\\' and s[i+1] == \"'\":",
        \ "            result.append(\"'\")",
        \ "            result.append(\"\\\\\")",
        \ "            result.append(\"'\")",
        \ "            result.append(\"'\")",
        \ "            i += 2",
        \ "        else:",
        \ "            result.append(s[i])",
        \ "            i += 1",
        \ "    return ''.join(result)",
        \ ""
        \ ]
endfunction

" 格式化命令输出（stdout 和 stderr）
function! FormatCommandOutput(stdout, stderr)
    let stdout = substitute(a:stdout, '\n\+$', '', '')
    let stderr = substitute(a:stderr, '\n\+$', '', '')
    if stdout != "" && stderr != ""
        return stdout . "\n" . stderr
    elseif stdout != ""
        return stdout
    elseif stderr != ""
        return stderr
    else
        return ""
    endif
endfunction

" 全局变量：跟踪实时输出
let g:exec_state = {}
let g:exec_spinner_frames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏']

" 旋转动画回调
function! ExecSpinnerTick(timer)
    if !has_key(g:exec_state, 'spinner_line')
        call timer_stop(a:timer)
        return
    endif

    let frame_idx = g:exec_state.spinner_idx % len(g:exec_spinner_frames)
    let frame = g:exec_spinner_frames[frame_idx]
    let g:exec_state.spinner_idx += 1

    " 更新动画行
    let elapsed = reltimestr(reltime(g:exec_state.start_time))
    let elapsed_str = printf("%.1f", str2float(elapsed))
    " 根据状态显示不同的文本
    let exec_count = get(g:exec_state, 'exec_count', 1)
    let status_text = get(g:exec_state, 'is_waiting', 0) ? "等待中..." : (exec_count > 1 ? "并发执行中..." : "执行中...")
    let spinner_text = frame . " " . status_text . " (" . elapsed_str . "s)"
    call setline(g:exec_state.spinner_line, spinner_text)
    redraw
endfunction

" Job 输出回调
function! ExecJobOutCb(channel, msg)
    if has_key(g:exec_state, 'spinner_line')
        " 合并到同一个 undo 块
        silent! undojoin
        " 在动画行之前插入输出（不删除动画行）
        lockmarks call appendbufline('%', g:exec_state.spinner_line - 1, a:msg)
        " 动画行位置向后移动一行
        let g:exec_state.spinner_line += 1
        redraw
    endif
endfunction

" Job 错误输出回调（用于处理等待信号）
function! ExecJobErrCb(channel, msg)
    " 检查是否是等待结束信号
    if a:msg == '__WAITING_DONE__'
        " 更新状态和动画文本
        if has_key(g:exec_state, 'is_waiting') && g:exec_state.is_waiting
            let g:exec_state.is_waiting = 0
            " 重置开始时间，从执行开始计算
            let g:exec_state.start_time = reltime()
        endif
    else
        " 其他错误输出，正常处理
        call ExecJobOutCb(a:channel, a:msg)
    endif
endfunction

" Job 完成回调
function! ExecJobExitCb(job, exit_code)
    " 先保存并清除 spinner_line，防止后续输出回调继续操作
    let spinner_line = get(g:exec_state, 'spinner_line', 0)
    if has_key(g:exec_state, 'spinner_line')
        unlet g:exec_state.spinner_line
    endif

    " 停止动画
    if has_key(g:exec_state, 'spinner_timer')
        call timer_stop(g:exec_state.spinner_timer)
    endif

    " 计算总耗时并生成完成消息
    let result_msg = "--- 执行完成 (退出码 " . a:exit_code . ") ---"
    if has_key(g:exec_state, 'start_time')
        let elapsed = reltimestr(reltime(g:exec_state.start_time))
        let elapsed_str = printf("%.3f", str2float(elapsed))
        let result_msg = "--- 执行完成 (耗时 " . elapsed_str . "s, 退出码 " . a:exit_code . ") ---"
    endif

    " 删除动画行并添加完成标记（合并到同一个 undo 块）
    if spinner_line > 0
        silent! undojoin
        let line_pos = spinner_line - 1
        call deletebufline('%', spinner_line)
        silent! undojoin
        lockmarks call appendbufline('%', line_pos, "")
        silent! undojoin
        lockmarks call appendbufline('%', line_pos + 1, result_msg)
    endif

    " 清理临时文件
    if has_key(g:exec_state, 'temp_script') && filereadable(g:exec_state.temp_script)
        call delete(g:exec_state.temp_script)
    endif
    if has_key(g:exec_state, 'wrapper_script') && filereadable(g:exec_state.wrapper_script)
        call delete(g:exec_state.wrapper_script)
    endif

    " 恢复视图（光标位置和滚动位置）
    if has_key(g:exec_state, 'save_view')
        call winrestview(g:exec_state.save_view)
    endif

    " 恢复最后编辑位置标记 (使按 '. 能回到最后编辑位置)
    " 注意：'. 是只读标记，不能直接用 setpos() 设置
    " 解决方案：跳转到该位置并执行一个微小的编辑操作
    let saved_change_mark = get(g:exec_state, 'save_change_mark', [])
    if len(saved_change_mark) > 0 && saved_change_mark[1] > 0
        " 保存当前位置
        let current_pos = getpos('.')
        " 跳转到最后编辑位置
        call setpos('.', saved_change_mark)
        " 用 r 替换当前字符为相同字符（会更新 '. 但不改变内容）
        let char = getline('.')[col('.') - 1]
        if char != ''
            silent! execute "normal! r" . char
        endif
        " 恢复光标位置
        call setpos('.', current_pos)
    endif

    " 清理状态
    let g:exec_state = {}
    redraw
endfunction

" 并发执行输出回调
function! ExecConcurrentOutCb(channel, msg)
    let exec_count = get(g:exec_state, 'exec_count', 1)

    " 单次执行：实时追加输出到最后
    if exec_count == 1
        if has_key(g:exec_state, 'spinner_line')
            " 合并到同一个 undo 块
            silent! undojoin

            " 获取当前输出的最后一行（初始时就是动画行）
            if !has_key(g:exec_state, 'output_end_line')
                let g:exec_state.output_end_line = g:exec_state.spinner_line
            endif

            " 在输出最后一行之后追加新内容
            lockmarks call appendbufline('%', g:exec_state.output_end_line, a:msg)
            " 更新输出最后一行位置
            let g:exec_state.output_end_line += 1
            redraw
        endif
    else
        " 并发执行：收集输出到全局状态
        if !has_key(g:exec_state, 'output')
            let g:exec_state.output = ""
        endif
        let g:exec_state.output .= a:msg
    endif
endfunction

" 并发执行错误输出回调（用于处理等待信号）
function! ExecConcurrentErrCb(channel, msg)
    " 检查是否是等待结束信号
    if a:msg =~ '__WAITING_DONE__'
        " 更新状态
        if has_key(g:exec_state, 'is_waiting') && g:exec_state.is_waiting
            let g:exec_state.is_waiting = 0
            " 重置开始时间，从执行开始计算
            let g:exec_state.start_time = reltime()
        endif
    else
        " 其他错误输出，正常收集
        call ExecConcurrentOutCb(a:channel, a:msg)
    endif
endfunction

" 并发执行完成回调
function! ExecConcurrentExitCb(job, exit_code)
    " 停止动画
    if has_key(g:exec_state, 'spinner_timer')
        call timer_stop(g:exec_state.spinner_timer)
    endif

    " 删除动画行
    let spinner_line = get(g:exec_state, 'spinner_line', 0)
    if spinner_line > 0
        silent! undojoin
        call deletebufline('%', spinner_line)
    endif

    let exec_count = get(g:exec_state, 'exec_count', 1)

    " 单次执行：输出已实时显示，只需删除动画行
    if exec_count == 1
        " 不需要解析和追加结果，输出已经实时显示了
    else
        " 并发执行：解析收集的输出并显示
        " 获取执行结果
        let output = get(g:exec_state, 'output', '')

        " 解析结果
        let raw_results = split(output, '\n---RESULT_SEPARATOR---\n', 1)
        let results = []
        for raw_result in raw_results
            if raw_result =~ '^\d\{4}-\d\{2}-\d\{2} \d\{2}:\d\{2}:\d\{2}\.\d\{3}|'
                let parts = split(raw_result, '|', 1)
                if len(parts) >= 3
                    let timestamp = parts[0]
                    let elapsed = parts[1]
                    let content = join(parts[2:], '|')
                    call add(results, [timestamp, elapsed, content])
                else
                    call add(results, ["", "", raw_result])
                endif
            else
                call add(results, ["", "", raw_result])
            endif
        endfor

        " 获取参数
        let last_line = get(g:exec_state, 'result_start_line', spinner_line - 1)

        " 按顺序追加所有结果（所有修改合并到同一个 undo 块）
        let i = 1
        for result_item in results
            let timestamp = result_item[0]
            let elapsed = result_item[1]
            let result = result_item[2]

            silent! undojoin
            call AppendResult(last_line, result, timestamp, elapsed, i, exec_count)
            let result_lines = GetResultLineCount(result)
            let last_line = last_line + 1 + result_lines + (i < exec_count ? 1 : 0)
            let i = i + 1
        endfor
    endif

    " 清理临时文件
    if has_key(g:exec_state, 'temp_script') && filereadable(g:exec_state.temp_script)
        call delete(g:exec_state.temp_script)
    endif
    if has_key(g:exec_state, 'python_script') && filereadable(g:exec_state.python_script)
        call delete(g:exec_state.python_script)
    endif

    " 恢复视图（光标位置和滚动位置）
    if has_key(g:exec_state, 'save_view')
        call winrestview(g:exec_state.save_view)
    endif

    " 恢复最后编辑位置标记 (使按 '. 能回到最后编辑位置)
    " 注意：'. 是只读标记，不能直接用 setpos() 设置
    " 解决方案：跳转到该位置并执行一个微小的编辑操作
    let saved_change_mark = get(g:exec_state, 'save_change_mark', [])
    if len(saved_change_mark) > 0 && saved_change_mark[1] > 0
        " 保存当前位置
        let current_pos = getpos('.')
        " 跳转到最后编辑位置
        call setpos('.', saved_change_mark)
        " 用 r 替换当前字符为相同字符（会更新 '. 但不改变内容）
        let char = getline('.')[col('.') - 1]
        if char != ''
            silent! execute "normal! r" . char
        endif
        " 恢复光标位置
        call setpos('.', current_pos)
    endif

    " 清理状态
    let g:exec_state = {}
    redraw
endfunction

function! ExecuteCommand(command_text, save_view, save_change_mark)
    " 创建临时 shell 脚本文件
    let temp_script = tempname() . ".sh"

    try
        " 将选中的文本原样写入临时脚本文件
        call writefile(split(a:command_text, '\n', 1), temp_script)

        " 给脚本添加执行权限
        call system("chmod +x " . shellescape(temp_script))

        " 检查第一行是否有定时信息，并判断是否需要等待
        let first_line_list = readfile(temp_script, '', 1)
        let first_line = len(first_line_list) > 0 ? first_line_list[0] : ''
        let is_waiting = 0
        if first_line =~# '^#.*>20\d\d-\d\d-\d\d\s\+\d\d:\d\d:\d\d'
            " 提取时间字符串
            let time_match = matchstr(first_line, '>20\d\d-\d\d-\d\d\s\+\d\d:\d\d:\d\d')
            if time_match != ''
                let scheduled_time = substitute(time_match, '^>', '', '')
                " 获取当前时间并比较
                let current_time = strftime('%Y-%m-%d %H:%M:%S')
                if scheduled_time > current_time
                    let is_waiting = 1
                endif
            endif
        endif

        " 获取当前选中区域的结束行
        let last_line = line("'>")

        " 添加空行和动画指示行（合并到同一个 undo 块）
        lockmarks call appendbufline('%', last_line, "")
        let last_line = last_line + 1
        silent! undojoin
        " 根据是否真的需要等待显示不同的初始文本
        let initial_text = is_waiting ? "⠋ 等待中..." : "⠋ 执行中..."
        lockmarks call appendbufline('%', last_line, initial_text)
        let spinner_line = last_line + 1

        " 初始化全局状态
        let g:exec_state = {
            \ 'temp_script': temp_script,
            \ 'spinner_line': spinner_line,
            \ 'spinner_idx': 0,
            \ 'start_time': reltime(),
            \ 'save_view': a:save_view,
            \ 'save_change_mark': a:save_change_mark,
            \ 'is_waiting': is_waiting
            \ }

        " 启动动画 timer（每100ms更新一次）
        let g:exec_state.spinner_timer = timer_start(100, 'ExecSpinnerTick', {'repeat': -1})

        " 创建包装脚本，先等待再执行
        let wrapper_script = tempname() . ".py"
        let wrapper_code = [
            \ "#!/usr/bin/env python3",
            \ "import subprocess, sys, time, re",
            \ "from datetime import datetime",
            \ "",
            \ "script_path = '" . temp_script . "'",
            \ "",
            \ "# 读取脚本第一行，检查是否有定时信息",
            \ "scheduled_time = None",
            \ "delay_ms = 0",
            \ "with open(script_path, 'r', encoding='utf-8') as f:",
            \ "    first_line = f.readline()",
            \ "    if first_line.strip().startswith('#'):",
            \ "        match = re.search(r'>(\\d{4}-\\d{2}-\\d{2}\\s+\\d{2}:\\d{2}:\\d{2})(?:\\s+(\\d+))?', first_line)",
            \ "        if match:",
            \ "            time_str = match.group(1)",
            \ "            delay_ms = int(match.group(2)) if match.group(2) else 0",
            \ "            try:",
            \ "                scheduled_time = datetime.strptime(time_str, '%Y-%m-%d %H:%M:%S')",
            \ "            except ValueError:",
            \ "                pass",
            \ "",
            \ "# 如果有定时信息且时间未到，等待",
            \ "if scheduled_time and datetime.now() < scheduled_time:",
            \ "    while True:",
            \ "        now = datetime.now()",
            \ "        if now >= scheduled_time:",
            \ "            time.sleep(delay_ms / 1000.0)",
            \ "            break",
            \ "        time.sleep(0.0001)",
            \ "    # 等待结束，发送信号",
            \ "    print('__WAITING_DONE__', file=sys.stderr, flush=True)",
            \ "",
            \ "# 执行脚本并实时输出",
            \ "proc = subprocess.Popen(['zsh', script_path], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)",
            \ "for line in proc.stdout:",
            \ "    print(line, end='', flush=True)",
            \ "proc.wait()",
            \ "sys.exit(proc.returncode)",
            \ ]
        call writefile(wrapper_code, wrapper_script)
        let g:exec_state.wrapper_script = wrapper_script

        " 启动异步执行
        let job_opts = {
            \ 'out_cb': 'ExecJobOutCb',
            \ 'err_cb': 'ExecJobErrCb',
            \ 'exit_cb': 'ExecJobExitCb',
            \ 'out_mode': 'nl',
            \ 'err_mode': 'nl'
            \ }

        let job = job_start(['python3', wrapper_script], job_opts)

        " 不返回任何值，因为是异步执行
        return ['0.000s', '']
    catch
        " 如果出错，清理临时文件
        if filereadable(temp_script)
            call delete(temp_script)
        endif
        return ['0.000s', '【启动执行失败: ' . v:exception . '】']
    endtry
endfunction

" 追加执行结果到文件
function! AppendResult(last_line, result, timestamp, elapsed, index, total)
    " 去除结果末尾的换行符
    let result = substitute(a:result, '\n\+$', '', '')

    " 将结果按行分割（保留空行）
    let lines = split(result, '\n', 1)

    " 添加分隔行标识每次执行，包含执行时间点和耗时
    if a:timestamp != "" && a:elapsed != ""
        lockmarks call appendbufline('%', a:last_line, "--- 执行 #" . a:index . " (" . a:timestamp . ", 耗时 " . a:elapsed . ") ---")
    elseif a:elapsed != ""
        lockmarks call appendbufline('%', a:last_line, "--- 执行 #" . a:index . " (耗时 " . a:elapsed . ") ---")
    else
        lockmarks call appendbufline('%', a:last_line, "--- 执行 #" . a:index . " ---")
    endif
    let current_line = a:last_line + 1

    " 如果结果为空，插入空行；否则插入所有结果行
    if len(lines) == 0
        lockmarks call appendbufline('%', current_line, "")
    else
        lockmarks call appendbufline('%', current_line, lines)
    endif

    " 在结果之间添加空行分隔（最后一个结果不加）
    if a:index <= a:total
        lockmarks call appendbufline('%', current_line + len(lines), "")
    endif
endfunction

" 获取结果的行数（不包括分隔行）
function! GetResultLineCount(result)
    let result = substitute(a:result, '\n\+$', '', '')
    let lines = split(result, '\n', 1)
    return len(lines) == 0 ? 1 : len(lines)
endfunction

function! GetVisualSelection()
    " 临时禁用 clipboard，避免覆盖系统剪贴板
    let save_clipboard = &clipboard
    set clipboard=

    " 保存当前寄存器
    let save_reg = @"
    let save_reg_type = getregtype('"')

    try
        " 使用 silent 避免输出，使用 noautocmd 避免触发自动命令
        silent! noautocmd normal! gvy

        " 获取选中的文本
        let selected = @"
        return selected
    finally
        " 恢复寄存器和 clipboard 设置
        call setreg('"', save_reg, save_reg_type)
        let &clipboard = save_clipboard
    endtry
endfunction


" ============================================================================
" JSON 格式化功能（使用 jq）
" ============================================================================
function! FormatJSON()
    " 检查是否在可视模式（在退出可视模式前检查）
    let visual_mode = mode()
    let has_selection = visual_mode ==# 'v' || visual_mode ==# 'V' || visual_mode ==# "\<C-V>"
    let start_line = line("'<")
    let end_line = line("'>")
    " echoerr visual_mode . "-" . start_line . "-" . end_line

    if end_line - start_line
        " 有选中文本：保存选中范围，格式化后替换
        " 注意：必须在退出可视模式前保存范围
        let start_col = col("'<")
        let end_col = col("'>")
        let saved_visual_mode = visual_mode

        " 立即退出可视模式
        execute "normal! \<Esc>"

        " 使用 getline() 和 '<、'> 标记获取选中的文本
        " 这样更可靠，不依赖于可视模式状态
        let selected_lines = []

        " 如果是行选择模式（V），获取整行
        if saved_visual_mode ==# 'V'
            " 行选择模式：获取所有完整行
            for line_num in range(start_line, end_line)
                call add(selected_lines, getline(line_num))
            endfor
        else
            " 字符选择模式（v）或块选择模式（Ctrl-V）：考虑列位置
            if start_line == end_line
                " 单行：获取部分行
                let line_text = getline(start_line)
                if start_col <= end_col && start_col <= len(line_text)
                    let end_pos = min([end_col, len(line_text)])
                    let selected_text = line_text[start_col - 1 : end_pos - 1]
                    call add(selected_lines, selected_text)
                else
                    let selected_text = line_text
                    call add(selected_lines, selected_text)
                endif
            else
                " 多行：获取第一行的部分、中间完整行、最后行的部分
                let first_line = getline(start_line)
                if start_col <= len(first_line)
                    let first_part = first_line[start_col - 1 :]
                    call add(selected_lines, first_part)
                endif

                " 中间完整行
                for line_num in range(start_line + 1, end_line - 1)
                    call add(selected_lines, getline(line_num))
                endfor

                " 最后一行
                if end_line > start_line
                    let last_line = getline(end_line)
                    if end_col <= len(last_line)
                        let last_part = last_line[: end_col - 1]
                        call add(selected_lines, last_part)
                    else
                        call add(selected_lines, last_line)
                    endif
                endif
            endif
        endif

        let selected_text = join(selected_lines, "\n")

        " 调试：显示获取到的原始选中文本
        if len(selected_text) < 10
            echoerr "警告：选中的文本太短（只有 " . len(selected_text) . " 个字符）"
            echoerr "选中的文本: " . string(selected_text)
            echoerr "选中范围: " . start_line . "," . end_line . " 行，列 " . start_col . "-" . end_col
        endif

        " 调试：显示获取到的原始选中文本
        " echo "原始选中文本长度: " . len(selected_text)
        " echo "原始选中文本前100字符: " . strpart(selected_text, 0, 100)

        " 清理选中文本：去除首尾空白和隐藏字符，保留换行符
        let selected_text = substitute(selected_text, '\r', '', 'g')

        " 去除每行的行尾空白，但保留空行（因为空行可能是 JSON 格式的一部分）
        let cleaned_lines = []
        for line in split(selected_text, '\n', 1)
            let cleaned_line = substitute(line, '\s\+$', '', 'g')
            " 保留所有行，包括空行（因为格式化后的 JSON 可能有空行）
            call add(cleaned_lines, cleaned_line)
        endfor
        let selected_text = join(cleaned_lines, "\n")

        " 去除首尾空白行，但保留中间的换行符
        let selected_text = substitute(selected_text, '^\s*\n\+\|\n\+\s*$', '', 'g')

        if selected_text == ""
            echoerr "选中的文本为空（清理后）"
            return
        endif

        " 检查选中的文本是否看起来完整（至少应该以 { 或 [ 开头）
        let trimmed = substitute(selected_text, '^\s\+\|\s\+$', '', 'g')
        if len(trimmed) == 0
            echoerr "选中的文本为空（去除空白后）"
            return
        endif

        " 如果选中的文本只有很少的内容（比如只有 {），可能是选中不完整
        if len(trimmed) < 10 && trimmed =~ '^[{[]'
            echoerr "警告：选中的文本可能不完整（只有 " . len(trimmed) . " 个字符）"
            echoerr "选中的文本: " . trimmed
            echoerr "请确保选中完整的 JSON 对象或数组"
            return
        endif

        " 调试：显示清理后的文本
        " echo "清理后文本长度: " . len(selected_text)
        " echo "清理后文本前100字符: " . strpart(selected_text, 0, 100)

        " 使用 jq 格式化 JSON（压缩成一行）
        " jq 会自动处理多行 JSON 并压缩成一行
        let formatted = FormatJSONWithJQ(selected_text, 1)

        " 如果格式化失败，显示调试信息
        if formatted == ""
            echoerr "格式化失败！"
            echoerr "选中的文本长度: " . len(selected_text)
            echoerr "选中的文本前500字符: " . strpart(selected_text, 0, 500)
            return
        endif

        " 如果格式化成功，替换选中的文本
        if formatted != ""
            " 删除选中的行
            if start_line == end_line
                " 单行：删除整行并插入格式化后的内容
                lockmarks execute start_line . "delete"
                lockmarks call appendbufline('%', start_line - 1, formatted)
                let new_start_line = start_line
                let new_end_line = start_line
            else
                " 多行：删除所有行，在第一行位置插入格式化后的内容
                lockmarks execute start_line . "," . end_line . "delete"
                lockmarks call appendbufline('%', start_line - 1, formatted)
                let new_start_line = start_line
                let new_end_line = start_line
            endif

            " 恢复选中状态（选中格式化后的内容）
            " 根据原始的可视模式类型恢复选择
            if saved_visual_mode ==# 'V'
                " 行选择模式
                execute "normal! " . new_start_line . "GV" . new_end_line . "G"
            elseif saved_visual_mode ==# 'v'
                " 字符选择模式
                execute "normal! " . new_start_line . "G0v" . new_end_line . "G$"
            else
                " 块选择模式
                execute "normal! " . new_start_line . "G0\<C-V>" . new_end_line . "G$"
            endif
        else
            " 格式化失败，恢复选中状态以便用户重试
            if saved_visual_mode ==# 'V'
                execute "normal! " . start_line . "GV" . end_line . "G"
            elseif saved_visual_mode ==# 'v'
                execute "normal! " . start_line . "G" . start_col . "|v" . end_line . "G" . end_col . "|"
            else
                execute "normal! " . start_line . "G" . start_col . "|\<C-V>" . end_line . "G" . end_col . "|"
            endif
        endif
    else
        " 没有选中文本：格式化当前行并替换
        let current_line = line(".")
        let current_text = getline(current_line)

        " 清理文本：去除首尾空白和隐藏字符
        let current_text = substitute(current_text, '\r', '', 'g')
        let current_text = substitute(current_text, '^\s\+\|\s\+$', '', 'g')

        if current_text == ""
            echoerr "当前行为空"
            return
        endif

        " 使用 jq 格式化 JSON（美化格式）
        let formatted = FormatJSONWithJQ(current_text, 0)

        " 如果格式化成功，替换当前行
        if formatted != ""
            " 如果格式化后是多行，需要特殊处理
            let lines = split(formatted, '\n', 1)
            if len(lines) == 1
                " 单行：直接替换
                lockmarks call setline(current_line, lines[0])
            else
                " 多行：删除当前行，插入多行
                lockmarks execute current_line . "delete"
                lockmarks call appendbufline('%', current_line - 1, lines)
            endif
        " 如果格式化失败，错误信息已经在 FormatJSONWithJQ 中显示
        endif
    endif
endfunction

" 使用 jq 格式化 JSON
" text: 要格式化的 JSON 文本
" compact: 1=压缩成一行, 0=美化格式
function! FormatJSONWithJQ(text, compact)
    " 检查 jq 是否可用
    if !executable('jq')
        echoerr "jq 未安装或不在 PATH 中，请先安装 jq"
        return ""
    endif

    " 清理文本：去除隐藏字符，保留换行符（jq 能正确处理多行 JSON）
    let text = substitute(a:text, '\r', '', 'g')

    " 去除每行的行尾空白，但保留行首空白（可能是指定格式）
    let cleaned_lines = []
    for line in split(text, '\n', 1)
        " 去除行尾空白
        let cleaned_line = substitute(line, '\s\+$', '', 'g')
        call add(cleaned_lines, cleaned_line)
    endfor
    let text = join(cleaned_lines, "\n")

    " 去除整个文本的首尾空白
    let text = substitute(text, '^\s\+\|\s\+$', '', 'g')

    if text == ""
        return ""
    endif

    " 使用临时文件传递 JSON 给 jq
    " 使用 writefile 可以正确处理多行文本
    let temp_file = tempname()

    try
        " 将文本按行分割，确保多行 JSON 正确写入
        let lines = split(text, '\n', 1)
        call writefile(lines, temp_file)

        " 根据 compact 参数选择格式化方式
        if a:compact
            " 压缩成一行（-c 参数）
            let result = system("jq -c . " . shellescape(temp_file) . " 2>&1")
        else
            " 美化格式（默认）
            let result = system("jq . " . shellescape(temp_file) . " 2>&1")
        endif
    finally
        " 清理临时文件
        if filereadable(temp_file)
            call delete(temp_file)
        endif
    endtry

    " 检查是否出错
    if v:shell_error != 0
        " 显示具体错误信息（去除文件路径）
        let error_msg = substitute(result, temp_file . ':', '', 'g')
        let error_msg = substitute(error_msg, '\n\+$', '', 'g')

        " 显示错误信息和调试信息
        echoerr "JSON 格式错误: " . error_msg

        " 如果错误信息包含 "Unfinished JSON" 或 "EOF"，可能是选中不完整
        if error_msg =~ "Unfinished JSON\|EOF"
            echoerr "提示：可能选中不完整，请确保选中完整的 JSON 对象或数组"
        endif

        " 调试：显示原始文本的前500个字符
        let debug_text = len(a:text) > 500 ? strpart(a:text, 0, 500) . "..." : a:text
        echoerr "原始文本（前500字符）: " . debug_text
        echoerr "原始文本总长度: " . len(a:text) . " 字符"
        echoerr "原始文本行数: " . len(split(a:text, '\n', 1))

        " 调试：显示写入文件的内容
        try
            let file_lines = readfile(temp_file)
            echoerr "写入文件的行数: " . len(file_lines)
            if len(file_lines) > 10
                echoerr "写入文件的前10行: " . string(file_lines[:9])
            else
                echoerr "写入文件的所有内容: " . string(file_lines)
            endif
        catch
            echoerr "无法读取临时文件"
        endtry

        return ""
    endif

    " 去除结果末尾的换行符
    let result = substitute(result, '\n\+$', '', '')

    return result
endfunction


" ============================================================================
" 格式化 curl 命令
" ============================================================================
function! FormatCurl()
    " 检查是否有选中文本（通过检查 '< 和 '> 标记）
    let start_line = line("'<")
    let end_line = line("'>")
    let current_line = line(".")

    " 如果 start_line 和 end_line 不同，或者它们不等于当前行，说明有选中
    let has_selection = (start_line != end_line) || (start_line != current_line)

    if has_selection
        " 有选中文本
        " 获取选中的文本
        let lines = getline(start_line, end_line)
        let selected_text = join(lines, "\n")
    else
        " 没有选中文本，使用当前行
        let start_line = current_line
        let end_line = current_line
        let selected_text = getline(".")
    endif

    " 保存当前光标位置
    let save_cursor = getpos(".")

    if selected_text == ""
        echoerr "文本为空"
        return
    endif

    " 格式化
    let formatted = FormatCurlText(selected_text)

    if formatted == ""
        echoerr "格式化失败"
        return
    endif

    " 替换选中的文本
    lockmarks execute start_line . "," . end_line . "delete"
    let formatted_lines = split(formatted, '\n', 1)
    lockmarks call appendbufline('%', start_line - 1, formatted_lines)

    " 恢复光标位置
    call setpos(".", save_cursor)
endfunction

function! FormatCurlText(text)
    let temp_input = tempname()

    try
        " 写入输入文本
        call writefile(split(a:text, '\n', 1), temp_input)

        " Python 脚本
        let python_code = [
            \ "import re",
            \ "",
            \ "with open('" . temp_input . "', 'r') as f:",
            \ "    text = f.read()",
            \ "",
            \ "def find_and_convert(text):",
            \ "    result = []",
            \ "    i = 0",
            \ "    ",
            \ "    while i < len(text):",
            \ "        # 尝试匹配参数标记 -xxx 或 --xxx",
            \ "        match = re.match(r'(--?[a-zA-Z][a-zA-Z0-9-]*)(\\s+)', text[i:])",
            \ "        if match:",
            \ "            param = match.group(1)",
            \ "            space = match.group(2)",
            \ "            i += len(match.group(0))",
            \ "            ",
            \ "            # 检查后面是否是引号",
            \ "            if i < len(text):",
            \ "                quote_char = text[i]",
            \ "                ",
            \ "                if quote_char == \"'\":",
            \ "                    # 单引号：找到结束的单引号并转换",
            \ "                    i += 1  # 跳过开始的单引号",
            \ "                    content_start = i",
            \ "                    ",
            \ "                    # 找结束的单引号（考虑 \\' 转义）",
            \ "                    while i < len(text):",
            \ "                        if text[i] == \"'\":",
            \ "                            # 找到单引号，结束",
            \ "                            break",
            \ "                        elif text[i] == '\\\\' and i + 1 < len(text) and text[i + 1] == \"'\":",
            \ "                            # 跳过 \\\\'",
            \ "                            i += 2",
            \ "                        else:",
            \ "                            i += 1",
            \ "                    ",
            \ "                    content = text[content_start:i]",
            \ "                    ",
            \ "                    # 转换内容",
            \ "                    content = content.replace(\"\\\\\\'\" , \"'\")",
            \ "                    content = content.replace('\"', '\\\\\"')",
            \ "                    content = content.replace('$', '\\\\$')",
            \ "                    content = content.replace('`', '\\\\`')",
            \ "                    ",
            \ "                    # 输出转换后的内容",
            \ "                    result.append(param + space + '\"' + content + '\"')",
            \ "                    i += 1  # 跳过结束的单引号",
            \ "                    ",
            \ "                elif quote_char == '\"':",
            \ "                    # 双引号：直接输出，不转换",
            \ "                    i += 1  # 跳过开始的双引号",
            \ "                    content_start = i",
            \ "                    ",
            \ "                    # 找结束的双引号",
            \ "                    while i < len(text):",
            \ "                        if text[i] == '\"' and (i == 0 or text[i-1] != '\\\\'):",
            \ "                            break",
            \ "                        i += 1",
            \ "                    ",
            \ "                    content = text[content_start:i]",
            \ "                    result.append(param + space + '\"' + content + '\"')",
            \ "                    i += 1  # 跳过结束的双引号",
            \ "                    ",
            \ "                else:",
            \ "                    # 不是引号，输出参数标记",
            \ "                    result.append(param + space)",
            \ "            else:",
            \ "                result.append(param + space)",
            \ "        else:",
            \ "            # 不是参数标记，直接输出字符",
            \ "            result.append(text[i])",
            \ "            i += 1",
            \ "    ",
            \ "    return ''.join(result)",
            \ "",
            \ "result = find_and_convert(text)",
            \ "print(result, end='')",
            \ ]

        let python_script = tempname() . ".py"
        call writefile(python_code, python_script)

        " 执行 Python 脚本
        let result = system("python3 " . shellescape(python_script) . " 2>&1")
        let exit_code = v:shell_error

        " 清理 Python 脚本
        if filereadable(python_script)
            call delete(python_script)
        endif

        if exit_code != 0
            echoerr "格式化失败: " . result
            return ""
        endif

        " 去除末尾换行符
        let result = substitute(result, '\n\+$', '', '')

        return result
    finally
        " 清理临时文件
        if filereadable(temp_input)
            call delete(temp_input)
        endif
    endtry
endfunction

