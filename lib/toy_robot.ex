defmodule ToyRobot do
  # max x-coordinate of table top
  @table_top_x 5
  # max y-coordinate of table top
  @table_top_y :e
  # mapping of y-coordinates
  @robot_map_y_atom_to_num %{:a => 1, :b => 2, :c => 3, :d => 4, :e => 5}

  @doc """
  Places the robot to the default position of (1, A, North)

  Examples:

      iex> ToyRobot.place
      {:ok, %ToyRobot.Position{facing: :north, x: 1, y: :a}}
  """
  def place do
    {:ok, %ToyRobot.Position{}}
  end

  def place(x, y, _facing) when x < 1 or y < :a or x > @table_top_x or y > @table_top_y do
    {:failure, "Invalid position"}
  end

  def place(_x, _y, facing)
  when facing not in [:north, :east, :south, :west]
  do
    {:failure, "Invalid facing direction"}
  end

  def place(x,y,facing) do
    {:ok, %ToyRobot.Position{x: x, y: y, facing: facing}}
  end

  @doc """
  Places the robot to the provided position of (x, y, facing),
  but prevents it to be placed outside of the table and facing invalid direction.

  Examples:

      iex> ToyRobot.place(1, :b, :south)
      {:ok, %ToyRobot.Position{facing: :south, x: 1, y: :b}}

      iex> ToyRobot.place(-1, :f, :north)
      {:failure, "Invalid position"}

      iex> ToyRobot.place(3, :c, :north_east)
      {:failure, "Invalid facing direction"}
  """
  def start() do
    {:ok, %ToyRobot.Position{x: 1, y: :a, facing: :north}}
  end
  def start(x, y, facing) when x < 1 or y < :a or x > @table_top_x or y > @table_top_y or facing not in [:north, :east, :south, :west] do
    {:failure, "Invalid START position"}
  end


  def start(x, y, facing) do
    {:ok, %ToyRobot.Position{x: x, y: y, facing: facing}}
  end



  def stop(_robot, goal_x, goal_y, _cli_proc_name) when goal_x < 1 or goal_y < :a or goal_x > @table_top_x or goal_y > @table_top_y do
    {:failure, "Invalid STOP position"}
  end
  
  def start() do
    {:ok, %ToyRobot.Position{x: 1, y: :a, facing: :facing}}
  end
  @doc """
  Provide STOP position to the robot as given location of (x, y) and plan the path from START to STOP.
  Passing the CLI Server process name that will be used to send robot's current status after each action is taken.
  """

    def change_facing(%ToyRobot.Position{x: _, y: _, facing: facing} = robot, facing_goal, cli_proc_name) do
    if facing == facing_goal do
    robot
    else
    %ToyRobot.Position{x: x,y: y,facing: facing} = right(robot)
    robot = %ToyRobot.Position{robot | x: x, y: y, facing: facing}
    send_robot_status(robot, cli_proc_name)
    change_facing(robot, facing_goal, cli_proc_name)
    end

    end

    def reach_horiz(%ToyRobot.Position{x: _, y: y, facing: _} = robot, goal_y, cli_proc_name) do
    if y == goal_y do
    robot
    else
    %ToyRobot.Position{x: x,y: y,facing: facing} = move(robot)
    robot = %ToyRobot.Position{robot | x: x, y: y, facing: facing}
    send_robot_status(robot, cli_proc_name)
    reach_horiz(robot, goal_y, cli_proc_name)
    end
    end

    def reach_vert(%ToyRobot.Position{x: x, y: _, facing: _} = robot, goal_x, cli_proc_name) do
    if x == goal_x do
    robot
    else
    %ToyRobot.Position{x: x,y: y,facing: facing} = move(robot)
    robot = %ToyRobot.Position{robot | x: x, y: y, facing: facing}
    send_robot_status(robot, cli_proc_name)
    reach_vert(robot, goal_x, cli_proc_name)
    end
    end


    def stop(robot, goal_x, goal_y, cli_proc_name) do
    send_robot_status(robot, cli_proc_name)
    if robot.y < goal_y  do
    robot = change_facing(robot, :north, cli_proc_name)
    robot = reach_horiz(robot, goal_y, cli_proc_name)
    if robot.x < goal_x  do
    robot = change_facing(robot, :east, cli_proc_name)
    robot = reach_vert(robot, goal_x, cli_proc_name)
    {:ok, robot}
    else
    robot = change_facing(robot, :west, cli_proc_name)
    robot = reach_vert(robot, goal_x, cli_proc_name)
    {:ok, robot}
    end
    else
    robot = change_facing(robot, :south, cli_proc_name)
    robot = reach_horiz(robot, goal_y, cli_proc_name)
    if robot.x < goal_x  do
    robot = change_facing(robot, :east, cli_proc_name)
    robot = reach_vert(robot, goal_x, cli_proc_name)
    {:ok, robot}
    else
    robot = change_facing(robot, :west, cli_proc_name)
    robot = reach_vert(robot, goal_x, cli_proc_name)
    {:ok, robot}
    end
    end

    end

  @doc """
  Send Toy Robot's current status i.e. location (x, y) and facing
  to the CLI Server process after each action is taken.
  """
  def send_robot_status(%ToyRobot.Position{x: x, y: y, facing: facing} = _robot, cli_proc_name) do
    send(cli_proc_name, {:toyrobot_status, x, y, facing})
    # IO.puts("Sent by Toy Robot Client: #{x}, #{y}, #{facing}")
  end

  @doc """
  Provides the report of the robot's current position

  Examples:

      iex> {:ok, robot} = ToyRobot.place(2, :b, :west)
      iex> ToyRobot.report(robot)
      {2, :b, :west}
  """
  def report(%ToyRobot.Position{x: x, y: y, facing: facing} = _robot) do
    {x, y, facing}
  end

  @directions_to_the_right %{north: :east, east: :south, south: :west, west: :north}
  @doc """
  Rotates the robot to the right.
  """
  def right(%ToyRobot.Position{facing: facing} = robot) do
    %ToyRobot.Position{robot | facing: @directions_to_the_right[facing]}
  end

  @directions_to_the_left Enum.map(@directions_to_the_right, fn {from, to} -> {to, from} end)
  @doc """
  Rotates the robot to the left.
  """
  def left(%ToyRobot.Position{facing: facing} = robot) do
    %ToyRobot.Position{robot | facing: @directions_to_the_left[facing]}
  end

  @doc """
  Moves the robot to the north, but prevents it to fall.
  """
  def move(%ToyRobot.Position{x: _, y: y, facing: :north} = robot) when y < @table_top_y do
    %ToyRobot.Position{robot | y: Enum.find(@robot_map_y_atom_to_num, fn {_, val} -> val == Map.get(@robot_map_y_atom_to_num, y) + 1 end) |> elem(0)}
  end

  @doc """
  Moves the robot to the east, but prevents it to fall.
  """
  def move(%ToyRobot.Position{x: x, y: _, facing: :east} = robot) when x < @table_top_x do
    %ToyRobot.Position{robot | x: x + 1}
  end

  @doc """
  Moves the robot to the south, but prevents it to fall.
  """
  def move(%ToyRobot.Position{x: _, y: y, facing: :south} = robot) when y > :a do
    %ToyRobot.Position{robot | y: Enum.find(@robot_map_y_atom_to_num, fn {_, val} -> val == Map.get(@robot_map_y_atom_to_num, y) - 1 end) |> elem(0)}
  end

  @doc """
  Moves the robot to the west, but prevents it to fall.
  """
  def move(%ToyRobot.Position{x: x, y: _, facing: :west} = robot) when x > 1 do
    %ToyRobot.Position{robot | x: x - 1}
  end

  @doc """
  Does not change the position of the robot.
  This function used as fallback if the robot cannot move outside the table.
  """
  def move(robot), do: robot

  def failure do
    raise "Connection has been lost"
  end
end
