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
- 在 Ubuntu 再次启动这个归档 JAR，HTTP 冒烟检查通过，随后停止本次测试进程。该次 JAR 检查没有启动 Docker 容器或改动原有服务；后续容器部署见下文。

Jenkins #1 归档及已传输 JAR 的 SHA-256（与上方本机 Maven 产物不同，不声称位级可复现）：

```text
e5852c31074620ee307e75dc8fe27b22345093a0c38aef9d9adc8e1528104120
```

文档更新提交 `442a022cb0e9aad6ce06eb884a741aa65fc740c6` 已由 **mytest #2** 再次构建成功，耗时 8.4 秒；与 #1 之间只修改 README 和验证记录。后续手动部署脚本修订不改变已传输的 #1 JAR。

## 手动部署脚本准备

- `deploy/deploy-local.sh` 只供用户在 Ubuntu ARM64 终端手动执行，Jenkins 不调用它。
- 脚本静态审查及 Bash 语法检查通过。使用模拟命令测试了成功路径，以及端口占用、危险 Compose 配置、已有同名容器/网络/镜像、拉取失败、基镜像 ID 不符、HTTP 校验失败时停止的行为；这不等同于真实 Docker 部署测试。
- 已在真实 Ubuntu 部署目录执行 `--check` 无 sudo 预检，JAR 哈希、空闲端口和 Compose 配置检查通过；独立错误 JAR 测试在 Docker/sudo 操作前被拒绝。
- 脚本固定检查已传输 #1 JAR 的 SHA-256、官方 ECR manifest digest 和 image ID。任何错误都会停止，不执行 Docker 清理或替换已有服务。

## Docker 实际部署与 HTTP 验证

- 用户在 Ubuntu 终端完成 sudo 认证并运行手动脚本，成功拉取官方 ECR 固定 ARM64 基镜像，验证 RepoDigest 与平台通过。
- Docker 29 实际返回的基镜像 image ID 是已固定 manifest digest `sha256:5bdb2989179defb8abd386a97b34407ebeccf9fdae11838576983254b5e8e5e2`。旧脚本只接受 config digest 的兼容性问题已修复，新增 11 个兼容与拒绝用例。
- `mytest:episode10` 应用镜像构建成功；Compose 创建 `devops-episode10_default` 网络和 `devops-episode10-mytest-1` 容器，映射 **127.0.0.1:8081 → 8080/tcp**。
- 应用镜像 manifest digest：`sha256:fa373fa94df68ec156ce13e5590676b144ed34ff3a17d16804751cb88ff7b194`；本次构建的 image index digest：`sha256:c014193663c2d3300b914534de0be3ce6758446de283d687db2c39193fe840a8`。
- 首次启动不到 1 秒时，旧 HTTP 检查遇到 curl (56) 连接重置并退出，但没有停止容器。随后独立检查确认 Ubuntu `/test` 为 **200 / Hello Jenkins!**、`/health` 为 **200 / OK**、未知路径为 **404**。
- 启动检查已改为有界轮询，覆盖临时连接重置；本机用先重置两次连接、再返回 200 OK 的真实 HTTP 测试服务器验证通过。修复后没有重复构建、重启或替换正在运行的容器。
- Mac 已通过仅绑定本机回环地址的临时 SSH 转发验证：`http://127.0.0.1:8081/test` 返回 **200 / Hello Jenkins!**，`/health` 返回 **200 / OK**。没有改动系统网络设置或开放局域网访问；SSH 连接断开后需重新建立转发。
- 原有 8000 服务和 Jenkins 8080 仍在监听。没有执行 down/prune，也没有授予 Jenkins Docker 或高权限 SSH 控制。

## 尚未完成

- 可选 `Jenkinsfile` 未在 Pipeline 作业中执行；实际验证的是课程自由风格作业。
- 本次 Docker 29/启动检查修复已通过上述针对性验证，未重新触发 Jenkins 构建；Jenkins #1/#2 的应用源码与当前版本相同。

## 记录与限制

Ubuntu 的系统时钟仍未同步，构建日志时间落后于 Mac；以上日期以 Mac UTC 为准。本任务没有更改系统时间或安全设置。

源码和文档进入 Git；JAR、日志、环境文件、私钥和 Jenkins 数据均不上传。原有服务、数据卷及其他仓库历史保持不变。没有执行 Docker 清理操作。
