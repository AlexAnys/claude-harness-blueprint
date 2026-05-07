# 论文摘要：Efficient Sparse Attention for Long-Context Transformers

> 来源：arXiv:2026.XXXXX（虚构）
> 作者：Chen et al.
> 发表时间：2026-03

## Abstract

We propose SparseFlash, a sparse attention mechanism that reduces the quadratic
complexity of standard attention to near-linear while maintaining quality on
long-context tasks. Our approach combines local windowed attention with learned
sparse global patterns, achieving 3.2x speedup on 128K context length inputs
compared to FlashAttention-3. We evaluate on document summarization, multi-hop
QA, and code understanding benchmarks, showing <0.5% quality degradation on
all tasks.

## Key Contributions

1. Learned sparse pattern selection that adapts per-head and per-layer
2. Efficient CUDA kernel leveraging block-sparse matrix multiplication
3. Seamless integration with existing FlashAttention infrastructure

## Results Summary

| Benchmark | Standard Attention | FlashAttention-3 | SparseFlash |
|-----------|--------------------|-------------------|-------------|
| DocSum-128K | 42.1 ROUGE-L | 42.1 ROUGE-L | 41.8 ROUGE-L |
| MultiHop-QA | 67.3 F1 | 67.3 F1 | 67.0 F1 |
| CodeUnder-64K | 78.5 Acc | 78.5 Acc | 78.2 Acc |
| Throughput (128K) | 1.0x | 2.8x | 8.9x |

## Notes for Compilation

- 核心概念：sparse attention, learned sparsity patterns, block-sparse kernels
- 关联概念：FlashAttention, local attention, global tokens
- 潜在 wiki 页面：Attention Mechanisms（更新）, Sparse Attention（新建）
