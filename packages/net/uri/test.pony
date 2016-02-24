use "ponytest"
use "debug"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)
  new make() => None

  fun tag tests(test: PonyTest) =>
    test(_UriSchemeIsMandatory)
    test(_UriSchemeIsNeverEmpty)
    test(_UriSchemeStartsWithAlpha)
    test(_UriSchemeContainsAlphanumericPlusMinusDot)
    test(_UriAuthorityStartsWithDoubleSlash)
    test(_UriHostCanBeIpFuture)
    test(_UriHostCanBeIp6)
    test(_UriHostCanBeIp6WithZoneId)
    test(_UriHostCanBeIp4)
    test(_UriHostCanBeRegisteredName)
    test(_UriHostCanBeEmpty)
    test(_UriUserInfoCanBeSpecified)
    test(_UriUserCanBeEmpty)
    test(_UriPasswordCanBeOmitted)
    test(_UriPortCanBeSpecified)
    test(_UriPortIsIgnoredWhenEmpty)
    test(_UriPathCanBeEmpty)
    test(_UriPathAfterAuthorityStartsWithASlash)
    test(_UriPathAfterSchemeCanStartWithASegment)
    test(_UriPathAfterSchemeCanStartWithSlash)
    test(_UriPathIsTerminatedByQuestionmark)
    test(_UriPathIsTerminatedByNumberSign)
    test(_UriQueryIsOptional)
    test(_UriQueryCanBeEmpty)
    test(_UriQueryCanContainQuestionmark)
    test(_UriQueryCanContainSlash)
    test(_UriFragmentIsOptional)
    test(_UriFragmentCanBeEmpty)
    test(_UriFragmentCanContainQuestionmark)
    test(_UriFragmentCanContainSlash)
    test(_UriUsesEntireRepresentation)
    test(_UriConvertedToStringProducesInitialRepresentation)
    test(_UriConvertedToStringOmitsEmptyPassword)
    test(_UriConvertedToStringHidesPassword)
    test(_UriConvertedToUnsafeStringRevealsPassword)
    test(_UriConvertedToStringOmitsEmptyPort)
    test(_IPv6ConvertedToStringIsEqualToInitialString)
    test(_IPv6ConvertedToStringPresentsEveryBlock)


class iso _UriSchemeIsMandatory is UnitTest
  fun name(): String => "net/uri/Uri.scheme is mandatory"

  fun apply(h: TestHelper)=>
    h.assert_error(_ConstructorOf.uri(""), "Empty representation")

class iso _UriSchemeIsNeverEmpty is UnitTest
  fun name(): String => "net/uri/Uri.scheme is never empty"

  fun apply(h: TestHelper)=>
  h.assert_error(_ConstructorOf.uri(":"), "Scheme must be not empty")

class iso _UriSchemeStartsWithAlpha is UnitTest
  fun name(): String => "net/uri/Uri.scheme starts with alpha"

  fun apply(h: TestHelper)=>
  h.assert_error(_ConstructorOf.uri("-:"), "Starts with '-'")
  h.assert_error(_ConstructorOf.uri("+:"), "Starts with '+'")
  h.assert_error(_ConstructorOf.uri(".:"), "Starts with '.'")
  h.assert_error(_ConstructorOf.uri("5:"), "Starts with digit")
  h.assert_error(_ConstructorOf.uri("*:"), "Starts with invalid char")

class iso _UriSchemeContainsAlphanumericPlusMinusDot is UnitTest
  fun name(): String =>
    "net/uri/Uri.scheme contains only alphanumeric, -, + and ."

  fun apply(h: TestHelper) ? =>
    h.assert_error(_ConstructorOf.uri("invalid/char:"), "Invalid char")

    let uri = Uri("special-and+numbers.123:")
    h.assert_eq[String]("special-and+numbers.123", uri.scheme)

class iso _UriAuthorityStartsWithDoubleSlash is UnitTest
  fun name(): String => "net/uri/Uri.authority starts with double slash"

  fun apply(h: TestHelper) ? =>
    h.assert_true(Uri("scheme:").authority is None, "Empty path")
    h.assert_true(Uri("scheme:/").authority is None, "Absolute path")
    h.assert_true(Uri("scheme:letters").authority is None, "Rootless path")

    match Uri("scheme://host").authority
    | let a: Authority => true
    | None => h.fail("Empty authority")
    else
      h.fail("Unexpected authority type")
    end

class iso _UriHostCanBeIpFuture is UnitTest
  fun name(): String => "net/uri/Uri.authority.host can be IPvFuture"

  fun apply(h: TestHelper) ? =>
    let host = _Authority.host(Uri("scheme://[v1337.future-ip]"), h)
    try
      h.assert_eq[IpFuture](IpFuture("1337", "future-ip"), host as IpFuture)
    else
      _Authority.unexpected(host, h)
    end

