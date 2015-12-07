use "debug"

class val Uri
  """
  Represents a Uniform Resource Identifier (URI) as defined in [RFC3986][1].

  The class validates given representation and extracts the following components: scheme, authority, path, query, and fragment. RFC3986 gives the following example to show [corresponding components of both URL and URN][2]:

         foo://example.com:8042/over/there?name=ferret#nose
         \_/   \______________/\_________/ \_________/ \__/
          |           |            |            |        |
       scheme     authority       path        query   fragment
          |   _____________________|__
         / \ /                        \
         urn:example:animal:ferret:nose

  [1]: https://tools.ietf.org/html/rfc3986
  [2]: https://tools.ietf.org/html/rfc3986#section-3
  """
  let scheme: String
  let authority: OptionalAuthority
  let path: String
  let query: OptionalQuery
  let fragment: OptionalFragment

  new val create(representation: String)? =>
    (scheme, authority, path, query, fragment, let i) =
      _UriSyntax(representation).parse_uri()

    let entire_rep_used = i == representation.size()
    if not entire_rep_used then error end

  fun string(fmt: FormatSettings = FormatSettingsDefault): String iso^ =>
    let s = recover String end

    s.append(scheme); s.append(":")
    try s.append("//" + (authority as Authority).string()) end
    s.append(path)
    try s.append("?" + (query as String)) end
    try s.append("#" + (fragment as String)) end

    consume s

type OptionalAuthority is (Authority | None)

class val Authority
  let user_info: OptionalUserInfo
  let host: Host
  let port: OptionalPort

  new val _create(host': Host, user_info': OptionalUserInfo = None,
    port': OptionalPort = None)
  =>
    host = host'
    user_info = user_info'
    port = port'

  fun string(fmt: FormatSettings = FormatSettingsDefault): String iso^ =>
    let s = recover String end

    try s.append((user_info as UserInfo).string() + "@") end

    match host
    | let h: IpLiteral => s.append("[" + h.string() + "]")
    else
      s.append(host.string())
    end

    try s.append(":" + (port as U16).string()) end

    consume s

type OptionalUserInfo is (UserInfo | None)
type OptionalPort is (U16 | None)

class val UserInfo
  let user: String
  let password: String

  new val _create(user': String, password': String) =>
    user = user'
    password = password'

  fun string(fmt: FormatSettings = FormatSettingsDefault): String iso^ =>
    let s = recover String end

    s.append(user)
    if password.size() > 0 then s.append(":******") end

    consume s

type Host is (IpLiteral | Ip4 | String)
type IpLiteral is (IpFuture | Ip6)

class val Ip4 is (Stringable & Equatable[Ip4])
  let b1: U8
  let b2: U8
  let b3: U8
  let b4: U8

  new val create(b1': U8, b2': U8, b3': U8, b4': U8) =>
    b1 = b1'; b2 = b2'; b3 = b3'; b4 = b4'

  fun eq(that: Ip4 box): Bool =>
    (b1 == that.b1) and (b2 == that.b2) and (b3 == that.b3) and (b4 == that.b4)

  fun string(fmt: FormatSettings = FormatSettingsDefault): String iso^ =>
    ".".join([as Stringable: b1, b2, b3, b4])

class val IpFuture is (Stringable & Equatable[IpFuture])
  let version: String
  let address: String

  new val create(version': String, address': String) =>
    version = version'
    address = address'

  fun eq(that: IpFuture box): Bool =>
    (version == that.version) and (address == that.address)

  fun string(fmt: FormatSettings = FormatSettingsDefault): String iso^ =>
    ("v" + version + "." + address).string(fmt)

class val Ip6 is (Stringable & Equatable[Ip6])
  let b1: U16
  let b2: U16
  let b3: U16
  let b4: U16
  let b5: U16
  let b6: U16
  let b7: U16
  let b8: U16
  let _string: String

  new val create(b1': U16, b2': U16, b3': U16, b4': U16, b5': U16, b6': U16,
    b7': U16, b8': U16)
  =>
    b1 = b1'; b2 = b2'; b3 = b3'; b4 = b4'
    b5 = b5'; b6 = b6'; b7 = b7'; b8 = b8'

    let fmt = FormatSettingsInt.set_format(FormatHexBare)

    _string = ":".join([as Stringable:
      b1.string(fmt), b2.string(fmt), b3.string(fmt), b4.string(fmt),
      b5.string(fmt), b6.string(fmt), b7.string(fmt), b8.string(fmt)
    ])

  new val from(representation: String) ? =>
    _string = representation

    (b1, b2, b3, b4, b5, b6, b7, b8, let i)
      = _IpSyntax(representation).parse_v6()

    let entire_rep_used = i == representation.size()
    if not entire_rep_used then error end

  fun eq(that: Ip6): Bool =>
    (b1 == that.b1) and (b2 == that.b2) and (b3 == that.b3) and
    (b4 == that.b4) and (b5 == that.b5) and (b6 == that.b6) and
    (b7 == that.b7) and (b8 == that.b8)

  fun string(fmt: FormatSettings = FormatSettingsDefault): String iso^ =>
    _string.clone()

type OptionalQuery is (String | None)

type OptionalFragment is (String | None)
