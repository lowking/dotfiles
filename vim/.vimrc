let $BASH_ENV="~/.vim_bash_env"

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
vnoremap <leader>] :<C-U>call ExecuteAndAppend(v:count1)<CR>
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
    " count 默认为 1，如果用户输入了数字前缀则使用该数字
    let exec_count = a:count > 0 ? a:count : 1
    
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
    
    " 去除选中文本末尾的换行符
    let selected_text = substitute(selected_text, '\n$', '', '')
    
    " 如果命令为空，直接返回
    if selected_text == ""
        echoerr "选中的文本为空"
        return
    endif
    
    " 处理续行符：将续行符和换行符合并成单行
    let processed_text = selected_text
    " 将续行符+空格+换行符合并为空格
    let processed_text = substitute(processed_text, '[\\/]\s*\n\s*', ' ', 'g')
    " 处理末尾的续行符
    let processed_text = substitute(processed_text, '[\\/]\s*$', '', 'g')
    " 压缩多个连续空格
    let processed_text = substitute(processed_text, '\s\+', ' ', 'g')
    " 去除首尾空格
    let processed_text = substitute(processed_text, '^\s\+\|\s\+$', '', 'g')
    
    " 使用之前保存的结束行号（因为我们已经退出了可视模式）
    let last_line = end_line

    " 每次执行都加一行空行, 方便vip选中命令
    call append(last_line, "")
    let last_line = last_line + 1
    
    " 如果执行次数大于1，使用并发执行；否则顺序执行
    if exec_count > 1
        " 并发执行所有命令
        let results = ExecuteCommandConcurrent(processed_text, exec_count)
        
        " 按顺序追加所有结果
        let i = 1
        for result_item in results
            " 解析结果：result_item 是 [timestamp, content] 或直接是字符串
            let timestamp = ""
            let result = ""
            if type(result_item) == 3 && len(result_item) == 2
                let timestamp = result_item[0]
                let result = result_item[1]
            else
                let result = result_item
            endif
            
            call AppendResult(last_line, result, timestamp, i, exec_count)
            " 更新 last_line：分隔行(1) + 结果行数 + (如果不是最后一个结果，还有分隔空行1)
            let result_lines = GetResultLineCount(result)
            let last_line = last_line + 1 + result_lines + (i < exec_count ? 1 : 0)
            let i = i + 1
        endfor
    else
        " 单次执行，直接调用
        let result = ExecuteCommand(processed_text)
        call AppendResult(last_line, result, "", 1, 1)
    endif
    
    " 恢复选中状态，方便再次执行
    " 根据原始的可视模式类型恢复选择
    if visual_mode ==# 'V'
        " 行选择模式
        execute "normal! " . start_line . "GV" . end_line . "G"
    elseif visual_mode ==# 'v'
        " 字符选择模式
        execute "normal! " . start_line . "G" . start_col . "|v" . end_line . "G" . end_col . "|"
    else
        " 块选择模式
        execute "normal! " . start_line . "G" . start_col . "|\<C-V>" . end_line . "G" . end_col . "|"
    endif
endfunction

