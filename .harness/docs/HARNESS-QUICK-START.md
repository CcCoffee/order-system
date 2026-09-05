# Harness Engineering Quick Start

> 面向公司研发团队的 Harness Engineering 快速上手指南  
> 技术栈示例：VS Code + GitHub Copilot + Spring Boot + React

---

## 1. 什么是 Harness Engineering？

Harness Engineering 可以简单理解为：

> **不是让 Agent “更聪明”，而是给 Agent 建立一套可靠的工程环境，让它能够自主实现、验证、发现问题并修复。**

传统 AI Coding 的工作方式通常是：

```text
人
 ↓
告诉 Agent 要做什么
 ↓
Agent 修改代码
 ↓
人检查代码
 ↓
发现问题
 ↓
继续告诉 Agent 修改
```

Harness Engineering 希望变成：

```text
                  ┌────────────────────┐
                  │      Harness       │
                  │                    │
                  │  Rules / Contracts │
                  │  Tasks / Eval      │
                  │  Verification      │
                  └─────────┬──────────┘
                            │
                            ▼
                       ┌─────────┐
                       │  Agent  │
                       └────┬────┘
                            │
                            ▼
                         修改代码
                            │
                            ▼
                    ┌──────────────┐
                    │   verify.sh  │
                    └──────┬───────┘
                           │
                    ┌──────┴──────┐
                    │             │
                   PASS          FAIL
                    │             │
                    ▼             ▼
                  完成        Agent 分析问题
                                  │
                                  ▼
                               修复代码
                                  │
                                  └───────► 再次验证
```

核心不是“Agent 写代码”。

核心是：

> **让 Agent 在一个有明确边界、明确任务、明确验证标准的工程环境中持续工作。**

---

# 2. 为什么需要 Harness？

LLM Agent 写代码最大的风险并不是“不会写代码”。

而是：

- 理解需求不完整
- 修改范围失控
- 为了通过测试而修改测试
- 忽略架构约束
- 产生隐藏技术债
- 只实现 Happy Path
- 修改 A 功能时破坏 B 功能
- 遇到失败后不断尝试随机修改
- 最终无法判断“到底完成没有”

例如：

```text
需求：

增加订单取消功能
```

普通 Agent 可能：

```text
创建 cancel API
        ↓
修改 Order.status
        ↓
测试通过
        ↓
完成
```

但是一个真实的订单系统可能还要求：

```text
取消订单
   │
   ├── 状态必须是 PENDING
   │
   ├── 修改订单状态
   │
   ├── 释放库存
   │
   ├── 写入审计日志
   │
   ├── 所有操作必须在同一个事务中
   │
   ├── 重复取消不能重复释放库存
   │
   └── 原有订单功能不能受到影响
```

如果这些规则没有进入 Harness，Agent 很容易只完成其中一部分。

---

# 3. Harness 的核心思想

一个最小可用 Harness 不需要复杂的平台。

第一阶段只需要四件事情：

```text
1. Instructions
2. Task
3. Evaluation
4. Verification
```

对应：

| 部分 | 作用 |
|---|---|
| Instructions | 告诉 Agent 应该如何开发 |
| Task | 告诉 Agent 当前需要完成什么 |
| Evaluation | 定义什么叫“完成” |
| Verification | 用程序客观判断是否完成 |

其中最重要的是：

> **Evaluation 定义标准，Verification 执行标准。**

---

# 4. 推荐的项目结构

一个 Spring Boot + React 项目的 Harness 可以从下面的结构开始：

