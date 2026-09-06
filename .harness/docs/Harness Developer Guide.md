# Harness Developer Guide

> Order System Harness 开发者使用指南

本文用于帮助团队成员快速理解本项目的 Harness Engineering 工作方式，并正确使用 GitHub Copilot Custom Agents 完成需求开发。

---

# 1. Harness 是什么

本项目使用 Harness Engineering 管理软件开发流程。

Harness 的目标不是增加开发流程，而是让每一次代码变更都具备：

- 明确的需求
- 可追踪的实现过程
- 自动化测试
- 独立 Review
- 确定性的最终验证
- 失败后的自动修复能力

核心流程：

```text
Requirement
     ↓
Task / Evaluation
     ↓
Order System Agent
     ↓
Planner
     ↓
Backend / Frontend
     ↓
Test
     ↓
Reviewer
     ↓
verify.sh
     ↓
PASS / FAIL
     ↓
Repair
     ↓
verify.sh
```

最终以：

```bash
./scripts/verify.sh
```

作为任务是否完成的最终判断。

---

# 2. 项目中的几个核心概念

项目中的 Harness 相关目录：

```text
.harness/
├── config/
├── docs/
├── evaluations/
├── plans/
├── tasks/
└── state/

.github/
├── agents/
└── instructions/

AGENTS.md

scripts/
└── verify.sh
```

它们承担不同职责。

| 文件 / 目录 | 职责 |
|---|---|
| `AGENTS.md` | 整个项目的工程规则 |
| `docs/` | 产品和系统知识 |
| `.harness/evaluations/` | 定义什么叫“正确” |
| `.harness/tasks/` | 定义当前要完成什么 |
| `.harness/plans/` | Planner 输出实现计划的规范持久化位置 |
| `.harness/state/` | 当前执行状态索引 |
| `.harness/docs/` | Harness 使用和方法论 |
| `.github/agents/` | 定义不同 Agent 的职责 |
| `.github/instructions/` | 针对特定目录/文件的开发规则 |
| `scripts/verify.sh` | 最终确定性验证 |

一个简单的理解方式：

```text
AGENTS.md
    = 怎么开发

docs/
    = 系统是什么

Evaluation
    = 什么才算正确

Task
    = 这次要做什么

Agent
    = 谁负责做

verify.sh
    = 最后怎么判断做对了
```

---

### Artifact hierarchy

Harness 的产物（Artifact）遵循明确的层级：

```text
Evaluation
    ↓
Task
    ↓
Plan
    ↓
Implementation
    ↓
Evidence
```

定义：

```text
Evaluation    = WHAT must be true（什么必须成立）
Task          = WHAT needs to be changed（这次要改什么）
Plan          = HOW the repository should be changed（仓库应如何变更）
Implementation = actual code changes（实际代码变更）
Evidence       = proof that Evaluation is satisfied（证明 Evaluation 被满足）
```

### Plan 是规范持久化产物

Planner 输出的最终 Implementation Plan 必须写入：

```text
.harness/plans/<evaluation-id>-<task-slug>.plan.md
```

例如：

```text
Evaluation: .harness/evaluations/002-order-cancellation.md
Task:       .harness/tasks/002-order-cancellation.prompt.md
Plan:       .harness/plans/002-order-cancellation.plan.md
```

`.harness/plans/` 是 Planner 输出的规范（canonical）位置。

以下内容 **不是** Harness 产物，不得作为后续 Agent 的正式上下文依赖：

> Copilot Chat history is not a Harness artifact.

> VS Code `workspaceStorage/chat-session-resources` is not a Harness artifact.

> `.harness/plans/` is the canonical location for Planner output.

`.harness/state/current-task.yaml` 只是当前执行状态索引，只保存对 Plan 的引用，
不复制 Plan 内容。

---

# 3. Agent 总览

当前项目有以下 Agent：

```text
Order System
Planner
Backend
Frontend
Test
Reviewer
```

它们不是平级关系。

推荐理解为：

```text
                    Order System
                         │
                      Planner
                         │
              ┌──────────┴──────────┐
              ↓                     ↓
           Backend              Frontend
              └──────────┬──────────┘
                         ↓
                       Test
                         ↓
                      Reviewer
                         ↓
                    verify.sh
```

其中：

- `Order System` 是编排 Agent
- `Planner` 是分析 Agent
- `Backend` 是后端实现 Agent
- `Frontend` 是前端实现 Agent
- `Test` 是测试 Agent
- `Reviewer` 是独立 Review Agent

---

# 4. 平时应该使用哪个 Agent？

## 4.1 默认情况：使用 Order System

