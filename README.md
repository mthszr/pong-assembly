# Pong!

<p align="center">
  <img src="https://imgur.com/jsnouzZ.gif" alt="animated" width="758" height="480"/>
</p>

## Requeriments

First install these programs:

- [DOSbox](https://www.dosbox.com/download.php?main=1)
- 8086 Assembler
- A text editor

## Run Procedure

Download this repo, extract it and paste all the all files in your newly created folder. The assembler is already included 

### Open DOSbox .conf file and write the code at bottom for automatic mount on every launch.

```text
$ mount c c:\[FOLDER PATH]
c:
```

Open DOSbox and type:

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