class iso _UriHostCanBeIp6 is UnitTest
  fun name(): String => "net/uri/Uri.authority.host can be IPv6"

  fun apply(h: TestHelper) ? =>
    assert_eq(h, Ip6(0, 0, 0, 0, 0, 0, 0, 0), "[::]")
    assert_eq(h, Ip6(0, 0, 0, 0, 0, 0, 0, 1), "[::1]")
    assert_eq(h, Ip6(10, 0, 0, 0, 0, 0, 0, 11), "[A::b]")
    assert_eq(h, Ip6(10, 0, 0, 0, 0, 0, (1*256)+3, (3*256)+7), "[A::1.3.3.7]")

    h.assert_error(_ConstructorOf.uri("s://[:::]"), "Invalid compact")
    h.assert_error(_ConstructorOf.uri("s://[1:2:3:4:5:6:7:8:9]"), "9 blocks")
    h.assert_error(_ConstructorOf.uri("s://[1::1.3.3.7:1]"), "IPv4 not last")

  fun assert_eq(h: TestHelper, expected: Ip6, representation: String) ? =>
    let host = _Authority.host(Uri("s://" + representation), h)
    try
      h.assert_eq[Ip6](expected, host as Ip6)
    else
      _Authority.unexpected(host, h)
    end

class iso _UriHostCanBeIp6WithZoneId is UnitTest
  fun name(): String => "net/uri/Uri.authority.host can be IPv6 with Zone ID"

  fun apply(h: TestHelper) ? =>
    assert_eq(h, Ip6.with_zone_id(0, 0, 0, 0, 0, 0, 0, 0, "en1"), "[::%25en1]")

    h.assert_error(_ConstructorOf.uri("s://[:::]"), "Invalid compact")
    h.assert_error(_ConstructorOf.uri("s://[1:2:3:4:5:6:7:8:9]"), ">8 blocks")
    h.assert_error(_ConstructorOf.uri("s://[1::1.3.3.7:1]"), "IPv4 not last")

  fun assert_eq(h: TestHelper, expected: Ip6, representation: String) ? =>
    let host = _Authority.host(Uri("s://" + representation), h)
    try
      h.assert_eq[Ip6](expected, host as Ip6)
    else
      _Authority.unexpected(host, h)
    end

class iso _UriHostCanBeIp4 is UnitTest
  fun name(): String => "net/uri/Uri.authority.host can be IPv4"

  fun apply(h: TestHelper) ? =>
    let host = _Authority.host(Uri("scheme://1.2.3.4"), h)
    try
      h.assert_eq[Ip4](Ip4(1, 2, 3, 4), host as Ip4)
    else
      _Authority.unexpected(host, h)
    end

class iso _UriHostCanBeRegisteredName is UnitTest
  fun name(): String => "net/uri/Uri.authority.host can be registered name"

  fun apply(h: TestHelper) ? =>
    let host = _Authority.host(Uri("scheme://registered%20name"), h)
    try
      h.assert_eq[String]("registered%20name", host as String)
    else
      _Authority.unexpected(host, h)
    end
    
class iso _UriHostCanBeEmpty is UnitTest
  fun name(): String => "net/uri/Uri.authority.host can be empty"

  fun apply(h: TestHelper) ? =>
    let host = _Authority.host(Uri("scheme://"), h)
    try
      h.assert_eq[String]("", host as String)
    else
      _Authority.unexpected(host, h)
    end

class iso _UriUserInfoCanBeSpecified is UnitTest
  fun name(): String => "net/uri/Uri.authority.user_info can be specified"

  fun apply(h: TestHelper) ? =>
    let user_info = _Authority.user_info(Uri("scheme://user:password@"), h)
    
    h.assert_eq[String]("user", user_info.user)

    try
      h.assert_eq[String]("password", user_info.password as String)
    else
      h.fail("User info password is missing.")
    end

class iso _UriUserCanBeEmpty is UnitTest
  fun name(): String => "net/uri/Uri.authority.user_info.user can be empty"

  fun apply(h: TestHelper) ? =>
    let user_info = _Authority.user_info(Uri("scheme://:password@"), h)
    
    h.assert_eq[String]("", user_info.user)

class iso _UriPasswordCanBeOmitted is UnitTest
  fun name(): String =>
    "net/uri/Uri.authority.user_info.password can be omitted"

  fun apply(h: TestHelper) ? =>
    let user_info = _Authority.user_info(Uri("scheme://user@"), h)
    
    h.assert_eq[String]("", user_info.password)

