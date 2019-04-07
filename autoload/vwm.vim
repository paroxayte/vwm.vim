" Main plugin logic

fun! vwm#close(name)
  let l:node_index = util#lookup_node(a:name)
  if l:node_index == -1
    return -1
  endif
  let l:node = g:vwm#layouts[l:node_index]

  let l:Funcr = function('s:close_helper', [l:node.cache])
  let l:FRaftr = function('s:deactivate')
  call util#traverse(l:node, v:null, l:FRaftr, v:null, l:Funcr)
endfun

fun! s:close_helper(cache, node, trash, ori)
  if util#buf_active(a:node["bid"])
    if a:cache
      execute(bufwinnr(a:node.bid) . 'wincmd w')
      close
    else
      execute(a:node.bid . 'bw')
    endif
  endif
endfun

fun! s:deactivate(node, trash)
  let a:node['active'] = 0
endfun

fun! vwm#open(name)
  let l:nodeIndex = util#lookup_node(a:name)
  if l:nodeIndex == -1
    return -1
  endif

  let l:node = g:vwm#layouts[l:nodeIndex]
  let l:node.bid = bufnr('%')
  let l:Primer = function('s:populate_root')
  let l:RAftr = function('s:update_node')
  let l:FBfr = function('s:populate_child')
  let l:FAftr = function('s:fill_winnode')

  " Begin winnode population
  call util#traverse(l:node, l:Primer, l:RAftr, l:FBfr, l:FAftr)
endfun

fun! s:update_node(node, def)
  for ori in keys(a:def)
    let a:node[ori] = a:def[ori]
  endfor
endfun

fun! s:populate_root(node, ori)
  if a:node.abs

    if a:ori == 1
      vert to new
    elseif a:ori == 2
      vert bo new
    elseif a:ori == 3
      to new
    elseif a:ori == 4
      bo new
    else
      echoerr "unexpected val passed to s:populate_root(...)"
      return -1
    endif

    call s:buf_mktmp()
  else
    call s:populate_child(a:node, a:ori)
  endif

  let a:node['active'] = 1
endfun

fun! s:populate_child(node, ori)
  if a:ori == 1
    vert abo new
  elseif a:ori == 2
    vert bel new
  elseif a:ori == 3
    abo new
  elseif a:ori == 4
    bel new
  else
    echoerr "unexpected val passed to s:populate_root(...)"
    return -1
  endif

  call s:buf_mktmp()
endfun

fun! s:buf_mktmp()
  setlocal nobl bh=wipe bt=nofile noswapfile
endfun

fun! s:fill_winnode(node, trash, ori)
  call util#resz_winnode(a:node, a:ori)
  let a:node.bid = s:place_content(a:node)
  call util#resz_winnode(a:node, a:ori)
  execute(bufwinnr(a:node.bid) . 'wincmd w')
endfun

fun! vwm#toggle(name)
  let l:nodeIndex = util#lookup_node(a:name)
  if l:nodeIndex == -1
    return -1
  endif
  let l:node = g:vwm#layouts[l:nodeIndex]

  if l:node.active
    call vwm#close(a:name)
  else
    call vwm#open(a:name)
  endif
endfun

fun! vwm#close_all()
  for node in util#active_nodes()
    call s:close_main(node, node.cache)
  endfor
endfun

fun! s:place_content(node)
  let l:init_buf = bufnr('%')
  let l:init_wid = bufwinnr(l:init_buf)

  let l:init_last = bufwinnr('$')

  " If buf exists, place it in current window and kill tmp buff
  if util#buf_exists(a:node.bid)
    execute(a:node.bid . 'b')
    call s:execute_cmds(a:node.restore)
    return bufnr('%')
  endif

  " Otherwise create the buff and force it to be in the current window
  call s:execute_cmds(a:node.init)
  let l:final_last = bufwinnr('$')

  if l:init_last != l:final_last
    let l:final_buf = winbufnr(l:final_last)
    execute(l:final_last . 'wincmd w')
    close
    execute(l:init_wid . 'wincmd w')
    execute(l:final_buf . 'b')
  endif

  return bufnr('%')
endfun

" Execute layout defined commands. Accept funcrefs and Strings
fun! s:execute_cmds(cmds)
  for Cmd in a:cmds
    if type(Cmd) == 2
      call Cmd()
    else
      execute(Cmd)
    endif
  endfor
endfun
