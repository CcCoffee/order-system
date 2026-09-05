# Harness Engineering：Evaluation 设计指南

> **核心原则：不是每个需求都需要一个 Evaluation。**
>
> Evaluation 是 Harness Engineering 中用于定义和长期保护“正确行为”的工程资产，而不是 Jira / Issue / User Story 的一一对应物。

---

## 1. 什么是 Evaluation？

Evaluation 可以理解为：

> **“这个系统什么情况下才算做对了？”**

在传统软件开发中，我们通常通过：

- PR Review
- Unit Test
- Integration Test
- E2E Test
- QA
- Code Review

判断代码是否正确。

Harness Engineering 在此基础上进一步把**业务正确性和工程约束显式化**，形成可以被 Agent、Test Agent 和自动化脚本反复验证的标准。

典型流程：

```text
                    Requirement
                         │
                         ↓
                      Planner
                         │
                         ↓
                  Implementation
                         │
             ┌───────────┴───────────┐
             ↓                       ↓
       Backend / Frontend          Test
             │                       │
             └───────────┬───────────┘
                         ↓
                      Reviewer
                         │
                         ↓
                 ./scripts/verify.sh
                         │
                    ┌────┴────┐
                    ↓         ↓
                   PASS      FAIL
                              │
                              ↓
                           Repair
                              │
                              └──→ Verify
```

Evaluation 就位于这个流程的“判定标准”一侧。

---

# 2. Evaluation 不是需求单

这是最重要的概念。

不要建立这样的关系：

```text
一个需求
    ↓
一个 Evaluation
```

而应该是：

```text
多个需求
    ↓
一个业务能力
    ↓
一个 Evaluation
```

例如：

```text
REQ-101 增加取消订单按钮
REQ-102 增加取消订单 API
REQ-103 取消后恢复库存
REQ-104 增加取消审计日志
```

这些实际上属于同一个业务能力：

```text
              Order Cancellation
                     │
        ┌────────────┼────────────┐
        ↓            ↓            ↓
       API          库存        AuditLog
        │
        ↓
    状态转换
```

因此不应该创建：

```text
evaluation-101.md
evaluation-102.md
evaluation-103.md
evaluation-104.md
```

而应该创建：

```text
002-order-cancellation.md
```

它描述的是：

> **订单取消能力必须满足什么条件。**

---

# 3. 什么情况下需要 Evaluation？

可以通过三个问题判断。

## 问题一：是否产生了新的业务行为？

如果只是：

- 修改按钮颜色
- 修改文字
- 调整 CSS
- 调整页面布局
- 重构内部代码但行为不变

通常不需要新的 Evaluation。

如果产生了新的业务行为，例如：

- 订单取消
- 订单幂等
- 库存扣减
- 支付状态转换
- 优惠券使用
- 权限控制

则应该继续判断。

---

## 问题二：这个行为是否容易被 Agent 改坏？

特别值得建立 Evaluation 的通常是：

```text
库存不能变成负数
订单不能重复创建
订单不能重复扣库存
订单状态不能非法转换
支付成功后不能再次取消
权限不足不能访问资源
```

这些规则非常容易在后续代码修改中被破坏。

因此它们应该被 Harness 长期保护。

---

## 问题三：这个行为是否值得长期回归？

如果未来每次修改代码，都希望系统自动检查：

> “这个能力仍然正确吗？”

那么就应该考虑建立 Evaluation。

---

# 4. 推荐的判断标准

| 需求类型 | 是否需要新的 Evaluation |
|---|---|
| 修改按钮文字 | ❌ |
| 修改 CSS | ❌ |
| 调整页面布局 | ❌ |
| 增加普通字段 | 通常 ❌ |
| 普通 CRUD | 通常 ❌ |
| 增加订单取消能力 | ✅ |
| 增加订单幂等 | ✅ |
| 库存并发扣减 | ✅ 强烈建议 |
| 支付状态机 | ✅ |
| 权限控制 | ✅ |
| 修复关键业务 Bug | ⚠️ 建议 |
| 普通代码重构 | ❌ |
| 大型业务能力 | ✅ |
| 容易回归的关键规则 | ✅ |

---

# 5. Evaluation 与 Requirement 的关系

Evaluation 和 Requirement 并不是一对一关系。

更准确的模型是：

```text
Requirement
    │
    ├──────────────┐
    ↓              ↓
业务能力 A       业务能力 B
    │              │
    ↓              ↓
Evaluation A    Evaluation B
```

甚至一个 Requirement 可以受到多个 Evaluation 的约束。

例如：

> “实现订单取消。”

可能同时受到：

```text
002-order-cancellation
003-inventory-concurrency
006-regression
```

约束。

因为订单取消不仅涉及：

- 状态转换

还涉及：

- 库存一致性
- 并发安全
- 回归兼容性

因此：

> **一个需求可以被多个 Evaluation 覆盖。**

反过来：

