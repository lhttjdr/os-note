# 1 启动

## 启动扇区

传统上，磁盘HDD扇区大小为512B，CD-ROM和DVD-ROM为2K。现代磁盘的规范是4K。

第一个扇区的末尾处两个字节是`0xAA55`，表示一个启动扇区。BIOS程序检测到之后，会将扇区的数据装载到内存`0x7c00`处。然后开始执行。

因此，启动扇区的数据布局大致是：先是程序数据，然后填充任意数据凑齐510字节，最后2字节是签名`0xAA55`。当然，程序数据分成多段，中间夹杂无用的填充部分也可以。

## Hello World!

制作一张启动盘，在裸机的屏幕上打印出`Hello World!`。这里假定是x86的CPU。

对于x86系统，可以使用BIOS中断**INT 10h**来打印字符串到屏幕。

> INT 10H，第17号中断向量
>
> 功能号AH = 13H，写字符串。
> 
> 参数:
> - `AL`： 写模式，取值范围0~3。
>   - bit 0：写字符串后，更新光标位置到字符串后第一个位置。
>   - bit 1：字符串含有BIOS颜色属性，即对每个字符指定属性。字符串=字符，属性，字符，属性……（参见`BL`参数的介绍）
> - `BH`：页号
> - `BL`： 8bit BIOS颜色属性。bit7表示是否闪烁，bit6~4表示背景色, bit3~0表示前景色。显然，只有8种背景色，16种前景色。当然，也可以通过设置禁用闪烁功能，支持16种背景色。`BL`仅当`AL`的bit1=0时有效。
> - `CX`：字符串长度
> - `DH`, `DL`：写字符串的起始位置——行、列。（显然最多只有256行、列）
> - `ES:BP`：字符串的地址

```asm
; boot.asm: print "Hello World!" on screen

	org 07c00h   ; "0x7C00" is the memory address which BIOS loads 
	             ; MBR(Master Boot Record, a first sector in hdd/fdd) into.
	mov ax, cs
	mov es, ax          ; set es
	mov ax, Message
	mov bp, ax          ; set bp, es:bp = Hello World!
	mov cx, Fill - Message  ; length
	mov ah, 13h         ; function : write string
	mov al, 01h         ; write mode
	mov bh, 0           ; page number
	mov bl, 0ah         ; background color=black, foreground color=light green
	mov dh,	0           ; row 0
	mov dl, 0           ; column 0
	int 10h             ; BIOS interrupt call
	jmp $               ; jump to current address (= infinite loop)
Message:    db "Hello, World!"       ; string data
Fill:       times 510-($-$$)  db 0   ; first sector (512 bytes) 
                                     ; |program data| ....any data ...|0xaa, 0x55|
                                     ;0         ($-$$)             509 510   511 512
                                     ; $$ is the address of the beginning of the current section
            dw 0xaa55      ; boot signature = end of the first sector
```

以上代码为nasm语言。编译，
```shell
nasm boot.asm -o boot.bin
```

## Bochs虚拟机

用裸机来实验太不方便，因此使用Bochs虚拟机。先配置如下一台机器。

```
# bochsrc.txt

cpu: model=pentium, count=1

memory: guest=512, host=256

romimage: file=$BXSHARE/BIOS-bochs-latest, options=fastboot

vgaromimage: file=$BXSHARE/VGABIOS-lgpl-latest

mouse: enabled=0
keyboard: type=mf, keymap=$BXSHARE/keymaps/x11-pc-us.map

floppya: 1_44=a.img, status=inserted, write_protected=1

boot: floppy

log: bochsout.txt
```

其中的软盘`a.img`就是要制作的启动盘。

首先使用bochs自带的bximage工具，创建1.44M软盘。
```
bximage -mode=create -fd=1.44M -q a.img
```
> bximage默认是交互式操作的程序。`-q`是静默模式。

然后用Linux的`dd`命令把`boot.bin`写入软盘`a.img`。
```
dd if=boot.bin of=a.img bs=512 count=1 conv=notrunc
```

现在就可以bochs命令，开始运行了。

## 调试

Bochs最好从源码编译，以便定制功能。
```shell
~: ./configure --enable-debugger --enable-disasm
~: make
~: make install
```

在`bootsrc.txt`和`a.img`的目录下，运行`bochs`命令。当然，此时会自动进入调试模式。在提示符下键入`c`，即继续执行（continue）。虚拟机的屏幕上就打印出“Hello World!”了。然后陷入死循环。`Ctrl+C`退出即可。

> 键入`h`，查看更多调试命令。比如`b`设置断点，`r`查看通用寄存器。