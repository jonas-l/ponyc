use "collections"

class val _IpSyntax
  let _ip: String
  let _max_i: USize

  new val create(source: String) =>
    _ip = source
    _max_i = source.size() - 1

  fun parse_future(pos: USize): (String, String, USize)? =>
    var i = pos

    i = try _skip_literal("v", i) else _skip_literal("V", i) end
    
    (let version, i) = _parse_ip_future_version(i)
    i = _skip_literal(".", i)
    (let address, i) = _parse_ip_future_address(i)
    (version, address, i)

  fun _parse_ip_future_version(pos: USize): (String, USize)? =>
    var i = pos

    while _exists(i) and _hex_digit(_at(i)) do
      i = i + 1
    else
      error
    end

    (_substring(pos, i), i)

  fun _parse_ip_future_address(pos: USize): (String, USize)? =>
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

  fun parse_v6(pos: USize = 0):
    (U16, U16, U16, U16, U16, U16, U16, U16, USize)?
  =>
    var i = pos

    var zeros_at = try i = _skip_literal("::", i); USize(0) else None end
    
    var blocks: Array[U16] = recover Array[U16](8) end
    while _exists(i) do
      try
        i = _skip_literal(':', i)
        if not (zeros_at is None) then error end
        zeros_at = blocks.size()
        continue
      end
      
      if blocks.size() <= 6 then
        try
          (let b1, let b2, let b3, let b4, i) = parse_v4(i)
          blocks.push((b1.u16() << 8) + b2.u16())
          blocks.push((b3.u16() << 8) + b4.u16())
          break
        end
      end
      
      (let block, i) = try _parse_h16(i) else break end
      blocks.push(block)
      
      try i = _skip_literal(':', i) else break end
    end

    if (blocks.size() < 8) then
      let z = zeros_at as USize
      for r in Range(0, 8 - blocks.size()) do blocks.insert(z, 0) end
    end

    if blocks.size() != 8 then error end

    (blocks(0), blocks(1), blocks(2), blocks(3), blocks(4), blocks(5), blocks(6), blocks(7), i)
  
  fun _parse_h16(pos: USize): (U16, USize)? =>
    var i = pos

    var h16: U16 = 0
    while _exists(i) and _hex_digit(_at(i)) do
      if (i - pos) > 4 then error end
      h16 = (h16 << 4) + _hex_to_dec(_at(i)).u16()
      i = i + 1
    else
      error
    end

    (h16, i)

  fun _hex_to_dec(char: U8): U8? =>
    match char
    | let c: U8 if _digit(c) => c - '0'
    | let c: U8 if _between('a', c, 'f') => (c - 'a') + 10
    | let c: U8 if _between('A', c, 'F') => (c - 'A') + 10
    else
      error
    end

  fun parse_v4(pos: USize): (U8, U8, U8, U8, USize)? =>
    var i = pos

    (let b1, i) = _parse_dec_octet(i)
    i = _skip_literal(".", i)
    (let b2, i) = _parse_dec_octet(i)
    i = _skip_literal(".", i)
    (let b3, i) = _parse_dec_octet(i)
    i = _skip_literal(".", i)
    (let b4, i) = _parse_dec_octet(i)

    (b1, b2, b3, b4, i)

  fun _parse_dec_octet(pos: USize): (U8, USize)? =>
    (let number, let i) = _parse_numeric(pos)
    (number.u8(10), i)

  fun _parse_numeric(pos: USize): (String, USize)? =>
    var i = pos
    while _exists(i) and _digit(_at(i)) do i = i + 1 else error end
    (_substring(pos, i), i)

  fun _skip_literal(literal: (U8 | String), pos: USize): USize? =>
    match literal
    | let c: U8 if _at(pos) == c => pos + 1
    | let s: String if _ip.at(s, pos.isize()) => pos + s.size()
    else
      error
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

  fun _alpha(char: U8): Bool =>
    _between('a', char, 'z') or _between('A', char, 'Z')
    
  fun _hex_digit(char: U8): Bool =>
    _between('0', char, '9') or _between('a', char, 'f')
    or _between('A', char, 'F')

  fun _digit(char: U8): Bool =>
    _between('0', char, '9')

  fun _substring(from: USize, to: USize): String =>
    _ip.substring(from.isize(), to.isize())

  fun _at(index: USize): U8? => _ip(index)

  fun _exists(i: USize): Bool => i <= _max_i 

  fun _between(first: U8, char: U8, last: U8): Bool =>
    (first <= char) and (char <= last)
