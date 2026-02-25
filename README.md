# Mod Scripting FrameworQ -- Lightweight Modding System for Godot

Mod Scripting FrameworQ is a lightweight scripting system for Godot designed for
safe and simple modding support.

It provides a small interpreted language that runs on top of Godot using
a controlled API. Modders can write scripts without accessing the full
engine or game code.

## Features

-   Custom scripting language
-   Safe execution through ModAPI
-   Local variable scopes
-   Control flow (if/else, while)
-   Expression evaluation via Godot Expression

## Example Script

    func test
        send_display_signal("Hallo Welt!")
    end func

## Architecture

Script → Compiler → Program → Interpreter

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

### ModAPI

The ModAPI exposes safe functionality to scripts.

Extend ModAPI to define your own api-methods that scripts can access.
Scripts are dynamically typed, so make sure to type check.
Game constants can be added to the ModAPI.context, so all script-functions can access them.

Example:

``` gdscript
extends ModAPI
class_name ExampleModAPI

signal display(text: String)

func send_display_signal(text: String) -> void:
    display.emit(text)
```

## Using ModScript

### Compile Script

``` gdscript
var script = FileAccess.get_file_as_string("res://script.txt")
var program = Compiler.compile(script)

if program.error != OK:
    print(program.error_message)
    return
```

### Run Script

``` gdscript
var interpreter = Interpreter.new()

interpreter.setup(program, ExampleModAPI.new())

await interpreter.run_function("test")
```

## Functions

Functions are defined as:

    func name

    end func

Example:

    func move

    end func

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