function! ExecuteCommandConcurrent(command_text, count)
    " 创建临时文件来保存命令
    let temp_file = tempname()
    
    try
        " 将命令写入临时文件
        call writefile([a:command_text], temp_file)
        
        " 使用 Python 的并发功能执行多次命令
        let python_script = tempname() . ".py"
        let python_code = [
            \ "#!/usr/bin/env python3",
            \ "import subprocess, sys, time",
            \ "from concurrent.futures import ThreadPoolExecutor",
            \ "from datetime import datetime",
            \ "",
            \ "with open('" . temp_file . "', 'r', encoding='utf-8', errors='ignore') as f:",
            \ "    cmd = f.read().strip()",
            \ ""
            \ ] + GetPythonFixQuoteEscapeCode() + [
            \ "def run_command(cmd, index):",
            \ "    start_time = time.time()",
            \ "    # 记录执行开始的时间点，格式：YYYY-MM-dd HH:mm:ss.sss",
            \ "    timestamp = datetime.fromtimestamp(start_time).strftime('%Y-%m-%d %H:%M:%S.%f')[:-3]",
            \ "    try:",
            \ "        result = subprocess.run(cmd, shell=True, executable='/bin/sh',",
            \ "                              capture_output=True, text=True,",
            \ "                              stdin=subprocess.DEVNULL)",
            \ "        # 先输出响应内容（stdout），再输出统计信息（stderr），用换行分隔",
            \ "        stdout = result.stdout.rstrip('\\n\\r')",
            \ "        stderr = result.stderr.rstrip('\\n\\r')",
            \ "        if stdout and stderr:",
            \ "            output = stdout + '\\n' + stderr",
            \ "        elif stdout:",
            \ "            output = stdout",
            \ "        elif stderr:",
            \ "            output = stderr",
            \ "        else:",
            \ "            output = ''",
            \ "        if result.returncode != 0:",
            \ "            output = '【执行错误，退出码: ' + str(result.returncode) + '】\\n' + output",
            \ "        return (index, timestamp, output)",
            \ "    except Exception as e:",
            \ "        return (index, timestamp, '【执行异常: ' + str(e) + '】')",
            \ "",
            \ "cmd = fix_single_quote_escape(cmd)",
            \ "count = " . a:count,
            \ "",
            \ "# 使用线程池并发执行",
            \ "results = [None] * count",
            \ "with ThreadPoolExecutor(max_workers=count) as executor:",
            \ "    futures = [executor.submit(run_command, cmd, i) for i in range(count)]",
            \ "    # 按提交顺序收集结果，保持顺序（按索引顺序等待）",
            \ "    for i in range(len(futures)):",
            \ "        index, timestamp, output = futures[i].result()",
            \ "        # 确保按提交顺序存储",
            \ "        results[i] = (timestamp, output)",
            \ "",
            \ "# 输出结果，使用分隔符避免特殊字符问题",
            \ "for i, (timestamp, output) in enumerate(results):",
            \ "    if i > 0:",
            \ "        sys.stdout.write('\\n---RESULT_SEPARATOR---\\n')",
            \ "    # 输出格式：时间戳|结果",
            \ "    sys.stdout.write(timestamp + '|' + output)",
            \ "    if not output.endswith('\\n'):",
            \ "        sys.stdout.write('\\n')",
            \ ]
        call writefile(python_code, python_script)
        
        " 执行 Python 脚本
        let result = system("python3 " . shellescape(python_script) . " 2>&1")
        let python_exit_code = v:shell_error
        
        " 清理 Python 脚本
        if filereadable(python_script)
            call delete(python_script)
        endif
        
        " 检查是否出错
        if python_exit_code != 0
            return [["", result]]
        endif
        
        " 使用分隔符分割结果
        " 格式：时间戳(YYYY-MM-dd HH:mm:ss.sss)|结果内容
        let raw_results = split(result, '\n---RESULT_SEPARATOR---\n', 1)
        
        " 如果分割失败，说明只有一个结果
        if len(raw_results) == 1 && result !~ '---RESULT_SEPARATOR---'
            " 尝试解析单个结果（时间戳格式：YYYY-MM-dd HH:mm:ss.sss）
            if raw_results[0] =~ '^\d\{4}-\d\{2}-\d\{2} \d\{2}:\d\{2}:\d\{2}\.\d\{3}|'
                let parts = split(raw_results[0], '|', 1)
                if len(parts) >= 2
                    let timestamp = parts[0]
                    let content = join(parts[1:], '|')
                    return [[timestamp, content]]
                endif
            endif
            return [["", raw_results[0]]]
        endif
        
        " 解析每个结果
        let results = []
        for raw_result in raw_results
            " 匹配时间戳格式：YYYY-MM-dd HH:mm:ss.sss
            if raw_result =~ '^\d\{4}-\d\{2}-\d\{2} \d\{2}:\d\{2}:\d\{2}\.\d\{3}|'
                let parts = split(raw_result, '|', 1)
                if len(parts) >= 2
                    let timestamp = parts[0]
                    let content = join(parts[1:], '|')
                    call add(results, [timestamp, content])
                else
                    call add(results, ["", raw_result])
                endif
            else
                call add(results, ["", raw_result])
            endif
        endfor
        
        return results
    finally
        " 清理临时文件
        if filereadable(temp_file)
            call delete(temp_file)
        endif
    endtry
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

