" Vdebug: Powerful, fast, multi-language debugger client for Vim.
" Maintainer: Jon Cairns
" License: MIT License
" Version: 2.0.0

" Avoid double loading of Vdebug
if exists('g:is_vdebug_loaded')
    finish
endif

let g:is_vdebug_loaded = 1

" Ensure Python3 is available
if !has('python3')
    echomsg ':python3 is not available, vdebug will not be loaded.'
    finish
endif

" Initialize default keymaps and options
let g:vdebug_keymap_defaults = {
\   'run': '<F5>',
\   'run_to_cursor': '<F9>',
\   'step_over': '<F2>',
\   'step_into': '<F3>',
\   'step_out': '<F4>',
\   'close': '<F6>',
\   'detach': '<F7>',
\   'set_breakpoint': '<F10>',
\   'get_context': '<F11>',
\   'eval_under_cursor': '<F12>',
\   'eval_visual': '<Leader>e'
\}

let g:vdebug_options_defaults = {
\   'port': 9000,
\   'timeout': 20,
\   'server': '',
\   'proxy_host': '',
\   'proxy_port': 9001,
\   'on_close': 'stop',
\   'break_on_open': 1,
\   'ide_key': '',
\   'debug_window_level': 0,
\   'debug_file_level': 0,
\   'debug_file': '',
\   'path_maps': {},
\   'watch_window_style': 'expanded',
\   'marker_default': '⬦',
\   'marker_closed_tree': '▸',
\   'marker_open_tree': '▾',
\   'sign_breakpoint': '▷',
\   'sign_current': '▶',
\   'sign_current_stack_position': '▶',
\   'sign_disabled': '▌▌',
\   'continuous_mode': 1,
\   'background_listener': 1,
\   'auto_start': 1,
\   'simplified_status': 1,
\   'layout': 'vertical'
\}

" Load options and keymaps with validation
if !exists('g:vdebug_keymap')
    let g:vdebug_keymap = copy(g:vdebug_keymap_defaults)
else
    let g:vdebug_keymap = extend(copy(g:vdebug_keymap_defaults), g:vdebug_keymap)
endif

if !exists('g:vdebug_options')
    let g:vdebug_options = copy(g:vdebug_options_defaults)
else
    let g:vdebug_options = extend(copy(g:vdebug_options_defaults), g:vdebug_options)
endif

" Adjust markers for ASCII-only systems
if has('win32') || has('win64') || has('multi_byte') == 0
    let g:vdebug_options['marker_default'] = '*'
    let g:vdebug_options['marker_closed_tree'] = '+'
    let g:vdebug_options['marker_open_tree'] = '-'
    let g:vdebug_options['sign_breakpoint'] = 'B>'
    let g:vdebug_options['sign_current'] = '->'
    let g:vdebug_options['sign_current_stack_position'] = '->'
    let g:vdebug_options['sign_disabled'] = 'B|'
endif

" Define debugging-related signs
function! s:DefineSigns()
    execute 'sign define breakpt text=' . g:vdebug_options['sign_breakpoint'] . ' texthl=DbgBreakptSign linehl=DbgBreakptLine'
    execute 'sign define current text=' . g:vdebug_options['sign_current'] . ' texthl=DbgCurrentSign linehl=DbgCurrentLine'
    execute 'sign define breakpt_dis text=' . g:vdebug_options['sign_disabled'] . ' texthl=DbgDisabledSign linehl=DbgDisabledLine'
    execute 'sign define current_stack_position text=' . g:vdebug_options['sign_current_stack_position'] . ' texthl=DbgCurrentStackPositionSign linehl=DbgCurrentStackPositionLine'
endfunction

" Reload options with defaults
function! Vdebug_load_options(options)
    let a:options = type(a:options) == type({}) ? a:options : {}
    let g:vdebug_options = extend(copy(g:vdebug_options_defaults), a:options)
    call s:DefineSigns()
    python3 debugger.reload_options()
endfunction

" Reload keymaps with defaults
function! Vdebug_load_keymaps(keymaps)
    let l:keymaps = type(a:keymaps) == type({}) ? a:keymaps : {}
    if empty(l:keymaps)
        echomsg 'Warning: Vdebug keymaps are empty. Using defaults.'
        let l:keymaps = copy(g:vdebug_keymap_defaults)
    endif
    let g:vdebug_keymap = extend(copy(g:vdebug_keymap_defaults), l:keymaps)
    for [key, mapping] in items(g:vdebug_keymap)
        execute 'noremap <silent> ' . mapping . ' :python3 debugger.'.key.'()<CR>'
    endfor
    python3 debugger.reload_keymappings()
endfunction

" Highlight groups for debugging
if hlexists('DbgCurrentLine') == 0
    highlight default DbgCurrentLine ctermfg=White ctermbg=Red guifg=#ffffff guibg=#ff0000
endif
if hlexists('DbgBreakptLine') == 0
    highlight default DbgBreakptLine ctermfg=White ctermbg=Green guifg=#ffffff guibg=#00ff00
endif
if hlexists('DbgDisabledLine') == 0
    highlight default DbgDisabledLine ctermfg=Cyan guifg=#888888 guibg=#b4ee9a
endif

" Python debugger initialization
python3 import vdebug.debugger_interface
python3 debugger = vdebug.debugger_interface.DebuggerInterface()

" Commands
command! -nargs=? VdebugChangeStack python3 debugger.change_stack(<q-args>)
command! -nargs=? -complete=customlist,s:BreakpointTypes Breakpoint python3 debugger.cycle_breakpoint(<q-args>)
command! -nargs=? SetBreakpoint python3 debugger.set_breakpoint(<q-args>)
command! VdebugStart python3 debugger.run()
command! BreakpointRemove python3 debugger.remove_breakpoint(<q-args>)
command! BreakpointToggle python3 debugger.toggle_breakpoint(<q-args>)
command! BreakpointWindow python3 debugger.toggle_breakpoint_window()
command! -nargs=? -bang VdebugEval python3 debugger.handle_eval('<bang>', <q-args>)

" Automatically load options and keymaps
call Vdebug_load_options(g:vdebug_options)
call Vdebug_load_keymaps(g:vdebug_keymap)