> **一个 Evaluation 也可以覆盖多个需求。**

---

# 6. Evaluation 应该描述什么？

Evaluation 应该描述：

> **业务行为、约束和验收标准。**

而不是过度规定实现方式。

例如：

## 推荐

```text
取消 PENDING 状态的订单必须成功。

取消订单后：

1. 订单状态变为 CANCELLED
2. 已预占库存必须释放
3. 必须产生 AuditLog
4. 整个操作必须保持事务一致性
5. 重复取消不能再次释放库存
```

## 不推荐

```text
必须创建 OrderCancellationService。

必须使用 RedisTemplate。

必须在 OrderService 第 83 行调用 releaseStock()。

必须使用某某设计模式。
```

除非这些是明确的架构约束，否则 Evaluation 不应该限制 Agent 的具体实现方式。

核心原则：

> **Evaluation 定义 What；Agent 决定 How。**

---

# 7. Agent 与 Evaluation 的职责边界

这是 Harness Engineering 中非常重要的边界。

```text
                 Human / Team
                      │
                      │ 定义
                      ↓
                 Evaluation
                      │
                      │ 判断标准
                      ↓
                  Harness
                      │
                      ↓
                    Agent
                      │
                      │ 实现
                      ↓
                    Code
```

Agent 可以：

- 分析需求
- 修改代码
- 创建测试
- 修复 Bug
- 重构代码

但是 Agent **不应该自行修改正式 Evaluation 来让自己通过**。

否则会产生一个危险的问题：

```text
Agent 出题
   ↓
Agent 答题
   ↓
Agent 改评分标准
   ↓
PASS
```

这实际上已经失去了 Harness 的意义。

---

# 8. Planner 与 Evaluation 的关系

Planner 和 Evaluation 很容易被混淆。

它们实际上解决两个完全不同的问题。

## Planner

回答：

> **“应该怎么实现？”**

例如：

```text
Backend:
- 增加 cancelOrder()
- 增加事务
- 增加库存释放

Frontend:
- 增加 Cancel 按钮
- 增加 loading/error 状态

Test:
- 测试状态转换
- 测试库存释放
- 测试重复取消
```

---

## Evaluation

回答：

> **“什么情况下才算实现正确？”**

例如：

```text
PENDING → CANCELLED 必须成功

PAID → CANCELLED 必须失败

SHIPPED → CANCELLED 必须失败

成功取消必须释放库存

重复取消不能重复释放库存

必须产生审计日志
```

所以：

```text
Requirement
     │
     ├──────────────→ Evaluation
     │                    │
     │                What is correct?
     │
     ↓
   Planner
     │
 How to implement?
     │
     ↓
   Agents
```

---

# 9. Planner 可以生成 Evaluation 吗？

可以**提出建议**，但不应该直接生成正式 Evaluation。

例如 Planner 发现新增优惠券功能，可以输出：

```markdown
## Proposed Evaluation

1. 一个订单只能使用一张优惠券
2. 过期优惠券不能使用
3. 同一优惠券不能被并发重复使用
4. 取消订单后优惠券是否恢复，需要明确规则
```

但是这个结果应该经过：

```text
Planner
   ↓
Proposed Evaluation
   ↓
Human / Tech Lead Review
   ↓
正式 Evaluation
```

而不是：

```text
Planner
   ↓
直接写入 .harness/evaluations/
```

原因很简单：

> **Agent 可以帮助制定标准，但最终的工程标准应该由人或团队负责。**

---

# 10. Evaluation 是长期工程资产

Evaluation 不应该随着需求完成就删除。

例如：

```text
2026-09
新增订单取消
        ↓
002-order-cancellation.md
```

一年后：

```text
2027-09
修改订单服务
        ↓
自动执行 Evaluation
        ↓
发现取消订单逻辑被破坏
```

这就是 Evaluation 的价值。

它实际上是在保存：

> **“这个系统过去踩过什么坑，以及我们以后绝不能再犯什么错误。”**

因此 Evaluation 会逐渐形成团队的：

- 业务知识
- 架构约束
- 关键回归规则
- Agent 验收标准

---

# 11. 一个健康的 Evaluation 目录

项目刚开始时，不需要很多。

例如：

```text
.harness/
└── evaluations/
    ├── 001-order-system-mvp.md
    ├── 002-order-cancellation.md
    ├── 003-inventory-concurrency.md
    ├── 004-order-idempotency.md
    ├── 005-web-ui-design-language.md
    └── 006-regression.md
```

这 6 个文件不是 6 个需求。

而是 6 个重要的系统能力：

```text
001 订单系统基本能力
002 订单取消
003 库存并发安全
004 订单幂等
005 网页 UI 设计语言
006 回归保护
```

这种规模是健康的。

---

# 12. 不要让 Evaluation 无限增长

一个反面例子：