```text
project/
│
├── backend/
│
├── frontend/
│
├── docs/
│   ├── architecture/
│   ├── api/
│   └── database/
│
├── scripts/
│   ├── verify.sh
│   ├── verify-structure.sh
│   ├── verify-infrastructure.sh
│   ├── verify-backend.sh
│   ├── verify-architecture.sh
│   ├── verify-api.sh
│   ├── verify-frontend.sh
│   └── e2e.sh
│
├── .harness/
│   ├── config/
│   │   └── evaluations.yaml
│   │
│   ├── evaluations/
│   │   ├── 001-order-system-mvp.md
│   │   ├── 002-order-cancellation.md
│   │   ├── 003-inventory-concurrency.md
│   │   ├── 004-order-idempotency.md
│   │   └── 005-regression.md
│   │
│   ├── tasks/
│   │   ├── 001-order-system-mvp.prompt.md
│   │   ├── 002-order-cancellation.prompt.md
│   │   ├── 003-inventory-concurrency.prompt.md
│   │   ├── 004-order-idempotency.prompt.md
│   │   └── 005-regression.prompt.md
│   │
│   └── state/
│
├── .github/
│   ├── agents/
│   │   └── order-system.agent.md
│   │
│   └── instructions/
│       ├── backend.instructions.md
│       ├── frontend.instructions.md
│       └── testing.instructions.md
│
├── .vscode/
│
├── AGENTS.md
│
└── README.md
```

并不要求一开始就建立所有目录。

最小 Harness 可以只有：

```text
AGENTS.md
.harness/
  evaluations/
  tasks/
scripts/
  verify.sh
.github/
  instructions/
  agents/
```

---

# 5. 各个目录分别负责什么？

## 5.1 `AGENTS.md`

这是项目级的总规则。

它回答：

> Agent 在这个项目里应该遵守什么原则？

例如：

```text
# Agent Engineering Rules

## General

- 不允许修改测试来绕过失败
- 不允许删除已有功能
- 不允许为了通过验证而硬编码测试数据
- 修改代码后必须运行 ./scripts/verify.sh
- 不确定时优先阅读现有代码和文档

## Backend

- 遵循现有 Spring Boot 架构
- Controller 不直接访问 Repository
- 业务逻辑必须位于 Service 层
- 数据库修改必须考虑事务

## Frontend

- 遵循现有 React 项目结构
- API 调用统一封装
- 页面必须处理 loading / error 状态

## Verification

完成任务前必须：

./scripts/verify.sh
```

它不是任务描述。

它是：

> **项目级工程宪法。**

---

# 6. Instructions

`.github/instructions/` 用于放更细粒度的开发规则。

例如：

```text
.github/instructions/
├── backend.instructions.md
├── frontend.instructions.md
└── testing.instructions.md
```

---

## 6.1 Backend Instructions

例如：

```markdown
# Backend Development Rules

## Architecture

Use the existing layered architecture:

Controller
    ↓
Service
    ↓
Repository
    ↓
Database

Do not put business logic in controllers.

## Transaction

Operations that modify multiple related entities must consider
transaction boundaries.

## Database

Do not modify the database schema only to make a test pass.

## Error Handling

Use the project's existing exception handling mechanism.

## Testing

Business logic must have unit tests.

Database behavior must have integration tests where appropriate.
```

---

## 6.2 Frontend Instructions

例如：

```markdown
# Frontend Development Rules

## Architecture

Follow the existing React project structure.

## API

Do not directly duplicate HTTP logic across components.

Use the existing API abstraction.

## UI State

Pages must consider:

- loading
- success
- empty
- error

## Changes

Do not rewrite unrelated components.

Prefer small, focused changes.
```

---

## 6.3 Testing Instructions

例如：

```markdown
# Testing Rules

Tests are part of the product contract.

Do not:

- delete tests
- weaken assertions
- skip tests
- disable verification
- change expected behavior only to make tests pass

When a test fails:

1. Understand the failure.
2. Determine whether the implementation is wrong.
3. Fix the implementation.
4. Re-run the test.
5. Run the full verification before completion.
```

---

# 7. Task：告诉 Agent 做什么

Task 不应该同时承担所有规则。

例如：

`.harness/tasks/002-order-cancellation.prompt.md`

可以是：

