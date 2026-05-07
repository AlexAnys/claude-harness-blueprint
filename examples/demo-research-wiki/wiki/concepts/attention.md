# Attention Mechanisms

> 编译自：raw/sample-paper.md 及相关素材
> 最后更新：2026-05-04

## 概述

Attention 机制允许模型在处理序列时动态关注不同位置的信息，
是 Transformer 架构的核心组件。

## Self-Attention

标准 self-attention 的计算：

```
Attention(Q, K, V) = softmax(QK^T / sqrt(d_k)) V
```

- **复杂度**：O(n^2 d)，其中 n 是序列长度，d 是维度
- **优点**：全局感受野，任意位置可以关注任意位置
- **瓶颈**：随序列长度二次增长，限制了长上下文应用

## 高效 Attention 变体

### FlashAttention

通过分块计算和 IO 感知的内存管理，加速标准 attention：
- 不改变数学等价性
- 减少 HBM 读写次数
- FlashAttention-3 在 H100 上进一步优化

### Sparse Attention

只计算部分位置对的 attention，降低复杂度：
- **Local windowed**：每个位置只关注附近的窗口
- **Global tokens**：部分特殊 token 关注全局
- **Learned patterns**：通过学习决定哪些位置对需要关注

> 参考：SparseFlash（Chen et al., 2026）提出了 learned sparse pattern
> selection，在 128K 长度上实现 8.9x 吞吐量提升，质量损失 <0.5%。
> 来源：raw/sample-paper.md

## Cross-Attention

用于两个不同序列之间的信息交互：
- Encoder-decoder 架构中，decoder 对 encoder 输出做 cross-attention
- 多模态模型中，文本对图像特征做 cross-attention

## 关联概念

- [返回索引](../index.md)
- Transformer Architecture（待创建）
- Sparse Attention（待编译）
