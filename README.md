# Pong!

<p align="center">
  <img src="https://imgur.com/jsnouzZ.gif" alt="animated" width="758" height="480"/>
</p>

## Requeriments

First install these programs:

- [DOSBOX](https://www.dosbox.com/download.php?main=1)
- 8086 Assembler
- A text editor

## Run Procedure

Open DOSBOX

### Indicate where game folder is

```console
$ mount c [FOLDER PATH]
```

### Compile the assembly file

```console
$ masm /a pong.asm
```

### Link the file

```console
$ link pong
```

### Run the game

```console
$ pong
```

## Controls

- `W` `S` - player 1
- `O` `L` - player 2
- `space` - toggle pause
- `R` - restart game
- `E` - exit game/main menu