```markdown
# Task: Order Cancellation

Implement order cancellation.

Requirements:

1. Only PENDING orders can be cancelled.
2. PAID orders cannot be cancelled.
3. SHIPPED orders cannot be cancelled.
4. CANCELLED orders cannot be cancelled again.
5. Cancellation must release reserved inventory.
6. Inventory must only be released once.
7. Cancellation must create an audit log.
8. Related database changes must be transactional.

Before finishing:

1. Inspect the existing order implementation.
2. Implement the feature.
3. Add or update tests.
4. Run:

./scripts/verify.sh

Do not modify evaluation criteria or weaken tests.
```

Task 的职责是：

> **告诉 Agent 现在要解决什么问题。**

---

# 8. Evaluation：什么叫完成？

Evaluation 和 Task 最大的区别：

### Task

告诉 Agent：

> “你要做什么。”

### Evaluation

告诉 Harness：

> “什么结果才算完成。”

例如：

```markdown
# Evaluation: Order Cancellation

## Functional Requirements

### Valid cancellation

Given an order with status PENDING:

- cancellation succeeds
- order status becomes CANCELLED
- reserved inventory is released
- an audit log is created

### Invalid cancellation

The following operations must fail:

PENDING → ?

Valid:

PENDING → CANCELLED

Invalid:

PAID → CANCELLED
SHIPPED → CANCELLED
CANCELLED → CANCELLED

### Idempotency

Repeated cancellation must not release inventory more than once.

### Transaction

Order status, inventory release and audit log must remain consistent
when an operation fails.

## Verification

The implementation must pass:

./scripts/verify.sh
```

Evaluation 的重要原则：

> **描述业务行为，而不是描述 Agent 应该怎么写代码。**

不要写：

```text
Agent 必须创建 CancelOrderService.java
```

应该写：

```text
订单处于 PENDING 状态时允许取消。
取消后库存必须恢复。
```

这样 Agent 才有实现空间。

---

# 9. Verification：Harness 的裁判

这是整个 Harness 最重要的部分。

推荐项目只保留一个统一入口：

```bash
./scripts/verify.sh
```

例如：

```bash
#!/usr/bin/env bash

set -e

echo "==> Verify project structure"
./scripts/verify-structure.sh

echo "==> Verify infrastructure"
./scripts/verify-infrastructure.sh

echo "==> Verify backend"
./scripts/verify-backend.sh

echo "==> Verify architecture"
./scripts/verify-architecture.sh

echo "==> Verify API"
./scripts/verify-api.sh

echo "==> Verify frontend"
./scripts/verify-frontend.sh

echo "==> Verify E2E"
./scripts/e2e.sh

echo ""
echo "================================"
echo "       HARNESS VERIFY: PASS"
echo "================================"
```

失败：

```text
HARNESS VERIFY: FAIL
```

成功：

```text
HARNESS VERIFY: PASS
```

---

# 10. 为什么一定要有 `verify.sh`？

因为 Agent 自己说：

```text
代码已经完成了。
```

没有意义。

Agent 的判断可能受到：

- 上下文
- LLM 推理
- 错误理解
- 测试覆盖率
- 自我确认偏差

影响。

Harness 应该让 Agent 面对一个客观结果：

```text
./scripts/verify.sh

PASS
```

或者：

```text
./scripts/verify.sh

FAIL
```

因此：

> **Agent 负责实现，Harness 负责判断。**

这是 Harness Engineering 最重要的边界之一。

---

# 11. Verification 应该检查什么？

一个企业后端项目至少可以检查：

```text
                    verify.sh
                       │
       ┌───────────────┼────────────────┐
       │               │                │
       ▼               ▼                ▼
   Structure       Backend          Frontend
       │               │                │
       ▼               ▼                ▼
   文件结构          编译              TypeScript
   必要文件          Unit Test          Build
   配置              Integration Test   Lint
       │               │                │
       └───────────────┼────────────────┘
                       │
                       ▼
                     API
                       │
                       ▼
                     E2E
```

