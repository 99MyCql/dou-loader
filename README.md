# dou-loader -- asm course design

简易加载器 —— 汇编课程设计

## Introduction

- `study\`: 用于学习的练习程序

- `src\`: 正式项目

    - `dou-loader.asm`: 加载器
    - `helloworld.asm`: 加载程序一，由loader引导加载。以TTY方式输出helloworld，和输出有颜色的helloworld
    - `sum&diff.asm`: 加载程序二。接收用户从键盘输入的两个十进制正整数，然后计算并输出这两个数的和与差
    - `clock.asm`: 加载程序三。设置定时器中断，长久在右上角显示时间信息，并每过一秒就更新，用户可以选择暂停
    - `keyboard.asm`: 加载程序四。键盘中断，替换 INT 9 中断程序，用户输入F1-F9将出现不一样的现象
    - `div.asm`: 加载程序五。修改 INT 0 除法中断处理程序
    - `extend-IO.asm`: 加载程序六。设置 INT 90H 为扩展的输出程序，以TTY方式输出带属性的字符
    - `dou-snake.asm`: 加载程序七。完全自编写的汇编贪吃蛇游戏。

详细文档见[nasm汇编实现贪吃蛇](https://blog.dounine.live/nasm%E6%B1%87%E7%BC%96%E5%86%99%E8%B4%AA%E5%90%83%E8%9B%87.html)。

## Run

use `nasm` to compile the `.asm` e.g.:

```bash
nasm xxx.asm -f bin -o xxx.bin
```

or

```bash
nasm xxx.asm -f bin -o xxx
```

then, using `VHDwriter` to write binary in `.vhd` hard disk of Vitrual Machine.