**绝大多数正常开发需求，都应该直接使用 `Order System`。**

例如：

```text
实现订单取消功能
```

或者：

```text
实现 .harness/tasks/002-order-cancellation.prompt.md
```

直接选择：

```text
Order System
```

即可。

不需要自己依次调用：

```text
Planner
→ Backend
→ Test
→ Reviewer
```

因为这些工作已经由 `Order System` 负责编排。

---

# 5. Order System Agent

## 职责

`Order System` 是整个 Harness 的入口和 Orchestrator。

它负责：

1. 理解用户需求
2. 找到相关 Evaluation
3. 找到相关 Task
4. 调用 Planner
5. 根据 Planner 结果调用实现 Agent
6. 调用 Test
7. 调用 Reviewer
8. 执行 `verify.sh`
9. 分析失败原因
10. 调用正确 Agent 修复
11. 再次执行验证

---

## 什么时候使用？

### 正常开发需求

优先使用：

```text
Order System
```

例如：

```text
实现 Task 002
```

```text
给订单增加取消功能
```

```text
实现订单详情页
```

```text
修复库存扣减的并发问题
```

---

## 推荐 Prompt

通常不需要描述整个 Harness 流程。

只需要告诉它：

```text
实现 .harness/tasks/002-order-cancellation.prompt.md
```

或者：

```text
实现 Task 002。
```

因为 Agent 定义本身已经包含工作流程。

---

# 6. Planner Agent

## 职责

Planner 负责：

> **理解问题，而不是写代码。**

它应该：

- 阅读项目规则
- 阅读相关文档
- 阅读 Evaluation
- 阅读 Task
- 检查现有实现
- 分析架构
- 找出受影响模块
- 制定实现计划
- 定义测试策略
- 定义验证策略

Planner **不应该修改生产代码**。

---

## 正常开发时是否需要手动调用？

通常：

```text
不需要
```

因为：

```text
Order System
      ↓
Planner
```

Order System 会自动调用 Planner。

---

## 什么时候适合手动使用 Planner？

以下情况可以直接调用 Planner：

### 1. 需求很复杂

例如：

```text
设计订单分布式锁方案
```

### 2. 想先了解现有系统

例如：

```text
分析订单取消流程，不修改任何代码。
```

### 3. 想在实现之前人工检查方案

例如：

```text
先分析这个需求并给出实现方案，不要修改代码。
```

### 4. 调试 Harness

如果怀疑：

```text
Order System
```

没有正确调用 Planner，可以直接调用 Planner 检查 Harness。

---

# 7. Backend Agent

## 职责

Backend 负责后端代码实现。

例如：

- Controller
- Service
- Repository
- Entity
- DTO
- 数据库访问
- Transaction
- 后端测试所需的生产代码修改

---

## 什么时候使用？

如果 Planner 判断：

```text
需要修改 Spring Boot 后端
```

则由：

```text
Backend
```

负责实现。

---

## 不建议直接使用 Backend 的情况

普通需求不要绕过：

```text
Order System
```

直接让 Backend 开发。

否则容易失去：

- Planner 分析
- Test
- Reviewer
- Harness Verification

这些步骤。

---

# 8. Frontend Agent

## 职责

Frontend 负责 React 前端。

例如：

- 页面
- Component
- API 调用
- 状态管理
- 表单
- Loading
- Error
- Empty State
- 前端测试

---

## 什么时候使用？

当需求主要涉及：

```text
React
UI
页面
交互
前端 API 调用
```

时使用 Frontend。

例如：

```text
增加订单取消按钮。
```

但如果这个需求同时涉及：

```text
取消 API
数据库
库存
前端按钮
```

则不要自己分别调用 Backend 和 Frontend。

应该：

```text
Order System
```

让它根据 Planner 的结果进行拆分。

---

# 9. Test Agent

## 职责

Test 负责：

- 分析现有测试
- 添加缺失测试
- 执行测试
- 验证 Evaluation
- 发现测试覆盖不足
- 反馈失败原因

Test 的重要原则：

> **Test Agent 不应该通过修改生产代码来让测试通过。**

例如测试失败：

```text
Expected CANCELLED
Actual PENDING
```

Test Agent 应该报告问题。

而不是直接修改业务代码。

生产代码应该交给：

```text
Backend
```

修复。

---

# 10. Reviewer Agent

## 职责

Reviewer 对已经完成的实现进行独立检查。

重点检查：

- 是否满足 Task
- 是否满足 Evaluation
- 架构是否合理
- 是否存在遗漏
- 是否存在回归风险
- Transaction 是否正确
- Concurrency 是否正确
- Idempotency 是否正确
- 测试是否充分