---

# 12. 不要一开始就追求复杂 Evaluation

Harness 很容易走向过度设计。

例如一开始就加入：

```text
Agent score
Token usage
Execution duration
Cost
Baseline
Benchmark
LLM judge
复杂 dashboard
```

这些都不是 Harness MVP 的必要组成部分。

第一阶段最重要的是：

```text
需求
 ↓
Agent
 ↓
代码
 ↓
验证
 ↓
PASS / FAIL
```

因此建议：

> **先建立确定性的工程反馈闭环，再考虑其他指标。**

---

# 13. 一个好的 Verification 应该是什么样？

好的：

```bash
./scripts/verify-backend.sh
```

内部：

```bash
mvn test
```

好的：

```bash
./scripts/verify-api.sh
```

检查：

```text
POST /api/orders
GET /api/orders/{id}
POST /api/orders/{id}/cancel
```

好的：

```bash
./scripts/e2e.sh
```

验证：

```text
创建订单
 ↓
查询订单
 ↓
取消订单
 ↓
确认库存
 ↓
确认订单状态
```

不好的：

```text
echo "Everything looks good"
exit 0
```

或者：

```bash
mvn test || true
```

因为：

```text
FAIL
 ↓
true
 ↓
PASS
```

这会直接破坏 Harness 的可信度。

---

# 14. Harness 的核心原则：不要让 Agent 修改裁判

这是一个非常重要的规则。

禁止：

```text
Agent 修改业务代码
Agent 修改测试
Agent 修改 Evaluation
Agent 修改 verify.sh
然后重新运行验证
```

尤其不能允许：

```text
测试失败
 ↓
修改测试断言
 ↓
测试通过
```

Harness 的目标是：

> **让 Agent 适应工程约束，而不是让工程约束适应 Agent。**

因此可以在 `AGENTS.md` 中明确：

```text
The agent must not modify:

- .harness/evaluations/
- verification criteria
- verification scripts

unless the task explicitly asks for changes to the Harness itself.
```

---

# 15. Harness 的反馈闭环

一个成熟的 Agent 工作过程应该类似：

```text
读取项目
   ↓
读取 AGENTS.md
   ↓
读取 Instructions
   ↓
读取 Task
   ↓
理解现有代码
   ↓
制定实现方案
   ↓
修改代码
   ↓
运行测试
   ↓
./scripts/verify.sh
   │
   ├── PASS ───────────► 完成
   │
   └── FAIL
          ↓
      分析失败原因
          ↓
       修改代码
          ↓
      再次验证
          │
          └────────────► PASS
```

这就是最小的：

> **Agent → Verification → Feedback → Repair Loop**

---

# 16. 一个实际例子：订单取消

假设产品经理提出：

> “增加订单取消功能。”

传统开发：

```text
PM
 ↓
开发人员
 ↓
写代码
 ↓
自己测试
 ↓
Code Review
 ↓
QA
 ↓
发现问题
 ↓
开发修复
```

Harness Engineering：

```text
Product Requirement
       ↓
.harness/tasks/002-order-cancellation.prompt.md
       ↓
Agent
       ↓
修改代码
       ↓
./scripts/verify.sh
       ↓
FAIL
       ↓
Agent 分析失败
       ↓
修复
       ↓
./scripts/verify.sh
       ↓
PASS
```

例如第一次：

```text
OrderCancellationTest
FAILED

Expected inventory: 10
Actual inventory: 9
```

Agent 可以发现：

```text
取消订单后没有释放库存
```

然后修复。

第二次：

```text
InventoryReleaseTest
PASS

AuditLogTest
PASS

OrderStatusTest
PASS

TransactionTest
PASS

RegressionTest
PASS
```

最终：

```text
HARNESS VERIFY: PASS
```

此时人类不需要逐行检查：

> “Agent 到底有没有把库存释放？”

