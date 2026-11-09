# 验证记录

更新日期：2026-11-09（UTC）。以下区分实际运行结果和未完成步骤。

## 已通过

- 独立仓库文件已在 Ubuntu 26.04.1 ARM64 的新目录重新验证，不依赖旧仓库历史或嵌套目录结构。
- OpenJDK 21.0.12.1、Maven 3.9.12、Spring Boot 4.1.2。Spring Boot 版本已在官方 Maven Central 核实；本任务未新增依赖镜像源或跳过 TLS 校验。
- 执行仓库中的 `jenkins/freestyle-build.sh`，复用已有 Maven 缓存：**BUILD SUCCESS**，3 个 HTTP 集成测试全部通过，失败 0、错误 0、跳过 0。
- 打包生成可执行 `target/mytest.jar`，约 20 MB。
- 实际运行 JAR：`/test` 返回 200 和 `Hello Jenkins!`，`/health` 返回 200 和 `OK`，未知路径返回 404。检查后自行停止本次 Java 进程。
- 冒烟脚本负向测试通过：拒绝无效端口；遇到占用端口会失败，并保留原测试监听进程。
- Compose 配置、Bash 语法和 POM XML 检查通过。容器配置使用非 root 用户、只读根文件系统、回环端口及有限日志，不挂载 Docker socket。
- 11 月 6 日曾实测 SSH JAR 传输，源端、Mac 中转和 Ubuntu 部署目录哈希一致；没有传输凭据或 Jenkins 数据。

11 月 9 日独立版本构建产物 SHA-256：

```text
a7e9a137d441e85d157cc51e779aa348c472a64481221a4e67558916f9e57fc2
```

## 尚未完成

- Jenkins `mytest` 自由风格作业正在配置为本公开仓库，尚未确认其 Git 拉取、构建和归档成功。
- Docker 镜像尚未构建、容器尚未启动，容器环境中的 8081 HTTP 响应尚未验证。部署需用户在 Ubuntu 终端自行完成 sudo 认证，不会给 Jenkins Docker 或高权限 SSH 权限。
- Docker Hub 之前有连接重置问题，Temurin 运行时镜像尚未成功拉取并记录 digest。
- 可选 `Jenkinsfile` 未在 Pipeline 作业中执行。

## 记录与限制

Ubuntu 的系统时钟仍未同步，构建日志时间落后于 Mac；以上日期以 Mac UTC 为准。本任务没有更改系统时间或安全设置。

源码和文档进入 Git；JAR、日志、环境文件、私钥和 Jenkins 数据均不上传。原有服务、数据卷及其他仓库历史保持不变。没有执行 Docker 清理操作。
