defmodule FullyTest do
  use ExUnit.Case
  doctest Fully

  test "can parse a height response" do
    response = <<242, 242, 1, 3, 1, 26, 15, 46, 126, 242, 242, 1, 3, 1, 26, 15, 46, 126>>

    assert ExUnit.CaptureIO.capture_io(fn ->
             assert Fully.inspect_response(response) == <<242, 242, 1, 3, 1, 26, 15, 46, 126>>
           end) === """
           Height in inches: 28.2
           """
  end

  test "build move_1" do
    assert Fully.Command.build_command(:move_1, "") == <<241, 241, 5, 0, 5, 126>>
  end

  test "build move_3" do
    assert Fully.Command.build_command(:move_3, "") == <<241, 241, 39, 0, 39, 126>>
  end

  test "read move command" do
    assert ExUnit.CaptureIO.capture_io(fn ->
             assert Fully.inspect_message(<<241, 241, 39, 0, 39, 126>>) == ""
           end) == """
           address: <<241, 241>>
           command: 0x27
           command: :move_3
           length: 0
           params: ""
           checksum: 39
           rest: ""
           """
  end
end