因为这个要求已经成为机器可验证的工程约束。

---

# 17. Evaluation 应该逐步增加

不要一开始设计几十个 Evaluation。

推荐：

```text
001 MVP
```

验证基本系统能运行。

然后：

```text
002 Order Cancellation
```

验证状态机和事务。

然后：

```text
003 Inventory Concurrency
```

验证并发库存。

然后：

```text
004 Order Idempotency
```

验证重复请求。

最后：

```text
005 Regression
```

验证旧功能没有被破坏。

最终：

```text
.harness/evaluations/

001-order-system-mvp.md
002-order-cancellation.md
003-inventory-concurrency.md
004-order-idempotency.md
005-regression.md
```

形成一套逐步增强的工程约束。

---

# 18. 为什么要把 Regression 单独作为 Evaluation？

因为 Agent 修改代码时：

```text
修改订单取消
```

可能导致：

```text
创建订单
查询订单
库存
支付
API
Frontend
```

出现问题。

所以：

> 新功能通过 ≠ 系统没有被破坏。

Regression Evaluation 的意义是：

```text
New Feature
     +
Existing Features
     ↓
System Still Works
```

例如：

```bash
./scripts/verify.sh
```

应该最终覆盖：

```text
MVP
Cancellation
Inventory
Idempotency
Regression
```

---

# 19. Harness 不等于测试框架

这是一个容易产生误解的地方。

JUnit：

```text
测试 Java 代码
```

Playwright：

```text
测试浏览器
```

Postman/Newman：

```text
测试 API
```

Harness：

```text
组织这些验证
+
给 Agent 提供工程规则
+
定义任务
+
提供反馈闭环
```

所以：

```text
             Harness
                │
       ┌────────┼────────┐
       │        │        │
      Unit   Integration  E2E
       │        │        │
      JUnit   PostgreSQL Playwright
```

Harness 并不需要替代现有测试工具。

它是：

> **把这些工具组织成 Agent 可执行的工程反馈系统。**

---

# 20. Harness 不等于 Custom Agent

例如：

`.github/agents/order-system.agent.md`

这是一个：

> GitHub Copilot Custom Agent

它定义：

```text
这个 Agent 应该如何工作。
```

而：

```text
.harness/
```

定义：

```text
这个项目如何约束和验证 Agent 的工作。
```

两者不是一个东西。

可以理解成：

```text
                Harness
                   │
          ┌────────┴────────┐
          │                 │
       Rules              Evaluation
          │                 │
          └────────┬────────┘
                   │
                   ▼
                 Agent
                   │
                   ▼
                 Code
                   │
                   ▼
              Verification
```

---

# 21. 为什么先做 Single Agent？

Harness Engineering 和 Multi-Agent 是两个不同的问题。

第一阶段：

```text
        Harness
           │
           ▼
      Single Agent
           │
           ▼
        Code
           │
           ▼
      Verification
```

先证明：

```text
Agent 能理解规则
Agent 能执行任务
Agent 能运行验证
Agent 能根据失败修复
```

如果这套闭环都没有建立起来，直接 Multi-Agent：

```text
Planner
Backend
Frontend
Tester
Reviewer
```

只会增加协调复杂度。

---

# 22. Multi-Agent 是下一阶段

当 Single Agent Harness 稳定之后，可以演进：

```text
                    Harness
                       │
              ┌────────┼────────┐
              │        │        │
           Planner   Backend   Frontend
              │        │        │
              └────────┼────────┘
                       │
                     Test
                       │
                    Reviewer
                       │
                       ▼
                  Verification
```

这时候 Harness 负责：

- 任务边界
- Agent 权限
- 文件所有权
- Agent 之间的交接
- Verification
- Regression
- 最终 PASS / FAIL

而不是让 Agent 自己决定：

> “我觉得这个代码应该没问题。”

---

# 23. 推荐的 Agent 边界

