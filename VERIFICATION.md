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
- 公开仓库独立初始化，仅包含本练习源码、配置及文档，不继承旧仓库历史。公开内容经过凭据和私人连接信息检查。

11 月 9 日独立版本构建产物 SHA-256：

```text
a7e9a137d441e85d157cc51e779aa348c472a64481221a4e67558916f9e57fc2
```

## Jenkins 实际构建

- **mytest #1：SUCCESS**，总耗时 8 分 44 秒；Maven 构建耗时 8 分 34 秒（首次依赖下载）。
- 公共 HTTPS Git SCM 无需凭据，实际检出 `6e8745d91f1157cdd423083ad58e24f6878cf040`，分支 `main`。
- 运行 `maven3` 的 `-B -ntp clean verify`，随后运行 `bash scripts/verify-jar.sh`。
- Jenkins 测试报告显示 **3 passed，0 failed，0 skipped**；可执行 JAR 的 `/test`、`/health` 和 404 检查也通过。
- `target/mytest.jar` 已归档，大小 19.04 MiB，并记录 Jenkins 文件指纹。
- 通过浏览器下载 #1 的归档 JAR，校验其指纹与 Jenkins 一致，再经已有 SSH 通道传到 Ubuntu 的 `~/devops-lab/episode-10/deploy/mytest.jar`。传输前后的 SHA-256 一致，旧练习 JAR 保留备份。
- 在 Ubuntu 再次启动这个归档 JAR，HTTP 冒烟检查通过，随后停止本次测试进程。没有启动 Docker 容器或改动原有服务。

Jenkins #1 归档及已传输 JAR 的 SHA-256（与上方本机 Maven 产物不同，不声称位级可复现）：

```text
e5852c31074620ee307e75dc8fe27b22345093a0c38aef9d9adc8e1528104120
```

本记录之后的文档修订不改变该次构建的源码提交。

## 尚未完成

- Docker 镜像尚未构建、容器尚未启动，容器环境中的 8081 HTTP 响应尚未验证。部署需用户在 Ubuntu 终端自行完成 sudo 认证，不会给 Jenkins Docker 或高权限 SSH 权限。
- Docker Hub 之前有连接重置问题，Temurin 运行时镜像尚未成功拉取并记录 digest。
- 可选 `Jenkinsfile` 未在 Pipeline 作业中执行。

## 记录与限制

Ubuntu 的系统时钟仍未同步，构建日志时间落后于 Mac；以上日期以 Mac UTC 为准。本任务没有更改系统时间或安全设置。

源码和文档进入 Git；JAR、日志、环境文件、私钥和 Jenkins 数据均不上传。原有服务、数据卷及其他仓库历史保持不变。没有执行 Docker 清理操作。