```text
.harness/evaluations/

001-button-color.md
002-button-padding.md
003-button-text.md
004-font-size.md
005-margin.md
006-api-field.md
007-api-comment.md
008-variable-name.md
009-class-name.md
...
```

最终 Harness 本身变成了负担。

正确方向应该是：

```text
很多 Requirements
       │
       ↓
少量核心业务能力
       │
       ↓
少量高价值 Evaluations
```

Harness 的目标不是：

> **什么都检查。**

而是：

> **把最重要、最容易回归、最值得长期保护的行为固定下来。**

---

# 13. Evaluation 与 Test 的区别

Evaluation 不是 Test Case。

例如：

### Evaluation

```text
订单取消必须满足：

PENDING → CANCELLED

并释放库存，产生审计日志，
且重复取消不能重复释放库存。
```

### Test

```java
@Test
void shouldCancelPendingOrder() {
    ...
}

@Test
void shouldReleaseInventoryWhenCancelled() {
    ...
}

@Test
void shouldNotReleaseInventoryTwice() {
    ...
}
```

Evaluation 是**行为规范**。

Test 是**验证手段**。

可以理解为：

```text
Evaluation
    │
    │ defines
    ↓
What must be true
    │
    ↓
Tests / Verification
    │
    │ prove
    ↓
Whether it is true
```

---

# 14. Evaluation 与 verify.sh 的关系

推荐采用：

```text
Evaluation
     ↓
定义应该满足什么
     ↓
Test / Verification
     ↓
实际执行检查
     ↓
verify.sh
     ↓
PASS / FAIL
```

例如：

```text
Evaluation:
“库存不能出现负数”

        ↓

Integration Test:
并发两个订单购买最后一个库存

        ↓

Database:
stock = 1

        ↓

两个请求同时执行

        ↓

只能一个成功

        ↓

stock != -1

        ↓

PASS
```

因此：

> **Evaluation 是规则，verify.sh 是最终自动化裁判。**

---

# 15. 推荐团队工作方式

以后同事收到一个新需求：

```text
“增加优惠券功能”
```

不要第一时间问：

> “我要创建哪个 Evaluation？”

而应该先问：

### Step 1：这是普通修改还是新的业务能力？

如果只是：

```text
修改页面
调整文案
普通字段
```

通常不需要。

---

### Step 2：是否涉及重要业务规则？

例如：

```text
优惠券不能过期使用
优惠券不能重复使用
并发情况下只能成功一次
```

这些就值得考虑 Evaluation。

---

### Step 3：是否已有 Evaluation 可以覆盖？

例如已经存在：

```text
004-order-idempotency.md
```

新需求也涉及幂等。

那么可能只需要：

> **扩展现有 Evaluation**

而不是新增一个文件。

---

### Step 4：确实出现新的核心能力，再创建 Evaluation

例如：

```text
006-coupon.md
```

---

# 16. 最终推荐的决策树

```text
                新需求
                  │
                  ↓
          是否产生新的业务能力？
             /           \
           否             是
           │              │
           ↓              ↓
       不需要          是否已有 Evaluation
       新 Evaluation     可以覆盖？
                         /       \
                       是         否
                       │          │
                       ↓          ↓
                  扩展已有      新建 Evaluation
                  Evaluation
```

---

# 17. 团队应该遵守的 6 条原则

### 原则 1

> **Evaluation ≠ Requirement**

不要一一对应。

### 原则 2

> **Evaluation 应围绕业务能力，而不是代码文件。**

不要因为修改了三个 Java 类就创建三个 Evaluation。

### 原则 3

> **优先扩展已有 Evaluation，而不是创建新的。**

避免 Evaluation 碎片化。

### 原则 4

> **Evaluation 描述 What，而不是 How。**

不要过度限制 Agent 实现方式。

### 原则 5

> **正式 Evaluation 应由人或团队负责。**

Agent 可以提出建议，但不应该自行修改验收标准。

### 原则 6

> **Evaluation 应该长期存在。**

它是项目的长期工程知识和回归保护机制。

---

# 18. 一句话记忆

如果只记住一句话：

> **Requirement 是“我要什么”，Planner 是“怎么做”，Evaluation 是“什么才算做对”，Test/verify.sh 是“证明它确实做对了”。**

完整关系：

```text
                Human
                  │
                  │ Requirement
                  ↓
              ┌─────────┐
              │ Planner │
              └────┬────┘
                   │
             Implementation
                   Plan
                   │
        ┌──────────┼──────────┐
        ↓          ↓          ↓
     Backend    Frontend     Test
        │          │          │
        └──────────┼──────────┘
                   ↓
                Reviewer
                   │
                   ↓
             ./scripts/verify.sh
                   │
              PASS / FAIL
                   ↑
                   │
             Evaluation
          “什么才算正确”
```

**Harness Engineering 的关键，不是让 Agent 写更多代码，而是让团队把“正确”定义清楚，并让机器能够持续判断 Agent 是否真的做对了。**