未来 Multi-Agent 可以这样设计：

```text
Planner
  │
  ├── 分析需求
  ├── 拆分任务
  └── 不直接修改业务代码
        │
        ▼
Backend Agent
  │
  ├── Spring Boot
  ├── Database
  └── API
        │
        ▼
Frontend Agent
  │
  └── React
        │
        ▼
Test Agent
  │
  └── Unit / Integration / E2E
        │
        ▼
Reviewer
  │
  └── Review
        │
        ▼
Harness Verification
```

但需要强调：

> **这是 Harness 成熟之后的演进方向，不是第一步。**

---

# 24. `.harness/config/evaluations.yaml`

可以维护当前 Evaluation：

```yaml
evaluations:
  - id: 001
    name: order-system-mvp
    file: .harness/evaluations/001-order-system-mvp.md

  - id: 002
    name: order-cancellation
    file: .harness/evaluations/002-order-cancellation.md

  - id: 003
    name: inventory-concurrency
    file: .harness/evaluations/003-inventory-concurrency.md

  - id: 004
    name: order-idempotency
    file: .harness/evaluations/004-order-idempotency.md

  - id: 005
    name: regression
    file: .harness/evaluations/005-regression.md

verification:
  command: ./scripts/verify.sh
```

这个文件的作用不是复杂编排。

主要用于：

> **告诉团队当前 Harness 包含哪些 Evaluation，以及统一验证入口是什么。**

---

# 25. 新项目如何快速增加 Harness？

对于一个已有 Spring Boot 项目，可以按照下面的顺序。

## Step 1：建立统一验证入口

首先确保：

```bash
./scripts/verify.sh
```

能够执行。

---

## Step 2：建立项目规则

创建：

```text
AGENTS.md
```

把团队真正重要的工程规则写进去。

不要写几十页。

只写：

```text
必须遵守什么
不能做什么
验证怎么运行
```

---

## Step 3：建立 Instructions

创建：

```text
.github/instructions/
```

按技术领域拆分：

```text
backend.instructions.md
frontend.instructions.md
testing.instructions.md
```

---

## Step 4：定义第一个 Evaluation

例如：

```text
.harness/evaluations/001-mvp.md
```

只定义最核心的业务能力。

---

## Step 5：创建 Task

例如：

```text
.harness/tasks/001-mvp.prompt.md
```

让 Agent 按 Evaluation 完成任务。

---

## Step 6：让 Agent 执行

在 VS Code / GitHub Copilot 中：

```text
读取项目规则
+
读取 Task
+
实现功能
+
运行 ./scripts/verify.sh
```

---

## Step 7：失败就修复

如果：

```text
verify.sh
```

返回：

```text
FAIL
```

Agent 不应该停止。

应该：

```text
读取失败信息
 ↓
定位原因
 ↓
修改代码
 ↓
重新验证
```

直到：

```text
PASS
```

---

# 26. 给团队成员的最简单使用方式

以后同事接手一个 Harness 项目，可以只记住下面四步：

```text
① 阅读 AGENTS.md

② 阅读当前 .harness/tasks/*.prompt.md

③ 使用 Copilot Agent 实现任务

④ 运行：

   ./scripts/verify.sh
```

如果：

```text
PASS
```

任务完成。

如果：

```text
FAIL
```

继续修复。

---

# 27. 新增业务需求时怎么做？

假设新增：

> “订单支持退款。”

不要直接让 Agent：

```text
帮我实现退款。
```

而应该增加：

```text
.harness/
├── evaluations/
│   └── 006-order-refund.md
│
└── tasks/
    └── 006-order-refund.prompt.md
```

Evaluation：

```text
什么情况下可以退款？
退款后订单状态是什么？
库存是否恢复？
金额如何处理？
重复退款怎么办？
失败如何处理？
原有功能是否保持？
```

Task：

```text
请实现订单退款功能。

完成后运行：

./scripts/verify.sh
```