class iso _UriPortCanBeSpecified is UnitTest
  fun name(): String => "net/uri/Uri.authority.port can be specified"

  fun apply(h: TestHelper) ? =>
    h.assert_eq[U16](1234, _Authority.port(Uri("scheme://host:1234"), h))
    h.assert_eq[U16](123, _Authority.port(Uri("scheme://host:0123"), h))

class iso _UriPortIsIgnoredWhenEmpty is UnitTest
  fun name(): String => "net/uri/Uri.authority.port is ignored when empty"

  fun apply(h: TestHelper) ? =>
    let actual_port = _Authority.of(Uri("scheme://host:"), h).port
    
    if actual_port isnt None then
      h.fail("Got port '" + actual_port.string() + "'.")
    end

class iso _UriPathCanBeEmpty is UnitTest
  fun name(): String => "net/uri/Uri.path can be empty"

  fun apply(h: TestHelper) ? =>
    h.assert_eq[String]("", Uri("s://host").path)
    h.assert_eq[String]("", Uri("s:").path)

class iso _UriPathAfterAuthorityStartsWithASlash is UnitTest
  fun name(): String =>
    "net/uri/Uri.path after authority starts with a '/'"

  fun apply(h: TestHelper) ? =>
    h.assert_eq[String]("/path", Uri("s://host/path").path)

class iso _UriPathAfterSchemeCanStartWithASegment is UnitTest
  fun name(): String =>
    "net/uri/Uri.path after scheme can start with a segment"

  fun apply(h: TestHelper) ? =>
    h.assert_eq[String]("segment", Uri("s:segment").path)

class iso _UriPathAfterSchemeCanStartWithSlash is UnitTest
  fun name(): String =>
    "net/uri/Uri.path after scheme can start with '/'"

  fun apply(h: TestHelper) ? =>
    h.assert_eq[String]("/segment", Uri("s:/segment").path)

class iso _UriPathIsTerminatedByQuestionmark is UnitTest
  fun name(): String =>
    "net/uri/Uri.path is terminated by '?'"

  fun apply(h: TestHelper) ? =>
    h.assert_eq[String]("segment", Uri("s:segment?query").path)

class iso _UriPathIsTerminatedByNumberSign is UnitTest
  fun name(): String =>
    "net/uri/Uri.path is terminated by '#'"

  fun apply(h: TestHelper) ? =>
    h.assert_eq[String]("segment", Uri("s:segment#fragment").path)

class iso _UriQueryIsOptional is UnitTest
  fun name(): String =>
    "net/uri/Uri.query is optional"

  fun apply(h: TestHelper) ? =>
    h.assert_is[OptionalQuery](None, Uri("s://host").query)
    h.assert_is[OptionalQuery](None, Uri("s://").query)

class iso _UriQueryCanBeEmpty is UnitTest
  fun name(): String =>
    "net/uri/Uri.query can be empty"

  fun apply(h: TestHelper) ? =>
    h.assert_eq[String]("", _Query.of(Uri("s://host?"), h))
    h.assert_eq[String]("", _Query.of(Uri("s://?"), h))

class iso _UriQueryCanContainQuestionmark is UnitTest
  fun name(): String =>
    "net/uri/Uri.query can contain questionmark"

  fun apply(h: TestHelper) ? =>
    h.assert_eq[String]("contains?", _Query.of(Uri("s://?contains?"), h))

class iso _UriQueryCanContainSlash is UnitTest
  fun name(): String =>
    "net/uri/Uri.query can contain slash"

  fun apply(h: TestHelper) ? =>
    h.assert_eq[String]("contains/", _Query.of(Uri("s://?contains/"), h))

class iso _UriFragmentIsOptional is UnitTest
  fun name(): String =>
    "net/uri/Uri.fragment is optional"

  fun apply(h: TestHelper) ? =>
    h.assert_is[OptionalFragment](None, Uri("s://host").fragment)
    h.assert_is[OptionalFragment](None, Uri("s://").fragment)

class iso _UriFragmentCanBeEmpty is UnitTest
  fun name(): String =>
    "net/uri/Uri.fragment can be empty"

  fun apply(h: TestHelper) ? =>
    h.assert_eq[String]("", _Fragment.of(Uri("s://host#"), h))
    h.assert_eq[String]("", _Fragment.of(Uri("s://#"), h))

class iso _UriFragmentCanContainQuestionmark is UnitTest
  fun name(): String =>
    "net/uri/Uri.fragment can contain questionmark"

  fun apply(h: TestHelper) ? =>
    h.assert_eq[String]("contains?", _Fragment.of(Uri("s://#contains?"), h))

