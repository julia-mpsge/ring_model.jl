# The Ring Model: A City Surrounded by Fields

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://julia-mpsge.github.io/ring_model.jl/dev/)

## Using this Package

There are two ways to use and run this package:

### 1. Cloning the Repository

Clone the repository to your machine. Activate the package environment, you can do this by either starting a REPL, pressing `]` to enter the package manager, and then typing:

```julia
activate .
```

or in VSCode, you can use the command palette (Ctrl+Shift+P) and type "Julia: Change Current Environment" and select the directory where you cloned the repository.

After activating the environment, you need to instantiate the package to install all dependencies. You can do this by typing:

```julia
instantiate
```

in the package manager. 


### 2. As a Standalone Package

For this version, I recommend creating a new Julia environment. Create a new directory for your project, navigate to it in the terminal, start Julia, enter the package manager by pressing `]`, and then type:

```julia
activate .
```

Then, add the package by typing:

```julia
add https://github.com/julia-mpsge/ring_model.jl
```

You will also want both JuMP and MPSGE installed,

```julia
add JuMP, MPSGE
```


