# 交通信号灯控制

## 设计要求

1. 采用中断拦截技术计时
2. 在数码管上显示延时时间倒计时，利用发光二极管模拟交通灯的变化。十字路口交通灯的变化规律如下：

    1. 东西红灯，南北绿灯同时亮 30s
    2. 南北黄灯 3s ，东西红灯继续
    3. 南北红灯，东西绿灯，保持 30s
    4. 南北红灯继续，东西黄灯 3s
    5. 转第一步

## 设计细节

1. 使用的硬件及用途
    - 8259A 中断拦截
    - 8254 计时
    - 8255A A 口连接数码管作输出，B 口连接发光二极管作输出，C 口连接 PC0~PC3 接数码管位码作输出
    - 数码管显示交通灯倒计时
    - 发光二极管作交通灯

2. 十字路口，东西南北4组交通灯

3. 顺序：

    1. 东西红灯，南北绿灯同时亮 30s
    2. 南北黄灯 3s ，东西红灯继续
    3. 南北红灯，东西绿灯，保持 30s
    4. 南北红灯继续，东西黄灯 3s
    5. goto 1
    共有 4 种状态

4. 产生1s定时

    采用中断拦截技术实现一秒定时。在主程序的初始化部分，先保存当前 1CH 的中断向量，然后再将自己编写的中断服务程序入口地址放入中断类型 1CH 所对应的中断向量中，最后在主程序的结束部分恢复原 1CH 的中断向量

5. 数码管控制
    - 0～9： 3FH, 06H, 5BH, 4FH, 66H, 6DH, 7DH, 07H, 7FH, 6FH
    - 7段接 8255A 口，PA0-a, ..., PA6-g
    - 位码接 C 口，PC0-S0, ..., PC3-S3

6. 发光二极管控制
    - 发光二极管 L7-L0 接 8255A PB7-PB0，1亮0灭
    - L7-L5 东西方向红黄绿，L2-L0 南北方向红黄绿

        ```txt
        STATE_1: 10000001B
        STATE_2: 10000010B
        STATE_3: 00100100B
        STATE_4: 01000100B
        ```

7. 8259A

    IR0 接到 8254 的 OUT0

8. 8254

   工作在方式 3、初值为 0， GATE0 接 +5V， CLK0 接 1.193 MHz 的方波信号， OUT0 接到 8259A 的 IR0

9. 8255A

    - 见数码管、发光二极管
    - CS 接 288H~28BH

10. 初始化
    - 8255A A、B、C 端口均工作在方式0，控制字为 `10001000B`
    - 8254 控制字为 `00110110B`
    - 8259A 初始化　无
