---
author: Vichayturen
icon: blog
date: 2023-09-04
category:
  - rag
tag:
  - 检索
  - rag
# sticky: 10
---

# 大语言模型应用中的文本分块策略

这篇博文讨论了在构建与大语言模型（LLM）相关的应用中使用的文本分块策略。分块是将大段文本分解为较小段的过程，它对于优化向量数据库返回内容相关性至关重要。

<!-- more -->

文章来源：https://www.pinecone.io/learn/chunking-strategies/

## 1 介绍

在构建与LLM相关的应用时，**分块（chunking）** 是将大段文本分解为较小段的过程。当我们使用LLM嵌入内容时，chunking是一项帮助优化向量数据库返回内容相关性的基本技术。在这篇博文中，我们将探讨它是否以及如何帮助提高LLM相关应用的效率和准确性。

往向量数据库中索引的任何内容都需要首先向量化（称为嵌入，embedding）。分块的主要原因是确保我们向量化的内容的噪音尽可能少，并且具有语义相关性。

例如，在语义搜索（semantic search）中，我们索引文档语料库。每个文档都包含有关特定主题的有价值的信息。通过应用有效的分块策略，可以确保搜索结果准确捕获用户查询的本质。区块太小或太大，可能会导致搜索结果不精确或错失显示相关内容的机会。**根据经验，如果文本块在没有周围上下文的情况下对人类有意义，那么它对语言模型也有意义。** 因此，为语料库中的文档找到最佳区块大小对于确保搜索结果准确且相关至关重要。

另一个例子是会话代理（conversational agents）。我们使用向量化的块来构建基于知识库的会话代理的**上下文**，该知识库使代理基于**受信任**的信息。在这种情况下，对分块策略做出正确的选择很重要，原因有两个：首先，它将确定上下文是否真正与我们的提示（prompt）相关。其次，它将确定是否能够在将检索到的文本发送到外部模型提供者（例如OpenAI）之前将其放入上下文中，因为我们可以为每个请求发送的token数量受到限制。在某些情况下，例如将 GPT-4 与 32k 上下文窗口一起使用时，拟合区块可能不是问题。尽管如此，使用非常大的块可能会对从向量数据库返回的结果的相关性产生不利影响。

我们将探讨几种分块方法，并讨论在选择分块大小和方法时应考虑的权衡。最后，我们将提供一些建议，以确定适合您的应用的最佳区块大小和方法。

## 2 嵌入短内容和长内容

当我们嵌入内容时，我们可以根据内容是短（如句子）还是长（如段落或整个文档）来预测不同的行为。

当嵌入**句子**时，生成的向量侧重于句子的特定含义。与其他句子嵌入相比，比较自然会在该级别上进行。这也意味着嵌入可能会错过段落或文档中更广泛的上下文信息。

嵌入**整个段落或文档**时，嵌入过程会考虑整体上下文以及文本中句子和短语之间的关系。这可以产生更全面的矢量表示，从而捕获文本的更广泛含义和主题。另一方面，较大的输入文本大小可能会引入干扰或稀释单个句子或短语的重要性，从而在查询索引时更难找到精确匹配项。

查询的长度也会影响嵌入之间的相互关系。较短的查询（例如单个句子或短语）将专注于细节，并且可能更适合与句子级嵌入进行匹配。跨越多个句子或段落的较长查询可能更符合段落或文档级别的嵌入，因为它可能正在寻找更广泛的上下文或主题。

索引也可能是非同类的，并且包含不同大小的块的嵌入。这可能会在查询结果相关性方面带来挑战，但也可能会产生一些积极的后果。一方面，由于长内容和短内容的语义表示之间存在差异，查询结果的相关性可能会波动。另一方面，非同构索引可能会捕获更广泛的上下文和信息，因为不同的块大小表示文本中的不同粒度级别。这可以更灵活地适应不同类型的查询。

## 3 chunking注意事项

