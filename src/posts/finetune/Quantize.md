---
author: Vichayturen
icon: boxes-packing
date: 2023-06-13
category:
  - 微调技术
tag:
  - 优化
  - 内存
  - 机器学习
---

# Int8量化技术原理讲解

Int量化技术是一种节约大模型推理或训练的过程中占用的显存的技术。量化的目是为了减少计算时间和计算能耗 。在一些场景下对能耗和时间的要求，要高于模型的指标，所以在这种情况下量化是一个必然的选择。

<!-- more -->

## 1 公式解析

基准：普通的Linear层：$y=Wx+b$

```python
x：tensor([1., 2., 3., 4.], device='cuda:0')
W：tensor([[ 0.4753,  0.4548, -0.2720,  0.0310],
                   [-0.3591, -0.4820, -0.3717, -0.2604]], device='cuda:0',requires_grad=True)
b：tensor([-0.4314,  0.1237], device='cuda:0', requires_grad=True)
y：tensor([ 0.2612, -3.3559], device='cuda:0', grad_fn=<AddBackward0>)
```

（1）令$W=TW'$，其中$T$是一个对角矩阵，相当于$W'$的每行乘以一个系数。

（2）选定$T$保证$W'$的每一行四舍五入到整型之后最大值为$127$或者最小值为$-127$即可，因此$T$完全由$W$决定。

T的对角元素：`tensor([0.0037, 0.0038], device='cuda:0', dtype=torch.float16)`

```python
W'：tensor([[ 127,  122,  -73,    8],
                    [ -95, -127,  -98,  -69]], device='cuda:0', dtype=torch.int8)
b：tensor([-0.4314,  0.1237], device='cuda:0', dtype=torch.float16)
```

（3）前向传播的计算公式变成了 $y=TW'x+b$。

（4）量化操作仅针对W，不针对$b$。量化之后，网络相当于舍弃了$W$，而保留了$W'$和$T$。$W'$由于变成了int8整型，因此对显存来说相当于多存了$T$的对角元素，少存了$W$的一半大小，总体上显存的压力是大大变小了。

```python
y：tensor([ 0.2571, -3.3652], device='cuda:0', dtype=torch.float16)
```

## 2 非对称量化

以上描述的过程是对称量化，对称量化把每一行的绝对值的最大值变换到$127$，而非对称量化是把每一行的最大值变换到$127$，最小值变换到$-128$，因此非对称量化的$W'=TW-p$，除了多一个$T$的对角元素之外还多一个偏移向量。