Reviewer 默认：

```text
只读
```

不应该直接修改生产代码。

---

# 11. verify.sh

`verify.sh` 是整个 Harness 的最终裁判。

运行：

```bash
./scripts/verify.sh
```

它的结果优先于：

- Agent 的自我判断
- Test Agent 的判断
- Reviewer 的判断
- 开发者自己的判断

也就是说：

```text
Agent: “应该没问题”
        ↓
        不重要

Reviewer: “LGTM”
        ↓
        不代表完成

Tests: PASS
        ↓
        仍然不代表完成

verify.sh: PASS
        ↓
      完成
```

---

# 12. 什么情况下需要 Evaluation？

Evaluation 定义：

> **什么叫做正确。**

例如：

```text
002-order-cancellation.md
```

可以定义：

```text
PENDING → CANCELLED

取消必须释放库存

库存只能释放一次

必须写 AuditLog

取消必须在一个事务中完成

PAID / SHIPPED 不允许取消
```

Evaluation 描述的是：

```text
What
```

而不是：

```text
How
```

---

# 13. 什么时候应该新增 Evaluation？

不是每一个需求都需要新增 Evaluation。

## 建议新增 Evaluation 的情况

当需求涉及：

### 状态机

例如：

```text
PENDING → CANCELLED
```

### 幂等性

例如：

```text
重复请求不能产生重复副作用
```

### 并发

例如：

```text
两个请求同时扣库存
```

### 数据一致性

例如：

```text
订单、库存、支付必须保持一致
```

### 关键业务规则

例如：

```text
已支付订单不能取消
```

### 长期需要持续验证的行为

如果这个规则未来很容易被重构破坏，也值得成为 Evaluation。

---

# 14. 什么情况下不需要新增 Evaluation？

以下通常不需要：

```text
修改按钮颜色
```

```text
调整页面布局
```

```text
修改文案
```

```text
修复 CSS
```

```text
普通代码重构
```

```text
增加一个简单的 DTO 字段
```

除非这些变化涉及重要业务行为。

---

# 15. Evaluation 和 Test 的区别

这是 Harness 中非常重要的概念。

### Evaluation

回答：

> **什么才算正确？**

例如：

```text
取消订单后库存必须恢复。
```

### Test

回答：

> **我们如何证明它正确？**

例如：

```java
@Test
void shouldReleaseInventoryWhenCancelOrder() {
    ...
}
```

因此：

```text
Evaluation
    ↓
定义正确性

Test
    ↓
证明正确性
```

两者不是重复的。

---

# 16. Task 是什么？

Task 描述：

> **当前要完成的具体工作。**

例如：

```text
.harness/tasks/002-order-cancellation.prompt.md
```

它应该描述：

- 本次需求
- 需要实现的行为
- 相关 Evaluation
- 验收目标
- 验证要求

可以理解为：

```text
Evaluation
    = 长期规则

Task
    = 当前工作
```

---

# 17. 一个需求应该怎么开始？

当你接到一个需求时，推荐按照下面的判断方式。

```text
收到需求
   ↓
是不是普通开发需求？
   │
   ├── 是
   │    ↓
   │  Order System
   │
   └── 否
        ↓
   是不是需要先分析？
        │
        └── Planner
```

正常情况下：

```text
直接 Order System
```

---

# 18. 推荐的日常开发流程

## Step 1：确认需求

找到：

```text
.harness/tasks/
```

确认有没有对应 Task。

同时检查：

```text
.harness/evaluations/
```

是否存在对应 Evaluation。

---

## Step 2：调用 Order System

例如：

```text
实现 .harness/tasks/002-order-cancellation.prompt.md
```

不需要重复告诉 Agent：

```text
先 Planner
再 Backend
再 Test
再 Reviewer
```

因为这些规则已经定义在 Agent 中。

---

## Step 3：观察 Agent 编排

正常情况下应该看到：

```text
Order System
    ↓
Planner
    ↓
Backend / Frontend
    ↓
Test
    ↓
Reviewer
    ↓
verify.sh
```

---

## Step 4：如果失败

不要手动修改：

```text
Evaluation
Task
verify.sh
```

先判断失败属于哪一层。

```text
业务实现错误
    ↓
Backend / Frontend

测试不足
    ↓
Test

架构问题
    ↓
Backend / Frontend

Review 问题
    ↓
对应实现 Agent

Harness 验证失败
    ↓
根据失败原因定位责任 Agent
```

---

# 19. 一个完整例子：Task 002

需求：

```text
实现订单取消。
```