function! ExecuteCommand(command_text)
    " 创建临时文件来保存命令
    let temp_file = tempname()
    
    try
        " 将命令写入临时文件
        call writefile([a:command_text], temp_file)
        
        " 使用 Python 修复单引号转义问题并执行命令
        let python_script = tempname() . ".py"
        let python_code = [
            \ "#!/usr/bin/env python3",
            \ "import subprocess, sys",
            \ "with open('" . temp_file . "', 'r', encoding='utf-8', errors='ignore') as f:",
            \ "    cmd = f.read().strip()",
            \ ""
            \ ] + GetPythonFixQuoteEscapeCode() + [
            \ "cmd = fix_single_quote_escape(cmd)",
            \ "",
            \ "try:",
            \ "    result = subprocess.run(cmd, shell=True, executable='/bin/sh',",
            \ "                          capture_output=True, text=True,",
            \ "                          stdin=subprocess.DEVNULL)",
            \ "    stdout = result.stdout.rstrip('\\n\\r')",
            \ "    stderr = result.stderr.rstrip('\\n\\r')",
            \ "    if stdout and stderr:",
            \ "        output = stdout + '\\n' + stderr",
            \ "    elif stdout:",
            \ "        output = stdout",
            \ "    elif stderr:",
            \ "        output = stderr",
            \ "    else:",
            \ "        output = ''",
            \ "    if result.returncode != 0:",
            \ "        output = '【执行错误，退出码: ' + str(result.returncode) + '】\\n' + output",
            \ "    sys.stdout.write(output)",
            \ "    sys.exit(result.returncode)",
            \ "except Exception as e:",
            \ "    sys.stderr.write('【执行异常: ' + str(e) + '】')",
            \ "    sys.exit(1)"
            \ ]
        call writefile(python_code, python_script)
        
        " 执行 Python 脚本
        let result = system("python3 " . shellescape(python_script) . " 2>&1")
        let python_exit_code = v:shell_error
        
        " 清理 Python 脚本
        if filereadable(python_script)
            call delete(python_script)
        endif
        
        " 检查命令是否执行成功
        if python_exit_code != 0 && result !~ '【执行错误'
            let result = "【执行错误，退出码: " . python_exit_code . "】\n" . result
        endif
        
        return result
    finally
        " 清理临时文件
        if filereadable(temp_file)
            call delete(temp_file)
        endif
    endtry
endfunction

" 追加执行结果到文件
function! AppendResult(last_line, result, timestamp, index, total)
    " 去除结果末尾的换行符
    let result = substitute(a:result, '\n\+$', '', '')
    
    " 将结果按行分割（保留空行）
    let lines = split(result, '\n', 1)
    
    " 添加分隔行标识每次执行，包含执行时间点
    if a:timestamp != ""
        call append(a:last_line, "--- 执行 #" . a:index . " (" . a:timestamp . ") ---")
    else
        call append(a:last_line, "--- 执行 #" . a:index . " ---")
    endif
    let current_line = a:last_line + 1
    
    " 如果结果为空，插入空行；否则插入所有结果行
    if len(lines) == 0
        call append(current_line, "")
    else
        call append(current_line, lines)
    endif
    
    " 在结果之间添加空行分隔（最后一个结果不加）
    if a:index <= a:total
        call append(current_line + len(lines), "")
    endif
endfunction

" 获取结果的行数（不包括分隔行）
function! GetResultLineCount(result)
    let result = substitute(a:result, '\n\+$', '', '')
    let lines = split(result, '\n', 1)
    return len(lines) == 0 ? 1 : len(lines)
endfunction

function! GetVisualSelection()
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
        " 恢复寄存器
        call setreg('"', save_reg, save_reg_type)
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
                execute start_line . "delete"
                call append(start_line - 1, formatted)
                let new_start_line = start_line
                let new_end_line = start_line
            else
                " 多行：删除所有行，在第一行位置插入格式化后的内容
                execute start_line . "," . end_line . "delete"
                call append(start_line - 1, formatted)
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
                call setline(current_line, lines[0])
            else
                " 多行：删除当前行，插入多行
                execute current_line . "delete"
                call append(current_line - 1, lines)
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

