defmodule Ophion.IRCv3.Parser.Test do
  use ExUnit.Case

  alias Ophion.IRCv3.Message
  alias Ophion.IRCv3.Parser

  describe "basic -" do
    test "it parses valid RFC1459 frames correctly" do
      message = ":kaniini!~kaniini@localhost JOIN #foo"

      {:ok, %Message{} = msg} = Parser.parse(message)

      assert msg.source == "kaniini!~kaniini@localhost"
      assert msg.verb == "JOIN"
      assert msg.params == ["#foo"]
    end

    test "it parses RFC1459 messages without a source" do
      message = "PASS foo TS 6 003"

      {:ok, %Message{} = msg} = Parser.parse(message)

      assert msg.source == nil
      assert msg.verb == "PASS"
      assert msg.params == ["foo", "TS", "6", "003"]
    end

    test "it parses multi-word messages correctly" do
      message = "PRIVMSG #bar :hi there :lol"

      {:ok, %Message{} = msg} = Parser.parse(message)

      assert msg.source == nil
      assert msg.verb == "PRIVMSG"
      assert msg.params == ["#bar", "hi there :lol"]
    end

    test "it parses RFC1459 messages with only a verb" do
      message = "INFO"

      {:ok, %Message{} = msg} = Parser.parse(message)

      assert msg.source == nil
      assert msg.verb == "INFO"
      assert msg.params == []
    end

    test "it parses source-less messages with a compound parameter" do
      message = "PING :eshmaki.me"

      {:ok, %Message{} = msg} = Parser.parse(message)

      assert msg.source == nil
      assert msg.verb == "PING"
      assert msg.params == ["eshmaki.me"]
    end
  end

  describe "message tags -" do
    test "it parses basic message tags correctly" do
      message = "@ophion.dev/test :kaniini!~kaniini@localhost PRIVMSG #foo :bar"

      {:ok, %Message{} = msg} = Parser.parse(message)

      assert msg.tags == %{"ophion.dev/test" => nil}
      assert msg.source == "kaniini!~kaniini@localhost"
      assert msg.verb == "PRIVMSG"
      assert msg.params == ["#foo", "bar"]
    end

    test "it parses basic message tags correctly without a source" do
      message = "@ophion.dev/test PRIVMSG #foo :bar"

      {:ok, %Message{} = msg} = Parser.parse(message)

      assert msg.tags == %{"ophion.dev/test" => nil}
      assert msg.verb == "PRIVMSG"
      assert msg.params == ["#foo", "bar"]
    end

    test "it parses multiple tags correctly" do
      message = "@ophion.dev/a;ophion.dev/b PRIVMSG #foo :bar"

      {:ok, %Message{} = msg} = Parser.parse(message)

      assert msg.tags == %{"ophion.dev/a" => nil, "ophion.dev/b" => nil}
      assert msg.verb == "PRIVMSG"
      assert msg.params == ["#foo", "bar"]
    end

    test "it parses tags with values correctly" do
      message = "@ophion.dev/a=123;ophion.dev/b PRIVMSG #foo :bar"

      {:ok, %Message{} = msg} = Parser.parse(message)

      assert msg.tags == %{"ophion.dev/a" => "123", "ophion.dev/b" => nil}
      assert msg.verb == "PRIVMSG"
      assert msg.params == ["#foo", "bar"]
    end

    test "it properly unescapes semicolons" do
      message = "@ophion.dev/a=haha\\:;ophion.dev/b PRIVMSG #foo :bar"

      {:ok, %Message{} = msg} = Parser.parse(message)

      assert msg.tags == %{"ophion.dev/a" => "haha;", "ophion.dev/b" => nil}
      assert msg.verb == "PRIVMSG"
      assert msg.params == ["#foo", "bar"]
    end

    test "it properly unescapes backslashes" do
      message = "@ophion.dev/a=haha\\\\;ophion.dev/b PRIVMSG #foo :bar"

      {:ok, %Message{} = msg} = Parser.parse(message)

      assert msg.tags == %{"ophion.dev/a" => "haha\\", "ophion.dev/b" => nil}
      assert msg.verb == "PRIVMSG"
      assert msg.params == ["#foo", "bar"]
    end

    test "it properly unescapes spaces" do
      message = "@ophion.dev/a=foo\\sbar;ophion.dev/b PRIVMSG #foo :bar"

      {:ok, %Message{} = msg} = Parser.parse(message)

      assert msg.tags == %{"ophion.dev/a" => "foo bar", "ophion.dev/b" => nil}
      assert msg.verb == "PRIVMSG"
      assert msg.params == ["#foo", "bar"]
    end

    test "it properly unescapes CR-LF sequences" do
      message = "@ophion.dev/a=foo\\r\\nbar;ophion.dev/b PRIVMSG #foo :bar"

      {:ok, %Message{} = msg} = Parser.parse(message)

      assert msg.tags == %{"ophion.dev/a" => "foo\r\nbar", "ophion.dev/b" => nil}
      assert msg.verb == "PRIVMSG"
      assert msg.params == ["#foo", "bar"]
    end

    test "it handles IRCv3 TAGMSG" do
      message = "@ophion.dev/foo TAGMSG"

      {:ok, %Message{} = msg} = Parser.parse(message)

      assert msg.tags == %{"ophion.dev/foo" => nil}
      assert msg.verb == "TAGMSG"
    end
  end

  describe "invalid messages -" do
    test "it rejects messages with only tags" do
      message = "@ophion.dev/a"

      {:error, :invalid_message} = Parser.parse(message)

      message = "@ophion.dev/a "

      {:error, :invalid_message} = Parser.parse(message)
    end

    test "it rejects empty messages" do
      {:error, :invalid_message} = Parser.parse("")
    end

    test "it rejects nil as message" do
      {:error, :invalid_message} = Parser.parse(nil)
    end
  end
end