正确流程：

```text
用户
 ↓
Order System
 ↓
Planner
```

Planner 分析：

```text
影响 OrderService
影响 InventoryService
需要事务
需要 AuditLog
需要取消测试
不需要 Frontend
```

然后：

```text
Order System
 ↓
Backend
```

Backend 实现：

```text
cancelOrder()
```

然后：

```text
Order System
 ↓
Test
```

Test 增加：

```text
PENDING 可以取消
PAID 不可以取消
SHIPPED 不可以取消
取消释放库存
重复取消不会重复释放库存
AuditLog 存在
事务行为正确
```

然后：

```text
Order System
 ↓
Reviewer
```

Reviewer 检查：

```text
状态转换
事务边界
幂等性
库存一致性
测试
```

最后：

```text
./scripts/verify.sh
```

如果：

```text
HARNESS VERIFY: PASS
```

任务完成。

---

# 20. 不推荐的开发方式

## 方式一：直接修改代码

```text
需求
 ↓
开发者直接改代码
 ↓
“看起来能跑”
```

问题：

- 没有 Planner
- 没有独立 Review
- 可能遗漏 Evaluation
- 没有统一验证

---

## 方式二：只让 Test 通过

```text
修改代码
 ↓
测试 PASS
 ↓
完成
```

错误。

正确判断应该是：

```text
Test PASS
      ↓
Reviewer PASS
      ↓
verify.sh PASS
```

---

## 方式三：修改 Harness 来让任务通过

禁止：

```text
修改 Evaluation
修改 Task
修改 verify.sh
```

来绕过失败。

如果 Harness 本身有问题，应把它作为一个独立的 Harness Engineering 变更处理。

---

# 21. Harness 本身也需要开发流程

如果修改的是：

```text
.harness/
.github/agents/
.github/instructions/
scripts/verify.sh
AGENTS.md
```

这不是普通业务开发。

应该把它当作：

```text
Harness Engineering Change
```

进行 Review。

尤其不要为了让某个任务：

```text
PASS
```

而降低：

```text
Evaluation
```

或者修改：

```text
verify.sh
```

---

# 22. Agent 使用速查表

| 场景 | 推荐 Agent |
|---|---|
| 正常开发需求 | **Order System** |
| 完整实现一个 Task | **Order System** |
| 复杂需求先分析 | **Planner** |
| 分析现有系统 | **Planner** |
| Spring Boot 后端实现 | **Backend** |
| React 前端实现 | **Frontend** |
| 添加/执行测试 | **Test** |
| 独立代码 Review | **Reviewer** |
| 完整 Harness 流程 | **Order System** |
| Harness 调试 | Planner / Order System |
| 最终是否完成 | `./scripts/verify.sh` |

---

# 23. 最重要的几个原则

### 原则 1

**正常开发优先使用 Order System。**

不要自己手动编排 Agent。

---

### 原则 2

**Agent 定义负责定义流程，用户 Prompt 负责描述需求。**

因此：

```text
实现 Task 002
```

通常就足够。

---

### 原则 3

**Planner 负责想，Backend / Frontend 负责做。**

Planner 不应该修改生产代码。

---

### 原则 4

**Test 负责证明，不负责偷偷修生产代码。**

---

### 原则 5

**Reviewer 是独立检查者。**

不要让实现 Agent 自己宣布：

```text
LGTM
```

---

### 原则 6

**verify.sh 是最终裁判。**

只有：

```text
./scripts/verify.sh
```

通过，任务才算完成。

---

### 原则 7

**不要为了 PASS 修改 Harness。**

尤其不要通过修改：

```text
Evaluation
Task
verify.sh
```

来降低验收标准。

---

# 24. 新同事只需要记住这张图

```text
                    收到需求
                       │
                       ↓
                有对应 Task？
                  │         │
                 YES        NO
                  │         │
                  ↓         ↓
            Order System   创建/讨论 Task
                  │
                  ↓
               Planner
                  │
          ┌───────┴────────┐
          ↓                ↓
       Backend          Frontend
          └───────┬────────┘
                  ↓
                Test
                  ↓
              Reviewer
                  ↓
          ./scripts/verify.sh
                  │
           ┌──────┴──────┐
           ↓             ↓
         PASS           FAIL
           │             │
           ↓             ↓
         完成        定位责任 Agent
                         │
                         ↓
                       修复
                         │
                         ↓
                 verify.sh 再次执行
```

**日常开发只有一个入口：**

```text
Order System
```

**只有在需要特殊目的时，才直接使用 Planner / Backend / Frontend / Test / Reviewer。**