这样每个重要业务能力都逐渐变成：

```text
需求
 ↓
Evaluation
 ↓
Task
 ↓
Implementation
 ↓
Verification
```

---

# 28. Harness 的几个关键原则

## 原则 1：机器可验证优先

不要只写：

```text
代码质量要高。
```

尽量变成：

```text
Controller 不允许直接访问 Repository。
```

或者：

```text
./scripts/verify-architecture.sh
```

能够验证。

---

## 原则 2：业务规则优先于实现方式

不要规定：

```text
必须使用某个具体 Java 类。
```

除非这是架构约束。

优先规定：

```text
取消订单必须释放库存。
```

让 Agent 自己选择合理实现。

---

## 原则 3：Verification 必须可信

不要：

```bash
command || true
```

不要：

```text
失败就跳过。
```

不要：

```text
为了让 Agent PASS 而降低断言。
```

否则 Harness 会逐渐失去意义。

---

## 原则 4：失败是反馈，不是异常

Harness 最有价值的地方就是：

```text
FAIL
```

不是失败。

真正的问题是：

```text
FAIL
 ↓
没人知道为什么
```

好的 Harness 应该输出：

```text
FAIL

OrderCancellationTest
Expected: inventory = 10
Actual:   inventory = 9

Cause:
Inventory was not released during cancellation.
```

让 Agent 能够继续工作。

---

## 原则 5：不要过度设计

第一阶段不需要：

```text
复杂 Agent Orchestrator
复杂 Dashboard
Baseline
Performance Benchmark
Token Cost Tracking
LLM Judge
复杂评分系统
```

只需要：

```text
Rules
+
Task
+
Evaluation
+
Verification
```

---

# 29. Harness 成熟度模型

可以把团队的 Harness Engineering 分成四个阶段。

## Level 0：普通 AI Coding

```text
Developer
    ↓
Copilot
    ↓
Code
```

---

## Level 1：Single Agent Harness

```text
Rules
 ↓
Task
 ↓
Agent
 ↓
Code
 ↓
verify.sh
 ↓
PASS / FAIL
```

这是最推荐的起点。

---

## Level 2：Domain Evaluation

开始建立：

```text
MVP
Cancellation
Concurrency
Idempotency
Regression
```

让越来越多的业务规则变成机器可验证的 Contract。

---

## Level 3：Multi-Agent Harness

```text
Planner
Backend
Frontend
Test
Reviewer
```

所有 Agent 共用：

```text
Harness
```

---

## Level 4：Organization Harness

最终可以沉淀成公司级模板：

```text
company-harness/
│
├── backend/
├── frontend/
├── database/
├── security/
├── testing/
├── architecture/
└── deployment/
```

新项目初始化：

```text
create-project
      ↓
初始化 Harness
      ↓
项目自己的 Evaluation
      ↓
项目自己的 Verification
```

这样 Harness Engineering 就从：

> “某个程序员会使用 Copilot”

变成：

> **公司的工程能力。**

---

# 30. 推荐的团队规范

建议团队统一约定：

```text
每个重要业务能力都应该有 Evaluation。

每个 Evaluation 都应该有对应 Task。

每个项目都应该有唯一的 ./scripts/verify.sh。

Agent 完成任务前必须运行 verify.sh。

Verification 失败时优先修复实现，而不是修改测试。

Evaluation 和 Verification 不应该由 Agent 随意修改。

新增功能必须考虑 Regression。

Harness 本身也应该保持简单。
```

---

# 31. 一个完整的 Harness 工作示例

最终，一个开发需求可以形成这样的链路：

