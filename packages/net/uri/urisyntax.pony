use "debug"
use "collections"

class val _UriSyntax
  let _uri: String
  let _max_i: USize

  new val create(source: String) =>
    _uri = source
    _max_i = source.size() - 1

  fun parse_uri():
    (String, OptionalAuthority, String, OptionalQuery, OptionalFragment,
    USize) ?
  =>
    _debug("Representation: " + _uri)
    var i: USize = 0
    (let scheme, i) = _parse_scheme(i)
    (let authority, let path, i) = _parse_hier_part(i)
    (let query, i) = _parse_query(i)
    (let fragment, i) = _parse_fragment(i)
    _debug("Out of '"+_uri+"' used by URI: '"+_substring(0, i)+"'")

    (scheme, authority, path, query, fragment, i)

  fun _parse_scheme(pos: USize): (String, USize)? =>
    _debug("Scheme from "+_uri.substring(pos.isize()))
    var i = pos

    if not _alpha(_at(i)) then error end // first char must be alpha
    
    while _exists(i) do
      match _at(i)
      | ':' => return (_substring(pos, i), i + 1)
      | let c: U8 if _alpha(c) or _digit(c) | '+' | '-' | '.' => i = i + 1
      else
        error // illegal char encountered
      end
    end

    error // colon has not been found

  fun _parse_hier_part(pos: USize): (OptionalAuthority, String, USize)? =>
    _debug("Hier part from "+_uri.substring(pos.isize()))
    var i = pos

    (let authority, i) = _parse_authority(i)
    (let path, i) = if not (authority is None) then
        _parse_path_abempty(i)
      else
        try _parse_path_absolute(i) else
          try _parse_path_rootless(i) else _parse_path_empty(i) end
        end
      end

    (authority, path, i)

  fun parse_relative_ref():
    (OptionalAuthority, String, OptionalQuery, OptionalFragment)?
  =>
    var i: USize = 0

    (let authority, let path, i) = _parse_relative_part(i)
    (let query, i) = _parse_query(i)
    (let fragment, i) = _parse_fragment(i)

    (authority, path, query, fragment)

  fun _parse_relative_part(pos: USize):
    (OptionalAuthority, String, USize)?
  =>
    var i: USize = pos

    (let authority, i) = _parse_authority(i)
    (let path, i) = if not (authority is None) then
        _parse_path_abempty(i)
      else
        try _parse_path_absolute(i) else
          try _parse_path_noscheme(i) else _parse_path_empty(i) end
        end
      end

    (authority, path, i)

  fun _parse_authority(pos: USize): (OptionalAuthority, USize)? =>
    _debug("Authority from "+_uri.substring(pos.isize()))
    var i = pos

    i = try _skip_literal("//", i) else return (None, pos) end
    _debug("Authority detected "+_uri.substring(i.isize()))

    (let user_info, i) = _parse_user_info(i)
    (let host, i) = _parse_host(i)
    (let port, i) = _parse_port(i)

    (Authority._create(host, user_info, port), i)

  fun _parse_user_info(pos: USize): (OptionalUserInfo, USize)? =>
    _debug("UserInfo from "+_uri.substring(pos.isize()))
    var i = pos

    var colon: (USize | None) = None
    while _exists(i) do
      let char = _at(i)

      if char == '@' then 
        let info = match colon
        | let c: USize =>
          UserInfo._create(_substring(pos, c), _substring(c + 1, i))
        | None =>
          UserInfo._create(_substring(pos, i), "")
        else
          _debug("Unexpected colon type")
          error // match is exhaustive so this should never happen
        end

        return (info, i + 1)
      end

      if (colon is None) and (char == ':') then colon = i end

      i = i + 1
    end

    (None, pos)

  fun _parse_host(pos: USize): (Host, USize)? =>
    _debug("Host from "+_uri.substring(pos.isize()))
    try return _parse_ip_literal(pos) end
    try return _parse_ip_v4(pos) end
    try return _parse_reg_name(pos) end
    error

  fun _parse_ip_literal(pos: USize): (IpLiteral, USize)? =>
    _debug("IP literal from "+_uri.substring(pos.isize()))
    var i = pos

    i = _skip_literal('[', i)

    match try _parse_ip_future(i) else _parse_ip_v6(i) end
    | (let ip: IpLiteral, let j: USize) => (ip, _skip_literal(']', j))
    else
      error // match is exhaustive. This should never happen.
    end

  fun _parse_ip_future(pos: USize): (IpFuture, USize)? =>
    _debug("IP future from "+_uri.substring(pos.isize()))
    var i = pos

    i = try _skip_literal("v", i) else _skip_literal("V", i) end
    
    (let version, i) = _parse_ip_future_version(i)
    i = _skip_literal(".", i)
    (let address, i) = _parse_ip_future_address(i)
    _debug("Extracted IP future address "+address.string())
    (IpFuture(version, address), i)

  fun _parse_ip_future_version(pos: USize): (String, USize)?
  =>
    _debug("IP future version from "+_uri.substring(pos.isize()))
    var i = pos

    while _exists(i) and _hex_digit(_at(i)) do
      i = i + 1
    else
      error
    end

    (_substring(pos, i), i)

  fun _parse_ip_future_address(pos: USize): (String, USize)?
  =>
    _debug("IP future address from "+_uri.substring(pos.isize()))
    var i = pos

    while
      _exists(i) and
      (_unreserved(_at(i)) or _sub_delim(_at(i)) or (_at(i) == ':'))
    do
      i = i + 1
    else
      error
    end

    (_substring(pos, i), i)

  fun _parse_ip_v6(pos: USize): (Ip6, USize)? =>
    var i = pos

    while _exists(i) do
      match _at(i)
      | let c: U8 if _hex_digit(c) | ':' | '.' => i = i + 1
      else
        break
      end
    end

    (Ip6.from(_substring(pos, i)), i)

  fun _parse_ip_v4(pos: USize): (Ip4, USize)? =>
    (let b1, let b2, let b3, let b4, let i) = _IpSyntax(_uri).parse_v4(pos)
    (Ip4(b1, b2, b3, b4), i)

  fun _parse_dec_octet(pos: USize): (U8, USize)? =>
    (let number, let i) = _parse_numeric(pos)
    (number.u8(10), i)

  fun _parse_reg_name(pos: USize): (String, USize)? =>
    _debug("Reg-name from "+_uri.substring(pos.isize()))
    var i = pos

    while
      _exists(i) and
      (_unreserved(_at(i)) or _sub_delim(_at(i)) or _pct_encoded_at(i))
    do
      i = i + 1
    end

    (_substring(pos, i), i)

  fun _parse_port(pos: USize): (OptionalPort, USize)? =>
    _debug("Port from "+_uri.substring(pos.isize()))
    var i = try _skip_literal(":", pos) else return (None, pos) end

    while _exists(i) and _digit(_at(i)) do
      i = i + 1
    else
      return (None, pos + 1)
    end

    let port = _substring(pos + 1, i).u16()
    (port, i)

  fun _parse_path_abempty(pos: USize): (String, USize) =>
    _debug("Path abempty from "+_substring(pos, _uri.size()))
    var i = pos

    i = _skip_multi_segments(i)

    (_substring(pos, i), i)

  fun _parse_path_absolute(pos: USize): (String, USize)? =>
    _debug("Path absolute from "+_substring(pos, _uri.size()))
    var i = pos

    i = _skip_literal('/', i)

    try
      i = _skip_segment_nz(i)
      i = _skip_multi_segments(i)
    end

    (_substring(pos, i), i)

  fun _parse_path_noscheme(pos: USize): (String, USize)? =>
    _debug("Path noscheme from "+_substring(pos, _uri.size()))
    var i = _skip_segment_nz_nc(pos)

    i = _skip_multi_segments(i)

    (_substring(pos, i), i)

  fun _parse_path_rootless(pos: USize): (String, USize)? =>
    _debug("Path rootless from "+_substring(pos, _uri.size()))
    var i = _skip_segment_nz(pos)

    i = _skip_multi_segments(i)

    (_substring(pos, i), i)

  fun _skip_multi_segments(pos: USize): USize =>
    var i = pos

    while _exists(i) do
      try
        i = _skip_literal('/', i)
        i = _skip_segment(i)
      else
        break
      end
    end

    i

  fun _parse_path_empty(pos: USize): (String, USize) => ("", pos)

  fun _parse_query(pos: USize): (OptionalQuery, USize)? =>
    var i = pos

    try i = _skip_literal('?', i) else return (None, pos) end

    while _exists(i) and
      (_pchar_at(i) or (_at(i) == '?') or (_at(i) == '/'))
    do
      i = i + 1
    end

    (_substring(pos + 1, i), i)

  fun _parse_fragment(pos: USize): (OptionalFragment, USize)? =>
    var i = pos

    try i = _skip_literal('#', i) else return (None, pos) end

    while _exists(i) and
      (_pchar_at(i) or (_at(i) == '?') or (_at(i) == '/'))
    do
      i = i + 1
    end

    (_substring(pos + 1, i), i)

  fun _parse_numeric(pos: USize): (String, USize)? =>
    var i = pos
    while _exists(i) and _digit(_at(i)) do i = i + 1 else error end
    (_substring(pos, i), i)
  
  fun _skip_literal(literal: (U8 | String), pos: USize): USize? =>
    match literal
    | let c: U8 if _at(pos) == c => pos + 1
    | let s: String if _uri.at(s, pos.isize()) => pos + s.size()
    else
      error
    end

  fun _skip_segment_nz(pos: USize): USize? =>
    let i = _skip_segment(pos)
    if i > pos then i else error end

  fun _skip_segment_nz_nc(pos: USize): USize? =>
    var i = pos
    while _exists(i) and _pchar_at(i) and (_at(i) != ':') do i = i + 1 end
    if i > pos then i else error end

  fun _skip_segment(pos: USize): USize? =>
    var i = pos
    while _exists(i) and _pchar_at(i) do i = i + 1 end
    i

  fun _pchar_at(pos: USize): Bool? =>
    match _at(pos)
    | let c: U8 if _unreserved(c) or _sub_delim(c) | ':' | '@' => true
    else
      _pct_encoded_at(pos)
    end

  fun _unreserved(char: U8): Bool =>
    match char
    | let c: U8 if _alpha(c) or _digit(c) | '-' | '.' | '_' | '~' => true
    else
      false
    end

  fun _sub_delim(char: U8): Bool =>
    match char
    | '!' | '$' | '&' | '\'' | '(' | ')' | '*' | '+' | ',' | ';' | '=' => true
    else
      false
    end

  fun _pct_encoded_at(pos: USize): Bool =>
    try
      _skip_literal("%", pos)
      _hex_digit(_at(pos + 1)) and _hex_digit(_at(pos + 2))
    else
      false
    end

  fun _alpha(char: U8): Bool =>
    _between('a', char, 'z') or _between('A', char, 'Z')

  fun _digit(char: U8): Bool =>
    _between('0', char, '9')

  fun _hex_digit(char: U8): Bool =>
    _between('0', char, '9') or _between('a', char, 'f')
    or _between('A', char, 'F')

  fun _between(first: U8, char: U8, last: U8): Bool =>
    (first <= char) and (char <= last)

  fun _substring(from: USize, to: USize): String =>
    _uri.substring(from.isize(), to.isize())

  fun _at(index: USize): U8? => _uri(index)

  fun _exists(i: USize): Bool => i <= _max_i

  fun _debug(s: String) =>
    """
    """
    Debug.out(s)
    // @fprintf[I32](@os_stdout[Pointer[U8]](), "%s\n".cstring(), s.cstring())
