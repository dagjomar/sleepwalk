# disablesleep

Keep a Mac awake, lid closed included, for a set amount of time. When the time
is up, sleep turns back on by itself.

```bash
disablesleep 2h       # awake for 2 hours
disablesleep status   # is sleep off, and how long is left?
disablesleep off      # turn sleep back on now
```

## Why

`caffeinate` doesn't help once you close the lid. The usual fix is
`sudo pmset -a disablesleep 1`, and the catch is that it stays on until you
turn it off, even across reboots. If you forget, your MacBook can sit in a bag
running hot until the battery is empty.

`disablesleep` puts a time limit on it:

- **A duration is required and capped.** It takes `Nm`, `Nh` or `NhNm`
  (`45m`, `2h`, `1h30m`), from 1 minute to 5 hours. Anything else is rejected.
- **The timer runs on its own.** A root background process turns sleep back
  on when time is up. Closing the terminal doesn't stop it.
- **Running it again resets the timer.** `disablesleep 2h` while a timer is
  running replaces that timer instead of adding a second one.
- **It warns you when the timer is gone.** If the Mac reboots or crashes before
  the timer fires, sleep stays off. `disablesleep check` in your shell rc
  catches that and prints a red warning in every new terminal.

## Install

```bash
git clone <this repo> ~/code/disablesleep
mkdir -p ~/.local/bin
ln -s ~/code/disablesleep/disablesleep ~/.local/bin/disablesleep
```

Any directory on your `PATH` works. If `~/.local/bin` isn't on yours, add
`export PATH="$HOME/.local/bin:$PATH"` to your shell rc. `/usr/local/bin` is
root-owned on newer Macs, so linking there needs `sudo`. Then add the
warning check to `~/.zshrc` or `~/.bashrc`:

```bash
command -v disablesleep >/dev/null && disablesleep check
```

## Commands

| Command | What it does |
| --- | --- |
| `disablesleep <duration>` | Turns sleep off and starts the timer. Asks for your password. |
| `disablesleep off` | Cancels the timer and turns sleep back on. |
| `disablesleep status` | Shows whether sleep is off and when it comes back on. |
| `disablesleep check` | Prints a warning if sleep is off with no timer running. Silent otherwise. |

## Notes

- macOS only. It uses `pmset`, which needs `sudo`.
- The timer's state lives in `/tmp/disablesleep.state`. macOS clears `/tmp` at
  boot, which is how `check` knows the timer didn't survive a reboot.
- On battery with the lid closed, the Mac stays awake until the timer ends or
  the battery runs out.