```text
                    产品需求
                       │
                       ▼
              Order Cancellation
                       │
                       ▼
             ┌─────────────────┐
             │   Evaluation    │
             │                 │
             │ PENDING only    │
             │ Release stock   │
             │ Audit log       │
             │ Transaction     │
             │ Idempotency     │
             └────────┬────────┘
                      │
                      ▼
                  Task Prompt
                      │
                      ▼
                    Agent
                      │
                      ▼
                 修改代码
                      │
                      ▼
               Unit / Integration
                      │
                      ▼
                ./scripts/verify.sh
                      │
                 ┌────┴────┐
                 │         │
               PASS       FAIL
                 │         │
                 │         ▼
                 │       分析
                 │         │
                 │       修复
                 │         │
                 │         └───────┐
                 │                 │
                 │            verify.sh
                 │                 │
                 │              PASS
                 │                 │
                 └─────────────────┘
```

这就是一个完整的 Harness Engineering Feedback Loop。

---

# 32. 最后：Harness Engineering 到底改变了什么？

传统开发：

```text
人负责：
需求理解
设计
编码
测试
调试
验证
```

Agent Coding：

```text
人负责需求
Agent 负责编码
人负责验证
```

Harness Engineering：

```text
人：
定义工程规则
定义业务 Contract
定义 Evaluation

Agent：
理解任务
实现代码
运行验证
分析失败
自动修复

Harness：
持续验证
判断 PASS / FAIL
保护工程边界
```

因此真正发生变化的不是：

> “我们用了一个更强的 AI。”

而是：

> **我们把软件开发从“人不断告诉 Agent 下一步怎么做”，变成了“人定义目标和约束，Agent 在可验证的工程环境中自主完成反馈闭环”。**

---

# 33. Quick Start Checklist

如果你准备在自己的项目中落地 Harness，先完成下面这些即可：

```text
□ 创建 AGENTS.md

□ 创建 .github/instructions/

□ 创建 .harness/evaluations/

□ 创建 .harness/tasks/

□ 创建 scripts/verify.sh

□ 确保 verify.sh 能真实发现失败

□ 创建第一个 Evaluation

□ 创建对应 Task

□ 配置 VS Code / GitHub Copilot Agent

□ 让 Agent 执行 Task

□ Agent 自动运行 ./scripts/verify.sh

□ FAIL → 修复 → 再验证

□ PASS → 完成
```

**不要一开始做更多。**

先把：

```text
Task
 ↓
Agent
 ↓
Code
 ↓
Verification
 ↓
FAIL
 ↓
Repair
 ↓
PASS
```

这条链路跑通。

这就是 Harness Engineering 的最小闭环。

---

# Appendix A：推荐的最小项目模板

```text
project/
│
├── AGENTS.md
│
├── .github/
│   ├── agents/
│   │   └── project.agent.md
│   │
│   └── instructions/
│       ├── backend.instructions.md
│       ├── frontend.instructions.md
│       └── testing.instructions.md
│
├── .harness/
│   ├── config/
│   │   └── evaluations.yaml
│   │
│   ├── evaluations/
│   │   ├── 001-mvp.md
│   │   ├── 002-feature-a.md
│   │   └── 003-regression.md
│   │
│   ├── tasks/
│   │   ├── 001-mvp.prompt.md
│   │   ├── 002-feature-a.prompt.md
│   │   └── 003-regression.prompt.md
│   │
│   └── state/
│
└── scripts/
    ├── verify.sh
    ├── verify-backend.sh
    ├── verify-frontend.sh
    ├── verify-api.sh
    └── e2e.sh
```

---

# Appendix B：最小 Harness 心智模型

记住下面这句话即可：

> **Harness = 给 Agent 一个明确的任务 + 明确的工程边界 + 客观的验证机制 + 可持续的反馈闭环。**

或者更简单：

```text
            What?
              │
            Task
              │
              ▼
           Agent
              │
          How to build?
              │
              ▼
             Code
              │
          Is it correct?
              │
              ▼
         Verification
              │
        ┌─────┴─────┐
        │           │
       PASS        FAIL
        │           │
        ▼           ▼
      Done        Repair
                    │
                    └──────► Verification
```

**这就是 Harness Engineering。**