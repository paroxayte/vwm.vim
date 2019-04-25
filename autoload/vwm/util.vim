" Utility functions for vim window manager

"------------------------------------------Layout traversal-----------------------------------------

" Traversal funcref signatures:
" bfr    :: dict -> int -> a
" aftr   :: dict -> int -> a

" Right recursive traverse and do
" If horz is true traverse top and bot, if vert is true traverse left and right
" node_type = { 0: 'root', 1: 'left', 2: 'right', 3: 'top', 4: 'bot', 5: 'float }
" Cache is an empty dictionary for saving special info through recursion
fun! vwm#util#traverse(target, bfr, aftr, horz, vert, node_type, cache)

  if !(a:bfr is v:null)
    call vwm#util#execute(a:bfr, a:target, a:node_type, a:cache)
  endif

  let l:bnr = bufnr('%')

  " Save the buffer id at each level
  if a:vert

    if util#node_has_child(a:target, 'left')
      call vwm#util#traverse(a:target.left, a:bfr, a:aftr, v:true, v:true, 1, a:cache)
      execute(bufwinnr(l:bnr) . 'wincmd w')
    endif
    if util#node_has_child(a:target, 'right')
      call vwm#util#traverse(a:target.right, a:bfr, a:aftr, v:true, v:true, 2, a:cache)
      execute(bufwinnr(l:bnr) . 'wincmd w')
    endif

  endif

  if a:horz

    if util#node_has_child(a:target, 'top')
      call vwm#util#traverse(a:target.top, a:bfr, a:aftr, v:true, v:true, 3, a:cache)
      execute(bufwinnr(l:bnr) . 'wincmd w')
    endif
    if util#node_has_child(a:target, 'bot')
      call vwm#util#traverse(a:target.bot, a:bfr, a:aftr, v:true, v:true, 4, a:cache)
      execute(bufwinnr(l:bnr) . 'wincmd w')
    endif

  endif

  if util#node_has_child(a:target, 'float')
    call vwm#util#traverse(a:target.float, a:bfr, a:aftr, v:true, v:true, 5, a:cache)
  endif

  if !(a:aftr is v:null)
    call vwm#util#execute(a:aftr, a:target, a:node_type, a:cache)
    execute(bufwinnr(l:bnr) . 'wincmd w')
  endif

endfun


fun! util#node_has_child(node, pos)
  if eval("exists('a:node." . a:pos . "')")
    return eval('len(a:node.' . a:pos . ')') ? 1 : 0
  endif
  return 0
endfun

"-----------------------------------------------Misc------------------------------------------------

" If a funcref is given, execute the function. Else assume list of strings
" Arity arg represents a list of arguments to be passed to the funcref
fun! vwm#util#execute(target, ...)
  if type(a:target) == 2
    let l:Vwm_Target = s:apply_funcref(a:target, a:000)
    call l:Vwm_Target()

  else

    for l:Cmd in a:target

      if type(l:Cmd) == 2
        let l:Vwm_Target = s:apply_funcref(l:Cmd, a:000)
        call l:Vwm_Target()
      else
        execute(l:Cmd)
      endif

    endfor

  endif
endfun

fun! s:apply_funcref(f, args)
    if a:args != [v:null] && len(a:args)
      let l:F = function(eval(string(a:f)), a:args)
    else
      let l:F = a:f
    endif
    return l:F
endfun

" If Target is a funcref, return it's result. Else return Target.
fun! vwm#util#get(Target)
  if type(a:Target) == 2
    return a:Target()
  else
    return a:Target
  endif
endfun

" Returns the first node in g:vwm#layouts with a matching name
fun! vwm#util#lookup(name)
  for l:node in g:vwm#layouts

    if a:name == l:node.name
      return l:node
    endif

  endfor

  echoerr a:name . " not in dictionary"
  return -1
endfun

" Returns true if the buffer exists in a currently visable window
fun! vwm#util#buf_active(bid)
  return bufwinnr(a:bid) == -1 ? v:false : v:true
endfun

" Returns true if the buffer exists
fun! vwm#util#buf_exists(bid)
  return bufname(a:bid) =~ '^$' ? v:false : v:true
endfun

" Retruns a list of all active layouts
fun! vwm#util#active()
  let l:active = []
  for node in g:vwm#layouts

    if node.active
      let l:active += [node]
    endif

  endfor
  return l:active
endfun