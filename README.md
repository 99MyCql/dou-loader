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

## Git Commit Format

```git
git commit -m "type: description"
```

- type:
    - feat：新功能（feature）
    - fix：修补bug
    - docs：文档（documentation）
    - style：格式（不影响代码运行的变动）
    - refactor：重构（即不是新增功能，也不是修改bug的代码变动）
    - test：增加测试
    - chore：构建过程或辅助工具的变动

- description: 详细描述
