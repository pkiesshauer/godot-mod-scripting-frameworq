# ModScript -- Lightweight Modding Language for Godot

ModScript is a lightweight scripting language for Godot designed for
safe and simple modding support.

It provides a small interpreted language that runs on top of Godot using
a controlled API. Modders can write scripts without accessing the full
engine or game code.

## Features

-   Custom scripting language
-   Safe execution through ModAPI
-   Local variable scopes
-   Functions and parameters
-   Optional parameters with defaults
-   If / Else control flow
-   While loops
-   Expression evaluation via Godot Expression
-   Async execution support
-   Plugin-based architecture

## Example Script

    func update(dt, threshold = 0.1)

        if dt > threshold
            send_display_signal("Slow frame")
        end if

    end func

## Example Function Call

    call update(dt = 0.016)

## Architecture

Script → Compiler → Program → Interpreter → ModAPI

### Compiler

The Compiler converts script text into an executable Program.

Responsibilities:

-   Parse functions
-   Parse instructions
-   Resolve control flow
-   Validate syntax

### Interpreter

The Interpreter executes compiled Programs.

Responsibilities:

-   Execute instructions
-   Maintain local variable contexts
-   Evaluate expressions
-   Handle control flow
-   Support async execution

The Interpreter does not depend on the SceneTree.

### ModAPI

The ModAPI exposes safe functionality to scripts.

Example:

``` gdscript
extends ModAPI
class_name ExampleModAPI

signal display(text: String)

func send_display_signal(text: String):
    display.emit(text)
    return null

func wait(seconds: float):
    await get_tree().create_timer(seconds).timeout
    return null
```

## Using ModScript

### Compile Script

``` gdscript
var script = FileAccess.get_file_as_string("res://script.txt")
var program = Compiler.compile(script)

if program.error:
    print(program.error_message)
    return
```

### Run Script

``` gdscript
var interpreter = Interpreter.new()

interpreter.setup(program, ExampleModAPI.new())

await interpreter.run_function("update")
```

## Functions

Functions are defined as:

    func name(parameters)

    end func

Example:

    func move(x, y)

    end func

## Parameters

Functions support named parameters:

    call move(x = 3, y = 4)

## Optional Parameters

Functions can define defaults:

    func spawn_enemy(type, hp = 100)

    end func

Example call:

    call spawn_enemy(type = "orc")

## Variables

Variables are dynamically typed.

    x = 5
    y = x + 3

Variables are local to each function call.

## Control Flow

### If / Else

    if x > 5

        send_display_signal("Large")

    else

        send_display_signal("Small")

    end if

### While

    while x < 10

        x = x + 1

    end while

## Async Execution

Scripts can run asynchronously.

    wait(1)
    send_display_signal("Done")

The wait() function is implemented in ModAPI.

Scripts do not block the game.

## Installation

Copy the addon folder into your project:

    addons/modscript/

Enable plugin:

Project → Project Settings → Plugins

## Demo

Full demo project available in:

    demo_project/

## License

MIT License