几个变量在确定最佳分块策略方面发挥作用，这些变量因用例而异。以下是需要牢记的一些关键方面：

1. **被索引的内容的性质是什么？** 您是处理较长的文档（如文章或书籍）还是较短的内容（如推文或即时消息）？答案将决定哪种模型更适合您的目标，从而决定应用哪种分块策略。

2. **您使用的是哪种嵌入模型，它在哪些块大小上表现最佳？** 例如，[sentence-transformer](https://huggingface.co/sentence-transformers)模型在单个句子上效果很好，但像[text-embedding-ada-002](https://openai.com/blog/new-and-improved-embedding-model)这样的模型在包含 256 或 512 个token的块上表现更好。

3. **您对用户查询的长度和复杂性有何期望？** 它们是简短而具体的还是冗长而复杂的？这也可能会告知您选择对内容进行分块的方式，以便嵌入式查询和嵌入式区块之间有更紧密的相关性。

4. **检索到的结果将如何在您的特定应用程序中使用？** 例如，它们是否用于语义搜索、问答、摘要或其他目的？例如，如果你的结果需要被输入到另一个具有令牌限制的LLM，你必须考虑到这一点，并根据你想要适应LLM请求的块数来限制块的大小。

回答这些问题将允许您开发平衡性能和准确性的分块策略，这反过来又将确保查询结果更具相关性。

## 4 分块方法
有不同的分块方法，每种方法可能适用于不同的情况。通过检查每种方法的优点和缺点，我们的目标是确定应用它们的正确方案。

### 4.1 固定大小的分块
这是最常见和最直接的分块方法：我们只需决定块中的代币数量，以及它们之间是否应该有任何重叠。通常，我们希望在块之间保持一些重叠，以确保语义上下文不会在块之间丢失。在大多数常见情况下，固定大小的分块将是最佳路径。与其他形式的分块相比，固定大小的分块在计算上便宜且易于使用，因为它不需要使用任何 NLP 库。

下面是使用 [LangChain](https://api.python.langchain.com/en/latest/api_reference.html) 执行固定大小的分块的示例：

```Python
text = "..." # your text
from langchain.text_splitter import CharacterTextSplitter
text_splitter = CharacterTextSplitter(
    separator = "\n\n",
    chunk_size = 256,
    chunk_overlap  = 20
)
docs = text_splitter.create_documents([text])
```

### 4.2 “内容感知”（Content-aware）分块
这些是一组方法，用于利用我们正在分块的内容的性质并对其应用更复杂的分块。以下是一些示例：

#### 4.2.1 句子切分
正如我们之前提到的，许多模型都针对嵌入句子级内容进行了优化。当然，我们会使用句子分块，并且有几种方法和工具可用于执行此操作，包括：

- **朴素切分**：最简单的方法是按句点（“.”）和换行符切分句子。虽然这可能既快速又简单，但这种方法不会考虑所有可能的边缘情况。下面是一个非常简单的示例：

```Python
text = "..." # your text
docs = text.split(".")
```

- **[NLTK](https://www.nltk.org/)**：自然语言工具包（NLTK）是一个流行的Python库，用于处理人类语言数据。它提供了一个句子分词器，可以将文本切分为句子，帮助创建更有意义的块。例如，要将NLTK与LangChain一起使用，您可以执行以下操作：
```Python
text = "..." # your text
from langchain.text_splitter import NLTKTextSplitter
text_splitter = NLTKTextSplitter()
docs = text_splitter.split_text(text)
```

- **[spaCy](https://spacy.io/)**：spaCy是另一个强大的Python库，用于NLP任务。它提供了复杂的分句功能，可以有效地将文本划分为单独的句子，从而在生成的块中更好地保留上下文。例如，要将spaCy与LangChain一起使用，您可以执行以下操作：
```Python
text = "..." # your text
from langchain.text_splitter import SpacyTextSplitter
text_splitter = SpaCyTextSplitter()
docs = text_splitter.split_text(text)
```

#### 4.2.2 递归分块
递归分块使用一组分隔符以分层和迭代方式将输入文本划分为较小的块。如果拆分文本的初始尝试未生成所需大小或结构的块，则该方法会使用不同的分隔符或条件递归调用生成的块，直到达到所需的块大小或结构。这意味着，虽然块的大小不会完全相同，但它们仍然追求具有相似的大小。

下面是如何在 LangChain 中使用递归分块的示例：
```Python
text = "..." # your text
from langchain.text_splitter import RecursiveCharacterTextSplitter
text_splitter = RecursiveCharacterTextSplitter(
    # Set a really small chunk size, just to show.
    chunk_size = 256,
    chunk_overlap  = 20
)

docs = text_splitter.create_documents([text])
```

#### 4.2.3 专用分块

Markdown和LaTeX是您可能会遇到的结构化和格式化内容的两个例子。在这些情况下，您可以使用专门的分块方法在分块过程中保留内容的原始结构。

- **[Markdown](https://www.markdownguide.org/)**：Markdown 是一种轻量级标记语言，通常用于格式化文本。通过识别 Markdown 语法（例如，标题、列表和代码块），您可以根据内容的结构和层次结构智能地划分内容，从而产生语义上更一致的块。例如：
```Python
from langchain.text_splitter import MarkdownTextSplitter
markdown_text = "..."

markdown_splitter = MarkdownTextSplitter(chunk_size=100, chunk_overlap=0)
docs = markdown_splitter.create_documents([markdown_text])

```

- **[LaTex](https://www.latex-project.org/)**：LaTeX是一种文档准备系统和标记语言，通常用于学术论文和技术文档。通过解析 LaTeX 命令和环境，您可以创建尊重内容逻辑组织（例如，部分、子部分和公式）的块，从而获得更准确和上下文相关的结果。例如：

```Python
from langchain.text_splitter import LatexTextSplitter
latex_text = "..."
latex_splitter = LatexTextSplitter(chunk_size=100, chunk_overlap=0)
docs = latex_splitter.create_documents([latex_text])
```

## 5 确定应用的最佳块大小
以下是一些指导意见，可帮助您在常见的分块方法（如固定分块）不容易应用于您的应用场景时提出最佳块大小。

- **预处理数据** - 在确定应用的最佳区块大小之前，需要先预处理数据以确保质量。例如，如果您的数据是从网络上抓取的，则可能需要移除具有干扰作用的 HTML标记或特定元素。

- **选择一组区块大小** - 预处理数据后，下一步是选择要测试的潜在区块大小范围。如前所述，选择应考虑内容的性质（例如，短消息或长文档）、您将使用的embedding模型及其功能（例如，token限制）。目标是在保留上下文和保持准确性之间找到平衡。首先探索各种块大小，包括用于捕获更精细语义信息的较小块（例如，128或256个token）和用于保留更多上下文的较大块（例如，512或1024个token）。

- **评估每个区块大小的性能** - 为了测试各种区块大小，您可以使用多个索引或具有多个[命名空间](https://docs.pinecone.io/docs/namespaces)的单个索引。使用代表性数据集，为要测试的区块大小创建嵌入向量，并将其保存在索引（或多个索引）中。然后，可以运行一系列查询，以便评估质量，并比较各种区块大小的性能。这很可能是一个迭代过程，您可以在其中针对不同的查询测试不同的区块大小，直到您可以确定内容和预期查询的最佳性能区块大小。

## 6 总结
在大多数情况下，对内容进行分块非常简单。但是当您开始徘徊在人迹罕至的地方时，它可能会带来一些挑战。文本分块没有一刀切的解决方案，因此适用于一个场景的方法可能不适用于另一个场景。希望这篇文章能帮助你更好地了解如何为您的应用进行文本分块。