class iso _UriFragmentCanContainSlash is UnitTest
  fun name(): String =>
    "net/uri/Uri.fragment can contain slash"

  fun apply(h: TestHelper) ? =>
    h.assert_eq[String]("contains/", _Fragment.of(Uri("s://#contains/"), h))

class iso _UriUsesEntireRepresentation is UnitTest
  fun name(): String =>
    "net/uri/Uri uses entire representation"

  fun apply(h: TestHelper) =>
    h.assert_error(_ConstructorOf.uri("s://host other text"), "other text")

class iso _UriConvertedToStringProducesInitialRepresentation is UnitTest
  fun name(): String =>
    "net/uri/Uri converted to string produces initial representation"

  fun apply(h: TestHelper) ? =>
    let representations = [
      "s:", "s:/", "s://",
      "s://host", "s://@host", "s://user@host", "s://host:42",
      "s://127.0.0.1", "s://[A::B]", "s://[v1337.address]",
      "s:/absolute", "s:non-absolute", "s:/multiple/segments",
      "s:?", "s:?query", "s:#", "s:#fragment", "s:?#",
      "s://user@host:42/path?query#fragment"
    ]
    for representation in representations.values() do
      h.assert_eq[String](representation, Uri(representation).string())
    end

class iso _UriConvertedToStringOmitsEmptyPassword is UnitTest
  fun name(): String =>
    "net/uri/Uri converted to string omits empty password"

  fun apply(h: TestHelper) ? =>
    h.assert_eq[String]("s://user@host", Uri("s://user:@host").string())

class iso _UriConvertedToStringHidesPassword is UnitTest
  fun name(): String =>
    "net/uri/Uri converted to string hides password"

  fun apply(h: TestHelper) ? =>
    h.assert_eq[String]("s://user:******@h", Uri("s://user:pass@h").string())

class iso _UriConvertedToUnsafeStringRevealsPassword is UnitTest
  fun name(): String =>
    "net/uri/Uri converted to unsafe string reveals password"

  fun apply(h: TestHelper) ? =>
    h.assert_eq[String]("s://u:pass@h", Uri("s://u:pass@h").string_unsafe())

class iso _UriConvertedToStringOmitsEmptyPort is UnitTest
  fun name(): String =>
    "net/uri/Uri converted to string omits empty port"

  fun apply(h: TestHelper) ? =>
    h.assert_eq[String]("s://host", Uri("s://host:").string())


primitive _ConstructorOf
  fun uri(rep: String): ITest => lambda()(rep)? => Uri(rep) end

primitive _Authority
  fun host(uri: Uri, h: TestHelper): Host? => of(uri, h).host

  fun unexpected(host': Host, h: TestHelper) =>
    match host'
    | let ip: Ip4 =>
      h.fail("Unexpectedly got IPv4 " + ip.string())
    | let ip: Ip6 =>
      h.fail("Unexpectedly got IPv6 " + ip.string())
    | let ip: IpFuture =>
      h.fail("Unexpectedly got IPvFuture " + ip.string())
    | let reg_name: String =>
      h.fail("Unexpectedly got registered name " + reg_name)
    else
      h.fail("Unexpected type of host " + host'.string())
    end

  fun user_info(uri: Uri, h: TestHelper): UserInfo? =>
    let authority = of(uri, h)
    try
      authority.user_info as UserInfo
    else
      h.fail("UserInfo does not exist")
      error
    end

  fun port(uri: Uri, h: TestHelper): U16? =>
    let authority = of(uri, h)
    try
      authority.port as U16
    else
      h.fail("Port does not exist")
      error
    end

  fun of(uri: Uri, h: TestHelper): Authority? =>
    try
      uri.authority as Authority
    else
      h.fail("Authority does not exist")
      error
    end

primitive _Query
  fun of(uri: Uri, h: TestHelper): String? =>
    try
      uri.query as String
    else
      h.fail("Query does not exist")
      error
    end

primitive _Fragment
  fun of(uri: Uri, h: TestHelper): String? =>
    try
      uri.fragment as String
    else
      h.fail("Fragment does not exist")
      error
    end

class iso _IPv6ConvertedToStringIsEqualToInitialString is UnitTest
  fun name(): String =>
    "net/uri/Ip6 converted to string is equal to initial string"

  fun apply(h: TestHelper) ? =>
    h.assert_eq[String]("A::B", Ip6.from("A::B").string())

class iso _IPv6ConvertedToStringPresentsEveryBlock is UnitTest
  fun name(): String =>
    "net/uri/Ip6 converted to string presents every block"

  fun apply(h: TestHelper) =>
    h.assert_eq[String]("A:0:0:0:0:0:0:B",
      Ip6(10, 0, 0, 0, 0, 0, 0, 11).string())
