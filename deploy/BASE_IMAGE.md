# 固定 ARM64 运行时镜像

核验日期：2026-11-09 UTC。

`deploy-local.sh` 使用 Docker 官方在 Amazon ECR Public 的分发，而不是第三方镜像站。Ubuntu 的 Docker Hub TLS 连接被重置，但 ECR 的 manifest 查询成功。

- 仓库：`public.ecr.aws/docker/library/eclipse-temurin`
- 对应标签：`21-jre-jammy`，Temurin JRE `21.0.13+9`，Ubuntu Jammy。
- 平台：`linux/arm64/v8`。
- 固定 manifest digest：`sha256:5bdb2989179defb8abd386a97b34407ebeccf9fdae11838576983254b5e8e5e2`。
- 已核验的 image config digest：`sha256:cd9edca13a4c03d1cacfde0cab66cdfbbcb44dcf1c7a1f3a5f800cc6e5c2b6ec`。
- 压缩镜像层合计约 96.1 MB；实际磁盘占用更大。

ECR 返回的 ARM64 manifest digest 与 [Docker 官方 repo-info 元数据](https://github.com/docker-library/repo-info/blob/master/repos/eclipse-temurin/remote/21-jre-jammy.md) 完全一致。[Docker 官方说明](https://www.docker.com/press-release/docker-official-images-available-amazon-elastic-container-registry/)确认 Docker Official Images 分发至 ECR Public。

脚本按固定 manifest digest 拉取，并要求本地 RepoDigests 包含完全一致的官方仓库引用、平台为 Linux/ARM64。Docker 经典存储的 image ID 是 config digest，Docker 29 的 containerd 存储可能使用目标 manifest digest，因此校验只接受上述两个已核验值；若存在 Descriptor，其 digest 也必须匹配。不更改系统镜像源、代理、VPN、TLS 或 Jenkins 权限。manifest 可访问并不代表镜像层已经下载成功，实际部署结果仍以 VERIFICATION.md 为准。

Dockerfile 默认仍为 `eclipse-temurin:21-jre-jammy`，可通过 `BASE_IMAGE` 构建参数覆盖。此脚本固定 ARM64 digest；其他架构不能直接使用该 digest。固定镜像需要以后主动跟进安全更新，不代表整个 JAR 构建位级可复现。

兼容性参考：[Docker containerd 存储文档](https://docs.docker.com/engine/storage/containerd/)及 [Docker 官方 CLI 的 inspect 示例](https://github.com/docker/cli/blob/master/man/src/inspect.md)。旧版脚本错误地只接受 config digest，已修复，而非跳过镜像验证。
