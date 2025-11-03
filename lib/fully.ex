defmodule Fully do
  @controller_address 0xF1
  @desk_address 0xF2
  @eom 0x7E

  @command_name_to_integer %{
    :raise => 0x1,
    :lower => 0x2,
    :progmem_1 => 0x3,
    :progmem_2 => 0x4,
    # Move desk to memory position 1
    :move_1 => 0x5,
    # Move desk to memory position 2
    :move_2 => 0x6,
    :settings => 0x7,
    :unknown_08 => 0x08,
    :unknown_09 => 0x09,
    :unknown_0C => 0x0C,
    # Set units to cm/inches
    :units => 0xE,
    :mem_mode => 0x19,
    :unknown_1c => 0x1C,
    # Set anti-collision sensitivity
    :coll_sens => 0x1D,
    :unknown_1f => 0x1F,
    :limits => 0x20,
    :set_max => 0x21,
    :set_min => 0x22,
    # clear min/max height
    :limit_clr => 0x23,
    # Set memory position 3 to current height
    :progmem_3 => 0x25,
    # Set memory position 4 to current height
    :progmem_4 => 0x26,
    # Move desk to memory position 3
    :move_3 => 0x27,
    # Move desk to memory position 4
    :move_4 => 0x28,
    :wake => 0x29,
    :calibrate => 0x91
  }

  @integer_to_command_name Map.new(@command_name_to_integer, fn {k, v} -> {v, k} end)

  defmodule Command do
    @controller_address 0xF1

    @doc """
    Find the checksum for the message

    CHECKSUM = sum(COMMAND, LENGTH, PARAMS) % 0xFF
    """
    def checksum(command, params) when is_binary(params) do
      Enum.sum([command, byte_size(params) | :binary.bin_to_list(params)])
      |> rem(0xFF)
    end

    def command_name_to_bytes(command_name) do
      Map.get(Fully.command_name_to_integer(), command_name)
    end

    # TODO: support building params in a non-raw way
    def build_command(command_name, params) when is_binary(params) do
      command_bytes = command_name_to_bytes(command_name)

      <<
        @controller_address,
        @controller_address,
        command_bytes,
        byte_size(params),
        params::binary,
        checksum(command_bytes, params),
        0x7E
      >>
    end
  end

  def command_name_to_integer, do: @command_name_to_integer

  def connect_uart do
    verify_uart_enumeration()

    {:ok, pid} = Circuits.UART.start_link()
    Circuits.UART.open(pid, "ttyAMA0", speed: 9600, active: false)

    pid
  end

  def read(pid) do
    case raw_read(pid) do
      {:ok, ""} -> :nothing_to_read
      {:ok, bytes} -> inspect_message(bytes)
      error -> IO.puts("Unable to read due to error: #{inspect(error)}")
    end
  end

  def raw_read(pid, timeout \\ 10_000) do
    Circuits.UART.read(pid, timeout)
  end

  def raise(pid) do
    message = Command.build_command(:raise, "")
    send_command(pid, message)
  end

  def lower(pid) do
    message = Command.build_command(:lower, "")
    send_command(pid, message)
  end

  def move_to_position(pid, position) when position in [:pos1, :pos2, :pos3, :pos4] do
    command_name =
      case position do
        :pos1 -> :move_1
        :pos2 -> :move_2
        :pos3 -> :move_3
        :pos4 -> :move_4
      end

    message = Command.build_command(command_name, "")
    send_command(pid, message)
  end

  def send_command(pid, message) when is_binary(message) do
    Circuits.UART.write(pid, message)
  end

  def build_command(:raise) do
    <<
      @controller_address,
      @controller_address,
      01::8,
      0,
      1::8
    >>
  end

  def inspect_bit_list(<<a::1, b::1, c::1, d::1, e::1, f::1, g::1, h::1, rest::binary>>) do
    pretty_bits = "#{a}#{b}#{c}#{d} #{e}#{f}#{g}#{h}"

    case rest do
      "" -> pretty_bits
      _ -> "#{pretty_bits} #{inspect_bit_list(rest)}"
    end
  end

  def verify_uart_enumeration do
    case Circuits.UART.enumerate() do
      %{"ttyAMA0" => map} when map == %{} -> :ok
    end
  end

  def inspect_message(<<
        address::2-bytes,
        command::integer,
        length::8,
        params::binary-size(length),
        checksum::8,
        @eom,
        rest::binary
      >>) do
    IO.inspect(address, label: "address")
    IO.inspect(command, label: "command", base: :hex)
    IO.puts("command: #{inspect(Map.get(@integer_to_command_name, command))}")
    IO.inspect(length, label: "length")
    IO.inspect(params, label: "params")
    IO.inspect(checksum, label: "checksum")
    # IO.inspect(eom, label: "eom")
    IO.inspect(rest, label: "rest")
    rest
  end

  # NOTE: only one of the responses is implemented right now
  def inspect_response(
        <<@desk_address, @desk_address, 1, 3, height::integer-size(16), _unknown, _checksum, @eom,
          rest::binary>>
      ) do
    # NOTE: Assuming that we're set in inches
    height = height / 10
    IO.puts("Height in inches: #{height}")
    rest
  end
end
