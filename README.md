# Katas

See katas from here https://kata-log.rocks

This repository is a small workspace for practicing coding katas in C#.

It gives you two things:

1. A reusable kata template under `templates/`
2. Scripts that create a fresh kata under `katas/` with the right folder names, solution names, project names, and namespaces

The goal is to make starting a new kata fast and repeatable so you can spend your time solving the problem instead of setting up files by hand.

## Repository Layout

The repository is organized into two main folders:

- `templates/` contains reusable starter templates
- `katas/` contains the actual katas you create and work on

Right now, the main template is `templates/csharp-kata`.

At the repository root you will also find two helper scripts:

- `new-kata.ps1` for PowerShell
- `new-kata.sh` for `sh`-compatible shells

Both scripts create a new kata from the same template and apply the same naming rules.

## Create a New Kata

You can create a new kata in either interactive or non-interactive mode.

### PowerShell

Interactive:

```powershell
.\new-kata.ps1
```

Non-interactive:

```powershell
.\new-kata.ps1 -Name "Bowling Game" -Description "# Bowling Game"
```

### Shell

Interactive:

```sh
sh ./new-kata.sh
```

Non-interactive:

```sh
sh ./new-kata.sh "Bowling Game" "# Bowling Game"
```

After the script runs, a new kata will be created under `katas/<slug>`.

For example, `Bowling Game` becomes:

- folder: `katas/bowling-game`
- solution: `BowlingGame.slnx`
- main project: `BowlingGame`
- test project: `BowlingGame.Tests`

## Work On a Kata

Once a kata has been created:

1. Open the generated folder under `katas/`
2. Open the solution in your editor or IDE
3. Run the tests
4. Start solving the kata

Example:

```powershell
Set-Location .\katas\bowling-game
dotnet test .\BowlingGame.slnx
```

Or, if you prefer continuous test runs:

```powershell
dotnet watch test
```

Each generated kata is self-contained, so you can work on one without affecting the others.

## Naming and Validation Rules

The scripts apply a small set of predictable rules:

- Kata names may contain only letters, numbers, spaces, and hyphens
- The generated folder name uses a lowercase slug
- The generated .NET solution, project, and namespace names use PascalCase
- If the destination folder already exists, the script stops and makes no changes
- `bin/` and `obj/` folders from the template are not copied into new katas

Examples:

- `Prime Factors` becomes `katas/prime-factors` and `PrimeFactors`
- `String Calculator` becomes `katas/string-calculator` and `StringCalculator`

## README Behavior

When you create a kata, the README behaves in one of two ways:

- If you provide a description, it replaces the full generated `README.md`
- If you leave the description empty, the template `README.md` is kept as-is

This makes it easy to either:

- start quickly with the default template instructions, or
- drop in your own kata prompt immediately

## Template Notes

The current C# template is intentionally small. It gives you:

- a solution file
- a main class library project
- a test project using xUnit
- a placeholder class and test

That keeps the setup lightweight while still giving you a clean red-green workflow from the start.
